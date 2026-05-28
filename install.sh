#!/bin/bash
# Claude Code session keep-alive — installer for Ubuntu Server
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
SESSION_FILE="$SCRIPT_DIR/session-starter.sh"

# ── OS check ──────────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "ERROR: This script must run on Linux (Ubuntu Server)."
    echo "       Copy this repository to your server and run it there."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: apt-get not found. Only Ubuntu/Debian is supported."
    exit 1
fi

# ── Verify sudo once ──────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "This installer needs sudo to install packages. You may be prompted for your password."
    sudo -v || { echo "ERROR: sudo access required."; exit 1; }
fi

# ── Language selection ────────────────────────────────────────────────────────
_pick_lang() {
    if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "Claude Session Installer" \
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

# ── String tables ─────────────────────────────────────────────────────────────
if [[ "$LANGUAGE" == "es" ]]; then
    S_TITLE="Instalador de sesión de Claude"
    S_DEPS="Verificando e instalando dependencias"
    S_INSTALLING="Instalando"
    S_INSTALLED="ya instalado"
    S_NODE_INSTALL="Instalando Node.js LTS"
    S_CLAUDE_INSTALL="Instalando Claude Code"
    S_CLAUDE_FOUND="Claude Code encontrado"
    S_CONFIG="Creando configuración"
    S_CRON="Configurando crontab"
    S_DONE="¡Instalación completada!"
    S_LOGIN_WARN="Inicia sesión en Claude con:  claude login"
    S_TEST_CMD="  Prueba:           bash test.sh"
    S_SCHED_CMD="  Editar horario:   bash update-schedule.sh"
    S_SCHED_FMT="  Horario:          %02d:%02d y %02d:%02d — días %s"
    S_ERR_NODE="ERROR: No se pudo instalar Node.js. Instálalo manualmente."
    S_ERR_CLAUDE="ERROR: No se pudo instalar Claude Code."
else
    S_TITLE="Claude Session Installer"
    S_DEPS="Checking and installing dependencies"
    S_INSTALLING="Installing"
    S_INSTALLED="already installed"
    S_NODE_INSTALL="Installing Node.js LTS"
    S_CLAUDE_INSTALL="Installing Claude Code"
    S_CLAUDE_FOUND="Claude Code found"
    S_CONFIG="Creating configuration"
    S_CRON="Setting up crontab"
    S_DONE="Installation complete!"
    S_LOGIN_WARN="Log in to Claude with:  claude login"
    S_TEST_CMD="  Test:             bash test.sh"
    S_SCHED_CMD="  Edit schedule:    bash update-schedule.sh"
    S_SCHED_FMT="  Schedule:         %02d:%02d and %02d:%02d — days %s"
    S_ERR_NODE="ERROR: Could not install Node.js. Install it manually."
    S_ERR_CLAUDE="ERROR: Could not install Claude Code."
fi

step() { echo ""; echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
die()  { echo "  ✗ $*"; exit 1; }

echo "┌─────────────────────────────────────┐"
printf "│  %-36s│\n" "$S_TITLE"
echo "└─────────────────────────────────────┘"
echo ""

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

# ── config.sh ─────────────────────────────────────────────────────────────────
step "$S_CONFIG"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash
LANGUAGE="$LANGUAGE"
MORNING_HOUR=7
MORNING_MINUTE=0
AFTERNOON_HOUR=12
AFTERNOON_MINUTE=0
WEEKDAYS="1,2,3,4,5"
MAX_LOG_LINES=200
EOF
    chmod +x "$CONFIG_FILE"
    ok "config.sh created"
else
    # Preserve existing settings; only update language
    sed -i "s/^LANGUAGE=.*/LANGUAGE=\"$LANGUAGE\"/" "$CONFIG_FILE"
    ok "config.sh already exists (settings preserved)"
fi

source "$CONFIG_FILE"

# ── Permissions ───────────────────────────────────────────────────────────────
chmod +x "$SESSION_FILE"         2>/dev/null || true
chmod +x "$SCRIPT_DIR/update-schedule.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/test.sh"   2>/dev/null || true
chmod +x "$SCRIPT_DIR/uninstall.sh" 2>/dev/null || true

# ── Crontab ───────────────────────────────────────────────────────────────────
step "$S_CRON"

{
    crontab -l 2>/dev/null | grep -v "session-starter" | grep -v "# Claude session" || true
    echo ""
    echo "# Claude session - morning"
    echo "$MORNING_MINUTE $MORNING_HOUR * * $WEEKDAYS $SESSION_FILE"
    echo "# Claude session - afternoon"
    echo "$AFTERNOON_MINUTE $AFTERNOON_HOUR * * $WEEKDAYS $SESSION_FILE"
} | crontab -

ok "crontab configured"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────┐"
printf "│  %-36s│\n" "$S_DONE"
echo "└─────────────────────────────────────┘"
echo ""
printf "  $S_SCHED_FMT\n" \
    "$MORNING_HOUR" "$MORNING_MINUTE" \
    "$AFTERNOON_HOUR" "$AFTERNOON_MINUTE" \
    "$WEEKDAYS"
echo ""
echo "$S_TEST_CMD"
echo "$S_SCHED_CMD"
echo ""
printf "  ⚠  %s\n" "$S_LOGIN_WARN"
echo ""
