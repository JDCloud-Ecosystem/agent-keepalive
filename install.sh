#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
SESSION_FILE="$SCRIPT_DIR/session-starter.sh"

# ── OS / apt check ────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "ERROR: This script must run on Linux (Ubuntu Server)."
    echo "       Copy this repository to your server and run it there."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: apt-get not found. Only Ubuntu/Debian is supported."
    exit 1
fi

# ── Sudo check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "This installer needs sudo to install packages. You may be prompted for your password."
    sudo -v || { echo "ERROR: sudo access required."; exit 1; }
fi

# ── Colors & language ─────────────────────────────────────────────────────────
_set_colors() {
    export NEWT_COLORS='
root=,black
border=yellow,black
window=yellow,black
shadow=black,black
title=yellow,black
button=black,yellow
actbutton=white,yellow
checkbox=yellow,black
actcheckbox=black,yellow
entry=yellow,black
label=yellow,black
listbox=yellow,black
actlistbox=black,yellow
textbox=yellow,black
acttextbox=black,yellow
helpline=,black
roottext=yellow,black
emptyscale=black,black
disabledentry=gray,black
'
}

_pick_lang() {
    _set_colors
    if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "Language" \
            --menu "Choose language / Elige idioma:" 10 45 2 \
            "en" "English" \
            "es" "Español" \
            3>&1 1>&2 2>&3 || echo "en"
    else
        printf "\nChoose language / Elige idioma:\n  1) English\n  2) Español\n"
        read -rp "Choice [1/2, default=1]: " _c
        [[ "${_c:-1}" == "2" ]] && echo "es" || echo "en"
    fi
}

LANGUAGE=$(_pick_lang)
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
if [[ "$LANGUAGE" == "es" ]]; then
    S_DEPS="Verificando e instalando dependencias"
    S_INSTALLING="Instalando"
    S_INSTALLED="ya instalado"
    S_NODE_INSTALL="Instalando Node.js LTS"
    S_CLAUDE_INSTALL="Instalando Claude Code"
    S_CLAUDE_FOUND="Claude Code encontrado"
    S_CONFIG="Creando configuración"
    S_CRON="Configurando crontab"
    S_DONE="── ¡Instalación Completada! — Claude Session ──"
    S_LOGIN_WARN="Inicia sesión en Claude con:  claude login"
    S_TEST_CMD="  Prueba:           bash test.sh"
    S_SCHED_CMD="  Editar horario:   bash update-schedule.sh"
    S_M_FMT="  Mañana:           %02d:%02d"
    S_A_FMT="  Tarde:            %02d:%02d"
    S_N_FMT="  Noche:            %02d:%02d"
    S_N_OFF="  Noche:            desactivada"
    S_D_FMT="  Días:             %s"
    S_CODEX_INSTALL="Instalando Codex"
    S_CODEX_FOUND="Codex encontrado"
    S_WARN_CODEX="No se pudo instalar Codex — instálalo con: npm install -g @openai/codex"
    S_ERR_NODE="ERROR: No se pudo instalar Node.js. Instálalo manualmente."
    S_ERR_CLAUDE="ERROR: No se pudo instalar Claude Code."
else
    S_DEPS="Checking and installing dependencies"
    S_INSTALLING="Installing"
    S_INSTALLED="already installed"
    S_NODE_INSTALL="Installing Node.js LTS"
    S_CLAUDE_INSTALL="Installing Claude Code"
    S_CLAUDE_FOUND="Claude Code found"
    S_CONFIG="Creating configuration"
    S_CRON="Setting up crontab"
    S_DONE="── Installation Complete! — Claude Session ──"
    S_LOGIN_WARN="Log in to Claude with:  claude login"
    S_TEST_CMD="  Test:             bash test.sh"
    S_SCHED_CMD="  Edit schedule:    bash update-schedule.sh"
    S_M_FMT="  Morning:          %02d:%02d"
    S_A_FMT="  Afternoon:        %02d:%02d"
    S_N_FMT="  Night:            %02d:%02d"
    S_N_OFF="  Night:            disabled"
    S_D_FMT="  Days:             %s"
    S_CODEX_INSTALL="Installing Codex"
    S_CODEX_FOUND="Codex found"
    S_WARN_CODEX="Could not install Codex — install manually: npm install -g @openai/codex"
    S_ERR_NODE="ERROR: Could not install Node.js. Install it manually."
    S_ERR_CLAUDE="ERROR: Could not install Claude Code."
fi

step() { echo ""; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
die()  { echo "  ✗ $*"; exit 1; }

# ── Package dependencies ──────────────────────────────────────────────────────
step "$S_DEPS"
sudo apt-get update -qq 2>/dev/null

_pkg() {
    if dpkg -s "$1" >/dev/null 2>&1; then
        ok "$1 — $S_INSTALLED"
    else
        printf "  %s %s... " "$S_INSTALLING" "$1"
        if sudo apt-get install -y "$1" -qq >/dev/null 2>&1; then
            echo "✓"
        else
            warn "could not install $1"
        fi
    fi
}

for _p in git curl cron whiptail; do _pkg "$_p"; done

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
    ok "node $(node --version) — $S_INSTALLED"
fi

# ── Claude Code ───────────────────────────────────────────────────────────────
if ! command -v claude >/dev/null 2>&1; then
    step "$S_CLAUDE_INSTALL"
    sudo npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 \
        || die "$S_ERR_CLAUDE"
    ok "claude $(claude --version 2>/dev/null | head -1)"
else
    ok "$S_CLAUDE_FOUND: $(claude --version 2>/dev/null | head -1)"
fi

# ── Codex ─────────────────────────────────────────────────────────────────────
if ! command -v codex >/dev/null 2>&1; then
    step "$S_CODEX_INSTALL"
    sudo npm install -g @openai/codex >/dev/null 2>&1 \
        && ok "codex $(codex --version 2>/dev/null | head -1)" \
        || warn "$S_WARN_CODEX"
else
    ok "$S_CODEX_FOUND: $(codex --version 2>/dev/null | head -1)"
fi

# ── config.sh ─────────────────────────────────────────────────────────────────
step "$S_CONFIG"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash
LANGUAGE="$LANGUAGE"
MORNING_HOUR=7
MORNING_MINUTE=0
MORNING_ENABLED=true
AFTERNOON_HOUR=12
AFTERNOON_MINUTE=0
AFTERNOON_ENABLED=true
NIGHT_HOUR=17
NIGHT_MINUTE=0
NIGHT_ENABLED=false
CODEX_ENABLED=false
WEEKDAYS="1,2,3,4,5"
MAX_LOG_LINES=200
EOF
    chmod +x "$CONFIG_FILE"
    ok "config.sh created"
else
    sed -i "s/^LANGUAGE=.*/LANGUAGE=\"$LANGUAGE\"/" "$CONFIG_FILE"
    ok "config.sh already exists (settings preserved)"
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
_add_if_missing 'CODEX_ENABLED'     'false'

source "$CONFIG_FILE"

# ── Permissions ───────────────────────────────────────────────────────────────
chmod +x "$SESSION_FILE"                          2>/dev/null || true
chmod +x "$SCRIPT_DIR/update-schedule.sh"         2>/dev/null || true
chmod +x "$SCRIPT_DIR/test.sh"                    2>/dev/null || true
chmod +x "$SCRIPT_DIR/uninstall.sh"               2>/dev/null || true

# Ignore fileMode changes so git pull works cleanly after chmod
git -C "$SCRIPT_DIR" config core.fileMode false 2>/dev/null || true

# ── Crontab ───────────────────────────────────────────────────────────────────
step "$S_CRON"

{
    crontab -l 2>/dev/null | grep -v "session-starter" | grep -v "# Claude session" | grep -v "# Codex session" || true
    echo ""
    if [[ "${MORNING_ENABLED:-true}" == "true" ]]; then
        echo "# Claude session - morning"
        echo "$MORNING_MINUTE $MORNING_HOUR * * $WEEKDAYS $SESSION_FILE morning"
    fi
    if [[ "${AFTERNOON_ENABLED:-true}" == "true" ]]; then
        echo "# Claude session - afternoon"
        echo "$AFTERNOON_MINUTE $AFTERNOON_HOUR * * $WEEKDAYS $SESSION_FILE afternoon"
    fi
    if [[ "${NIGHT_ENABLED:-false}" == "true" ]]; then
        echo "# Claude session - night"
        echo "${NIGHT_MINUTE:-0} ${NIGHT_HOUR:-17} * * $WEEKDAYS $SESSION_FILE night"
    fi
    if [[ "${CODEX_ENABLED:-false}" == "true" ]]; then
        if [[ "${MORNING_ENABLED:-true}" == "true" ]]; then
            echo "# Codex session - morning"
            echo "$MORNING_MINUTE $MORNING_HOUR * * $WEEKDAYS $SESSION_FILE morning codex"
        fi
        if [[ "${AFTERNOON_ENABLED:-true}" == "true" ]]; then
            echo "# Codex session - afternoon"
            echo "$AFTERNOON_MINUTE $AFTERNOON_HOUR * * $WEEKDAYS $SESSION_FILE afternoon codex"
        fi
        if [[ "${NIGHT_ENABLED:-false}" == "true" ]]; then
            echo "# Codex session - night"
            echo "${NIGHT_MINUTE:-0} ${NIGHT_HOUR:-17} * * $WEEKDAYS $SESSION_FILE night codex"
        fi
    fi
} | crontab -

ok "crontab configured"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
printf '\033[1;32m%s\033[0m\n' "$S_DONE"
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
printf "  ⚠  %s\n" "$S_LOGIN_WARN"
echo ""
