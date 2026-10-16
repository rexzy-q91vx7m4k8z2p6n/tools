#!/bin/bash

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PANEL_DIR=""

for d in /var/www/pterodactyl /var/www/pterodactyl-panel /var/www/html/pterodactyl; do
  if [ -f "$d/artisan" ]; then
    PANEL_DIR="$d"
    break
  fi
done

if [ -z "$PANEL_DIR" ]; then
  echo -e "${RED}Panel tidak ditemukan.${NC}"
  exit 1
fi

cd "$PANEL_DIR" || exit 1

EGG_FILE="/tmp/egg-rexzystore.json"

cat > "$EGG_FILE" <<'EGG_JSON'
{
    "_comment": "DO NOT EDIT: FILE GENERATED AUTOMATICALLY BY PTERODACTYL PANEL - PTERODACTYL.IO",
    "meta": {
        "version": "PTDL_v2",
        "update_url": null
    },
    "exported_at": "2025-12-31T18:51:53+07:00",
    "name": "RexzyStore🌐",
    "author": "rexzystore@gmail.com",
    "description": null,
    "features": null,
    "docker_images": {
        "NodeJS 24": "ghcr.io/parkervcp/yolks:nodejs_24",
        "NodeJS 23": "ghcr.io/parkervcp/yolks:nodejs_23",
        "NodeJS 22": "ghcr.io/parkervcp/yolks:nodejs_22",
        "NodeJS 21": "ghcr.io/parkervcp/yolks:nodejs_21",
        "NodeJS 20": "ghcr.io/parkervcp/yolks:nodejs_20",
        "NodeJS 19": "ghcr.io/parkervcp/yolks:nodejs_19",
        "NodeJS 18": "ghcr.io/parkervcp/yolks:nodejs_18",
        "NodeJS 17": "ghcr.io/parkervcp/yolks:nodejs_17",
        "NodeJS 16": "ghcr.io/parkervcp/yolks:nodejs_16",
        "NodeJS 15": "ghcr.io/parkervcp/yolks:nodejs_15"
    },
    "file_denylist": [],
    "startup": "if [[ -d .git ]] && [[ {{AUTO_UPDATE}} == \"1\" ]]; then git pull; fi; if [[ ! -z ${NODE_PACKAGES} ]]; then /usr/local/bin/npm install ${NODE_PACKAGES}; fi; if [[ ! -z ${UNNODE_PACKAGES} ]]; then /usr/local/bin/npm uninstall ${UNNODE_PACKAGES}; fi; if [ -f /home/container/package.json ]; then /usr/local/bin/npm install; fi; if [[ ! -z ${CUSTOM_ENVIRONMENT_VARIABLES} ]]; then vars=$(echo ${CUSTOM_ENVIRONMENT_VARIABLES} | tr \";\" \"\\n\"); for line in $vars; do export $line; done fi; /usr/local/bin/${CMD_RUN};",
    "config": {
        "files": "{}",
        "startup": "{\r\n    \"done\": \"running\"\r\n}",
        "logs": "{}",
        "stop": "^^C"
    },
    "scripts": {
        "installation": {
            "script": "#!\/bin\/bash\r\n# NodeJS App Installation Script\r\n#\r\n# Server Files: \/mnt\/server\r\napt update\r\napt install -y git curl jq file unzip make gcc g++ python python-dev libtool\r\n\r\nmkdir -p \/mnt\/server\r\ncd \/mnt\/server\r\n\r\nif [ \"${USER_UPLOAD}\" == \"true\" ] || [ \"${USER_UPLOAD}\" == \"1\" ]; then\r\n    echo -e \"assuming user knows what they are doing have a good day.\"\r\n    exit 0\r\nfi\r\n\r\n## add git ending if it's not on the address\r\nif [[ ${GIT_ADDRESS} != *.git ]]; then\r\n    GIT_ADDRESS=${GIT_ADDRESS}.git\r\nfi\r\n\r\nif [ -z \"${USERNAME}\" ] && [ -z \"${ACCESS_TOKEN}\" ]; then\r\n    echo -e \"using anon api call\"\r\nelse\r\n    GIT_ADDRESS=\"https:\/\/${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d\/ -f3-)\"\r\nfi\r\n\r\n## pull git js repo\r\nif [ \"$(ls -A \/mnt\/server)\" ]; then\r\n    echo -e \"\/mnt\/server directory is not empty.\"\r\n    if [ -d .git ]; then\r\n        echo -e \".git directory exists\"\r\n        if [ -f .git\/config ]; then\r\n            echo -e \"loading info from git config\"\r\n            ORIGIN=$(git config --get remote.origin.url)\r\n        else\r\n            echo -e \"files found with no git config\"\r\n            echo -e \"closing out without touching things to not break anything\"\r\n            exit 10\r\n        fi\r\n    fi\r\n\r\n    if [ \"${ORIGIN}\" == \"${GIT_ADDRESS}\" ]; then\r\n        echo \"pulling latest from github\"\r\n        git pull\r\n    fi\r\nelse\r\n    echo -e \"\/mnt\/server is empty.\\ncloning files into repo\"\r\n    if [ -z ${BRANCH} ]; then\r\n        echo -e \"cloning default branch\"\r\n        git clone ${GIT_ADDRESS} .\r\n    else\r\n        echo -e \"cloning ${BRANCH}'\"\r\n        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .\r\n    fi\r\n\r\nfi\r\n\r\necho \"Installing nodejs packages\"\r\nif [[ ! -z ${NODE_PACKAGES} ]]; then\r\n    \/usr\/local\/bin\/npm install ${NODE_PACKAGES}\r\nfi\r\n\r\nif [ -f \/mnt\/server\/package.json ]; then\r\n    \/usr\/local\/bin\/npm install --production\r\nfi\r\n\r\necho -e \"install complete\"\r\nexit 0",
            "container": "node:14-buster-slim",
            "entrypoint": "bash"
        }
    },
    "variables": [
        {
            "name": "Git Repo Address",
            "description": "GitHub Repo to clone\r\n\r\nI.E. https:\/\/github.com\/user_name\/repo_name",
            "env_variable": "GIT_ADDRESS",
            "default_value": "",
            "user_viewable": true,
            "user_editable": true,
            "rules": "nullable|string",
            "field_type": "text"
        },
        {
            "name": "Install Branch",
            "description": "The branch to install.",
            "env_variable": "BRANCH",
            "default_value": "",
            "user_viewable": true,
            "user_editable": true,
            "rules": "nullable|string",
            "field_type": "text"
        },
        {
            "name": "Git Username",
            "description": "Username to auth with git.",
            "env_variable": "USERNAME",
            "default_value": "",
            "user_viewable": true,
            "user_editable": true,
            "rules": "nullable|string",
            "field_type": "text"
        },
        {
            "name": "Git Access Token",
            "description": "Password to use with git.\r\n\r\nIt's best practice to use a Personal Access Token.\r\nhttps:\/\/github.com\/settings\/tokens\r\nhttps:\/\/gitlab.com\/-\/profile\/personal_access_tokens",
            "env_variable": "ACCESS_TOKEN",
            "default_value": "",
            "user_viewable": true,
            "user_editable": true,
            "rules": "nullable|string",
            "field_type": "text"
        },
        {
            "name": "Command Run",
            "description": "The command to start the bot",
            "env_variable": "CMD_RUN",
            "default_value": "npm start",
            "user_viewable": true,
            "user_editable": true,
            "rules": "required|string",
            "field_type": "text"
        }
    ]
}
EGG_JSON

PHP_SCRIPT="/tmp/import_egg.php"

cat > "$PHP_SCRIPT" <<'PHP_EOF'
<?php

$panelDir = null;

foreach ([
    '/var/www/pterodactyl',
    '/var/www/pterodactyl-panel',
    '/var/www/html/pterodactyl',
] as $dir) {
    if (file_exists($dir . '/artisan') && file_exists($dir . '/vendor/autoload.php')) {
        $panelDir = $dir;
        break;
    }
}

if (!$panelDir) {
    fwrite(STDERR, "ERROR: Panel tidak ditemukan.\n");
    exit(1);
}

require $panelDir . '/vendor/autoload.php';

$app = require_once $panelDir . '/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Pterodactyl\Models\Nest;
use Pterodactyl\Models\Egg;
use Pterodactyl\Models\Node;
use Pterodactyl\Models\Allocation;
use Pterodactyl\Services\Eggs\Sharing\EggImporterService;
use Illuminate\Http\UploadedFile;

$eggFile = '/tmp/egg-rexzystore.json';

if (!file_exists($eggFile)) {
    fwrite(STDERR, "ERROR: File egg tidak ditemukan.\n");
    exit(1);
}

try {
    // ===== 1. CREATE / GET NEST (id 5) =====
    $nestId = 5;
    $nestName = 'Bot WhatsApp';

    $nest = Nest::find($nestId);

    if (!$nest) {
        $nest = Nest::where('name', $nestName)->first();
    }

    if (!$nest) {
        $nest = new Nest();
        $nest->id = $nestId;
        $nest->name = $nestName;
        $nest->description = 'Nest untuk bot WhatsApp';
        $nest->author = 'rexzystore@gmail.com';
        $nest->save();
        echo "NEST_CREATED:" . $nest->id . "\n";
    } else {
        echo "NEST_EXISTS:" . $nest->id . "\n";
    }

    // ===== 2. IMPORT EGG PAKAI UploadedFile =====
    $tmpCopy = tempnam(sys_get_temp_dir(), 'egg_') . '.json';
    copy($eggFile, $tmpCopy);

    $uploaded = new UploadedFile(
        $tmpCopy,
        'egg-rexzystore.json',
        'application/json',
        null,
        true
    );

    $importer = app(EggImporterService::class);
    $egg = $importer->handle($uploaded, $nest->id);

    echo "EGG_IMPORTED:" . $egg->id . ":" . $egg->name . "\n";

    @unlink($tmpCopy);

    // ===== 3. CREATE ALLOCATIONS DI NODE ID 1 =====
    $nodeId = 1;
    $node = Node::find($nodeId);

    if (!$node) {
        echo "ALLOC_WARN:Node ID 1 tidak ditemukan\n";
    } else {
        echo "NODE:" . $node->id . ":" . $node->name . "\n";

        $ip = '0.0.0.0';
        $portStart = 2000;
        $portEnd = 2900;

        $created = 0;
        $skipped = 0;
        $batch = [];

        for ($p = $portStart; $p <= $portEnd; $p++) {
            $exists = Allocation::where('node_id', $node->id)
                ->where('ip', $ip)
                ->where('port', $p)
                ->exists();

            if ($exists) {
                $skipped++;
                continue;
            }

            $batch[] = [
                'node_id' => $node->id,
                'ip' => $ip,
                'port' => $p,
                'ip_alias' => null,
                'server_id' => null,
                'notes' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            if (count($batch) >= 200) {
                Allocation::insert($batch);
                $created += count($batch);
                $batch = [];
            }
        }

        if (!empty($batch)) {
            Allocation::insert($batch);
            $created += count($batch);
        }

        echo "ALLOC_NODE:" . $node->id . ":created=" . $created . ":skipped=" . $skipped . "\n";
    }

    echo "SUCCESS\n";

} catch (\Exception $e) {
    fwrite(STDERR, "ERROR: " . $e->getMessage() . "\n");
    exit(1);
}
PHP_EOF

php "$PHP_SCRIPT" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}   NEST + EGG + ALLOCATION BERHASIL${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo -e "${CYAN}📦 Nest       : Bot WhatsApp (ID 5)${NC}"
  echo -e "${CYAN}🥚 Egg        : RexzyStore🌐${NC}"
  echo -e "${CYAN}🌐 IP         : 0.0.0.0${NC}"
  echo -e "${CYAN}🔢 Port Range : 2000-2900 (Node ID 1)${NC}"
  echo -e "${GREEN}========================================${NC}"
else
  echo ""
  echo -e "${RED}========================================${NC}"
  echo -e "${RED}   GAGAL IMPORT${NC}"
  echo -e "${RED}========================================${NC}"
fi

chown -R www-data:www-data "$PANEL_DIR/storage" "$PANEL_DIR/bootstrap/cache" 2>/dev/null
php artisan optimize:clear --no-interaction 2>/dev/null

rm -f "$PHP_SCRIPT"
