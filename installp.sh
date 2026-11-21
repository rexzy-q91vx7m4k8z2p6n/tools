#!/bin/bash
# Pterodactyl auto installer: Panel + Wings + Location/Node + (opsional) Egg
# Fungsi setara dengan command bot /installpanelv2, tapi dijalankan langsung di VPS.
#
# Pakai interaktif : bash install-panel.sh
# Pakai argumen    : bash install-panel.sh panel.com node.com 4096
# Egg opsional     : EGG_SCRIPT_URL="https://.../egg.sh" bash install-panel.sh ...

set -Eeuo pipefail

START=$(date +%s)
LOG=/var/log/ptero-autoinstall.log
: > "$LOG"

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan menggunakan root!"
    exit 1
fi

# ---------- Input ----------
PANEL_DOMAIN="${1:-}"
NODE_DOMAIN="${2:-}"
RAM="${3:-}"

[[ -n "$PANEL_DOMAIN" ]] || read -rp "Domain Panel (panel.domain.com): " PANEL_DOMAIN
[[ -n "$NODE_DOMAIN"  ]] || read -rp "Domain Node  (node.domain.com): " NODE_DOMAIN
[[ -n "$RAM"          ]] || read -rp "RAM/Disk node dalam MB (contoh 4096): " RAM
EMAIL="${EMAIL:-admin@gmail.com}"
TIMEZONE="${TIMEZONE:-Asia/Makassar}"

domain_re='^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
for D in "$PANEL_DOMAIN" "$NODE_DOMAIN"; do
    [[ "$D" =~ $domain_re ]] || { echo "Domain tidak valid: $D"; exit 1; }
done
[[ "$PANEL_DOMAIN" != "$NODE_DOMAIN" ]] || { echo "Domain Panel dan Node tidak boleh sama!"; exit 1; }
[[ "$RAM" =~ ^[0-9]+$ ]] || { echo "RAM harus angka (MB)."; exit 1; }

for D in "$PANEL_DOMAIN" "$NODE_DOMAIN"; do
    getent ahosts "$D" >/dev/null || { echo "DNS belum mengarah ke server: $D"; exit 1; }
done

# ---------- Kredensial otomatis ----------
rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-12}"; }
ADMIN_USER="admin"
ADMIN_PASS="$(rand 12)"
DBHOST_USER="admin"
DBHOST_PASS="$(rand 16)"

if ! command -v expect >/dev/null 2>&1; then
    apt-get update -y >>"$LOG" 2>&1
    apt-get install -y expect curl >>"$LOG" 2>&1
fi

export PANEL_DOMAIN NODE_DOMAIN EMAIL TIMEZONE ADMIN_USER ADMIN_PASS DBHOST_USER DBHOST_PASS

step() { echo; echo "==> $1"; }

# ---------- 1. Panel ----------
step "[1/5] Install Panel"
expect >>"$LOG" 2>&1 <<'EXPECT'
set timeout -1
spawn bash -c {bash <(curl -fsSL https://pterodactyl-installer.se)}
expect -re {Input 0-6} { send -- "0\r" }
expect {
    -re {Database name}                 { send -- "\r"; exp_continue }
    -re {Database username}             { send -- "\r"; exp_continue }
    -re {Password}                      { send -- "\r"; exp_continue }
    -re {Select timezone}               { send -- "$env(TIMEZONE)\r"; exp_continue }
    -re {[Ee]mail address}              { send -- "$env(EMAIL)\r"; exp_continue }
    -re {Username for the admin}        { send -- "$env(ADMIN_USER)\r"; exp_continue }
    -re {First name}                    { send -- "admin\r"; exp_continue }
    -re {Last name}                     { send -- "admin\r"; exp_continue }
    -re {[Pp]assword for the admin}     { send -- "$env(ADMIN_PASS)\r"; exp_continue }
    -re {Set the FQDN}                  { send -- "$env(PANEL_DOMAIN)\r"; exp_continue }
    -re {\(y/N\)|\(Y\)es/\(N\)o}        { send -- "y\r"; exp_continue }
    eof {}
}
catch wait result
exit [lindex $result 3]
EXPECT
echo "    Panel terinstall"

# ---------- 2. Wings ----------
step "[2/5] Install Wings"
expect >>"$LOG" 2>&1 <<'EXPECT'
set timeout -1
spawn bash -c {bash <(curl -fsSL https://pterodactyl-installer.se)}
expect -re {Input 0-6} { send -- "1\r" }
expect {
    -re {Enter the panel address}       { send -- "https://$env(PANEL_DOMAIN)\r"; exp_continue }
    -re {Database host username}        { send -- "$env(DBHOST_USER)\r"; exp_continue }
    -re {Database host password}        { send -- "$env(DBHOST_PASS)\r"; exp_continue }
    -re {Set the FQDN}                  { send -- "$env(NODE_DOMAIN)\r"; exp_continue }
    -re {Enter email address}           { send -- "$env(EMAIL)\r"; exp_continue }
    -re {\(y/N\)|\(Y\)es/\(N\)o}        { send -- "y\r"; exp_continue }
    eof {}
}
EXPECT
echo "    Wings terinstall"

# ---------- 3. Location + Node (artisan, tanpa script pihak ketiga) ----------
step "[3/5] Membuat location & node"
cd /var/www/pterodactyl
php artisan p:location:make --short=SGP --long=NODE >>"$LOG" 2>&1
php artisan p:node:make \
    --name=Nodes --description=NODE --locationId=1 \
    --fqdn="$NODE_DOMAIN" --public=1 --scheme=https --proxy=0 \
    --maxMemory="$RAM" --overallocateMemory=0 \
    --maxDisk="$RAM" --overallocateDisk=0 \
    --uploadSize=100 --daemonListeningPort=8080 --daemonSFTPPort=2022 \
    --daemonBase=/var/lib/pterodactyl >>"$LOG" 2>&1
echo "    Node terbuat"

# ---------- 4. Konfigurasi Wings & start ----------
step "[4/5] Konfigurasi & jalankan Wings"
mkdir -p /etc/pterodactyl
php artisan p:node:configuration 1 > /etc/pterodactyl/config.yml
systemctl enable --now wings >>"$LOG" 2>&1
systemctl restart wings
sleep 3
if systemctl is-active --quiet wings; then WINGS_STATUS="BERJALAN"; else WINGS_STATUS="GAGAL (cek: journalctl -u wings)"; fi
echo "    Wings: $WINGS_STATUS"

# ---------- 5. Egg (opsional) ----------
EGG_STATUS="DILEWATI"
step "[5/5] Import egg"
if [[ -n "${EGG_SCRIPT_URL:-}" ]]; then
    set +e
    EGG_OUT=$(bash <(curl -fsSL "$EGG_SCRIPT_URL") 2>&1)
    CODE=$?
    set -e
    echo "$EGG_OUT" >>"$LOG"
    if [[ $CODE -eq 0 ]] && ! grep -qiE 'error|gagal|failed|exception|not found|tidak ditemukan' <<<"$EGG_OUT"; then
        EGG_STATUS="BERHASIL"
    else
        EGG_STATUS="GAGAL"
    fi
else
    echo "    EGG_SCRIPT_URL tidak diset, dilewati"
fi

# ---------- Ringkasan ----------
DUR=$(( $(date +%s) - START ))
echo
echo "=========================================="
echo "         INSTALASI SELESAI"
echo "=========================================="
echo "Username : $ADMIN_USER"
echo "Password : $ADMIN_PASS"
echo "Panel    : https://$PANEL_DOMAIN"
echo "Node     : $NODE_DOMAIN"
echo "Wings    : $WINGS_STATUS"
echo "Egg      : $EGG_STATUS"
echo "Waktu    : $((DUR/60)) menit $((DUR%60)) detik"
echo "Log      : $LOG"
echo "=========================================="
