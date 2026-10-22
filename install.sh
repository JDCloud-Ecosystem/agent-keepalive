#!/bin/bash
set -uo pipefail

KEEPALIVE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/load.sh
source "$KEEPALIVE_DIR/lib/load.sh"

# ── OS / apt check ────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Este instalador corre en Linux, en Ubuntu o Debian. Copia el repositorio a tu servidor y córrelo ahí."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "No está apt-get. Solo funciona en Ubuntu o Debian."
    exit 1
fi

# ── Sudo check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "El instalador necesita sudo para instalar paquetes, y te puede pedir tu contraseña."
    sudo -v || { echo "Sin sudo no se puede instalar."; exit 1; }
fi

clear

# ── ASCII header (always in cyan, not translated) ─────────────────────────────
printf '\033[1;36m%s\033[0m\n' '░█▀▀░█░░░█▀█░█░█░█▀▄░█▀▀░░░█▀▀░█▀▀░█▀▀░█▀▀░▀█▀░█▀█░█▀█'
printf '\033[1;36m%s\033[0m\n' '░█░░░█░░░█▀█░█░█░█░█░█▀▀░░░▀▀█░█▀▀░▀▀█░▀▀█░░█░░█░█░█░█'
printf '\033[1;36m%s\033[0m\n' '░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀░░▀▀▀░░░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀'
printf '\033[1;36m%s\033[0m\n' '░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░░█▀▀░█▀▄░█                '
printf '\033[1;36m%s\033[0m\n' '░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░░█▀▀░█▀▄░▀                '
printf '\033[1;36m%s\033[0m\n' '░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀                '
echo ""

# ── String tables ─────────────────────────────────────────────────────────────
S_DEPS="Verificando e instalando dependencias"
S_INSTALLING="Instalando"
S_INSTALLED="ya instalado"
S_NOT_INSTALLED="no se pudo instalar"
S_NODE_INSTALL="Instalando Node.js LTS"
S_CLAUDE_INSTALL="Instalando Claude Code"
S_CLAUDE_FOUND="Claude Code ya instalado"
S_CONFIG="Creando la configuración"
S_CONFIG_NEW="config.sh creado"
S_CONFIG_KEPT="config.sh ya existía y se quedó igual"
S_CRON="Configurando el crontab"
S_CRON_OK="crontab listo"
S_DONE="INSTALACIÓN COMPLETA"
S_LOGIN_WARN="Conecta tus agentes desde el menú, con keepalive. Claude queda conectado por un año."
S_TEST_CMD="  Todo en un comando:  keepalive"
S_SCHED_CMD="  Horario y agentes:   keepalive schedule"
S_M_FMT="  Mañana:   %02d:%02d"
S_A_FMT="  Tarde:    %02d:%02d"
S_N_FMT="  Noche:    %02d:%02d"
S_N_OFF="  Noche:    desactivada"
S_D_FMT="  Días:     %s"
S_CODEX_INSTALL="Instalando Codex"
S_CODEX_FOUND="Codex ya instalado"
S_WARN_CODEX="No se pudo instalar Codex. Para instalarlo, corre: sudo npm install -g @openai/codex"
S_ERR_NODE="No se pudo instalar Node.js. Instálalo a mano."
S_ERR_CLAUDE="No se pudo instalar Claude Code."

step() { echo ""; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
die()  { echo "  ✗ $*"; exit 1; }

# ── Package dependencies ──────────────────────────────────────────────────────
step "$S_DEPS"
sudo apt-get update -qq 2>/dev/null

_pkg() {
    if dpkg -s "$1" >/dev/null 2>&1; then
        ok "$1 $S_INSTALLED"
    else
        printf "  %s %s... " "$S_INSTALLING" "$1"
        if sudo apt-get install -y "$1" -qq >/dev/null 2>&1; then
            echo "✓"
        else
            warn "$1 $S_NOT_INSTALLED"
        fi
    fi
}

for _p in git curl cron; do _pkg "$_p"; done

sudo systemctl enable cron >/dev/null 2>&1 || true
sudo systemctl start  cron >/dev/null 2>&1 || true

# ── Node.js ───────────────────────────────────────────────────────────────────
if ! command -v node >/dev/null 2>&1; then
    step "$S_NODE_INSTALL"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null 2>&1 \
        && sudo apt-get install -y nodejs -qq >/dev/null 2>&1 \
        || die "$S_ERR_NODE"
    ok "node $(node --version)"
else
    ok "node $(node --version) $S_INSTALLED"
fi

# ── Claude Code ───────────────────────────────────────────────────────────────
if ! command -v claude >/dev/null 2>&1; then
    step "$S_CLAUDE_INSTALL"
    sudo npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 \
        || die "$S_ERR_CLAUDE"
    ok "claude $(claude --version 2>/dev/null | head -1)"
else
    ok "$S_CLAUDE_FOUND, $(claude --version 2>/dev/null | head -1)"
fi

# ── Codex ─────────────────────────────────────────────────────────────────────
if ! command -v codex >/dev/null 2>&1; then
    step "$S_CODEX_INSTALL"
    sudo npm install -g @openai/codex >/dev/null 2>&1 \
        && ok "codex $(codex --version 2>/dev/null | head -1)" \
        || warn "$S_WARN_CODEX"
else
    ok "$S_CODEX_FOUND, $(codex --version 2>/dev/null | head -1)"
fi

# ── config.sh ─────────────────────────────────────────────────────────────────
step "$S_CONFIG"

mkdir -p "$LOG_DIR" && chmod 700 "$STATE_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash
MORNING_HOUR=7
MORNING_MINUTE=0
MORNING_ENABLED=true
AFTERNOON_HOUR=12
AFTERNOON_MINUTE=0
AFTERNOON_ENABLED=true
NIGHT_HOUR=17
NIGHT_MINUTE=0
NIGHT_ENABLED=false
AGENTS="claude"
WEEKDAYS="1,2,3,4,5"
MAX_LOG_LINES=200
EOF
    chmod +x "$CONFIG_FILE"
    ok "$S_CONFIG_NEW"
else
    ok "$S_CONFIG_KEPT"
fi

# Add new variables if missing (migration for existing installs)
_add_if_missing() {
    grep -q "^${1}=" "$CONFIG_FILE" || echo "${1}=${2}" >> "$CONFIG_FILE"
}
_add_if_missing 'MORNING_ENABLED'   'true'
_add_if_missing 'AFTERNOON_ENABLED' 'true'
_add_if_missing 'NIGHT_HOUR'        '17'
_add_if_missing 'NIGHT_MINUTE'      '0'
_add_if_missing 'NIGHT_ENABLED'     'false'
if ! grep -q '^AGENTS=' "$CONFIG_FILE"; then
    grep -q '^CODEX_ENABLED=true' "$CONFIG_FILE" && echo 'AGENTS="claude codex"' >> "$CONFIG_FILE" || echo 'AGENTS="claude"' >> "$CONFIG_FILE"
    sed -i '/^CODEX_ENABLED=/d' "$CONFIG_FILE"
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ── Permissions ───────────────────────────────────────────────────────────────
chmod +x "$KEEPALIVE_DIR"/*.sh "$KEEPALIVE_DIR"/scripts/*.sh "$KEEPALIVE_DIR/keepalive" 2>/dev/null || true
# One command for everything: keepalive
mkdir -p "$HOME/.local/bin" && ln -sf "$KEEPALIVE_DIR/keepalive" "$HOME/.local/bin/keepalive"
migrate_token

# Ignore fileMode changes so git pull works cleanly after chmod
git -C "$KEEPALIVE_DIR" config core.fileMode false 2>/dev/null || true

# ── Crontab ───────────────────────────────────────────────────────────────────
step "$S_CRON"

write_crontab

ok "$S_CRON_OK"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
ui_section "$S_DONE"
echo ""
[[ "${MORNING_ENABLED:-true}"   == "true" ]] && printf "$S_M_FMT\n" "$MORNING_HOUR"         "$MORNING_MINUTE"
[[ "${AFTERNOON_ENABLED:-true}" == "true" ]] && printf "$S_A_FMT\n" "$AFTERNOON_HOUR"        "$AFTERNOON_MINUTE"
if [[ "${NIGHT_ENABLED:-false}" == "true" ]]; then
    printf "$S_N_FMT\n" "${NIGHT_HOUR:-17}" "${NIGHT_MINUTE:-0}"
else
    echo "$S_N_OFF"
fi
printf "$S_D_FMT\n" "$WEEKDAYS"
echo ""
echo "$S_TEST_CMD"
echo "$S_SCHED_CMD"
echo ""
ui_warn "$S_LOGIN_WARN"
echo ""
