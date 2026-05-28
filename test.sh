#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
SESSION_FILE="$SCRIPT_DIR/session-starter.sh"
LOG_FILE="$SCRIPT_DIR/sessions.log"

PASS=0
FAIL=0

# ── Colors ────────────────────────────────────────────────────────────────────
export NEWT_COLORS='
root=,black
border=brown,black
window=brown,black
shadow=black,black
title=yellow,black
button=black,brown
actbutton=white,brown
checkbox=brown,black
actcheckbox=black,brown
entry=brown,black
label=brown,black
listbox=brown,black
actlistbox=black,brown
textbox=brown,black
acttextbox=black,brown
helpline=,black
roottext=brown,black
emptyscale=black,black
disabledentry=gray,black
'

# ── Language selection (always ask) ──────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null || true
_DEFAULT_LANG="${LANGUAGE:-en}"

if command -v whiptail >/dev/null 2>&1; then
    LANGUAGE=$(whiptail --title "Language" \
        --menu "Choose language / Elige idioma:" 10 45 2 \
        "en" "English" \
        "es" "Español" \
        3>&1 1>&2 2>&3) || LANGUAGE="$_DEFAULT_LANG"
else
    printf "\nChoose language / Elige idioma:\n  1) English\n  2) Español\n"
    read -rp "Choice [1/2, default=1]: " _c
    [[ "${_c:-1}" == "2" ]] && LANGUAGE="es" || LANGUAGE="en"
fi

# ── String tables ─────────────────────────────────────────────────────────────
if [[ "$LANGUAGE" == "es" ]]; then
    T_TITLE="── Prueba de Humo — Claude Session ──"
    T_OS="Sistema operativo: Linux"
    T_OS_F="Requiere Linux — ejecuta este script en tu servidor"
    T_CRON="Servicio cron activo"
    T_CRON_F="Cron no está activo — sudo systemctl start cron"
    T_CLAUDE="Claude Code instalado"
    T_CLAUDE_F="Claude Code no encontrado — ejecuta install.sh"
    T_CONFIG="config.sh encontrado"
    T_CONFIG_F="config.sh no encontrado — ejecuta install.sh"
    T_CRONTAB="Entradas crontab presentes"
    T_CRONTAB_F="Sin entradas en crontab — ejecuta install.sh"
    T_RUNNING="Ejecutando session-starter.sh"
    T_LOG_OK="Log actualizado correctamente"
    T_LOG_F="El log no se actualizó (¿iniciaste sesión con claude login?)"
    T_ALL_OK="── Todas las Pruebas Pasaron — Claude Session ──"
    T_FAIL_S="── %d Prueba(s) Fallaron — Claude Session ──"
    T_LOGIN="Inicia sesión en Claude:  claude login"
else
    T_TITLE="── Smoke Test — Claude Session ──"
    T_OS="OS: Linux"
    T_OS_F="Requires Linux — run this on your server, not Windows"
    T_CRON="Cron service is active"
    T_CRON_F="Cron is not active — sudo systemctl start cron"
    T_CLAUDE="Claude Code installed"
    T_CLAUDE_F="Claude Code not found — run install.sh"
    T_CONFIG="config.sh found"
    T_CONFIG_F="config.sh not found — run install.sh"
    T_CRONTAB="Crontab entries present"
    T_CRONTAB_F="No crontab entries — run install.sh"
    T_RUNNING="Running session-starter.sh"
    T_LOG_OK="Log updated successfully"
    T_LOG_F="Log was not updated (did you run: claude login?)"
    T_ALL_OK="── All Tests Passed — Claude Session ──"
    T_FAIL_S="── %d Test(s) Failed — Claude Session ──"
    T_LOGIN="Log in to Claude:  claude login"
fi

_ok()   { echo "  ✓ $*"; (( PASS++ )) || true; }
_fail() { echo "  ✗ $*"; (( FAIL++ )) || true; }
_info() { echo "  • $*"; }

echo ""
printf '\033[1;36m%s\033[0m\n' "$T_TITLE"
echo ""

# 1. OS
[[ "$(uname -s)" == "Linux" ]] && _ok "$T_OS" || _fail "$T_OS_F"

# 2. Cron
systemctl is-active cron >/dev/null 2>&1 && _ok "$T_CRON" || _fail "$T_CRON_F"

# 3. Claude
if command -v claude >/dev/null 2>&1; then
    _ok "$T_CLAUDE: $(claude --version 2>/dev/null | head -1)"
else
    _fail "$T_CLAUDE_F"
fi

# 4. config.sh
[[ -f "$CONFIG_FILE" ]] && _ok "$T_CONFIG" || _fail "$T_CONFIG_F"

# 5. Crontab
crontab -l 2>/dev/null | grep -q "session-starter" \
    && _ok "$T_CRONTAB" || _fail "$T_CRONTAB_F"

# 6. Run session-starter and check log
if [[ -x "$SESSION_FILE" ]]; then
    echo ""
    _info "$T_RUNNING..."
    LOG_BEFORE=$([ -f "$LOG_FILE" ] && wc -l < "$LOG_FILE" || echo 0)
    bash "$SESSION_FILE" 2>&1 | sed 's/^/    /'
    LOG_AFTER=$([ -f "$LOG_FILE" ] && wc -l < "$LOG_FILE" || echo 0)
    (( LOG_AFTER > LOG_BEFORE )) && _ok "$T_LOG_OK" || _fail "$T_LOG_F"
fi

echo ""
if (( FAIL == 0 )); then
    printf '\033[1;32m%s\033[0m\n' "$T_ALL_OK"
else
    printf '\033[1;31m'"$T_FAIL_S"'\033[0m\n' "$FAIL"
    echo ""
    echo "  ⚠  $T_LOGIN"
fi
echo ""
exit "$FAIL"
