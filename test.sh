#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

PASS=0
FAIL=0

# ── Colors ────────────────────────────────────────────────────────────────────
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
    T_TITLE="── Prueba de Humo — agent-keepalive ──"
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
    T_ALL_OK="── Todas las Pruebas Pasaron — agent-keepalive ──"
    T_FAIL_S="── %d Prueba(s) Fallaron — agent-keepalive ──"
    T_LOGIN="keepalive login"
    T_TOKEN="Claude conectado por un año"
    T_TOKEN_SOON="El token de Claude vence pronto: keepalive login claude"
    T_DAYS="días"
    T_AGENT_OK="instalado y con sesión"
    T_AGENT_NO_LOGIN="sin sesión: ejecuta"
    T_AGENT_MISSING="no instalado: ejecuta"
    T_RUN_AGENT="Enviando a"
else
    T_TITLE="── Smoke Test — agent-keepalive ──"
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
    T_ALL_OK="── All Tests Passed — agent-keepalive ──"
    T_FAIL_S="── %d Test(s) Failed — agent-keepalive ──"
    T_LOGIN="keepalive login"
    T_TOKEN="Claude connected for a year"
    T_TOKEN_SOON="The Claude token expires soon: keepalive login claude"
    T_DAYS="days"
    T_AGENT_OK="installed and logged in"
    T_AGENT_NO_LOGIN="not logged in: run"
    T_AGENT_MISSING="not installed: run"
    T_RUN_AGENT="Sending to"
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

# 3. Every agent in the automatic session, and the year-long Claude token
load_config
for agent in $AGENTS; do
    if ! agent_installed "$agent"; then
        _fail "$(agent_title "$agent"): $T_AGENT_MISSING sudo npm install -g $(agent_package "$agent")"
    elif agent_logged_in "$agent"; then
        _ok "$(agent_title "$agent"): $T_AGENT_OK"
    else
        _fail "$(agent_title "$agent"): $T_AGENT_NO_LOGIN $(agent_login_command "$agent")"
    fi
done
if [[ -s "$CLAUDE_TOKEN" ]]; then
    CREATED=$(cat "$CLAUDE_TOKEN.created" 2>/dev/null || date +%F)
    LEFT=$(( ( $(date -d "$CREATED +1 year" +%s) - $(date +%s) ) / 86400 ))
    (( LEFT > 30 )) && _ok "$T_TOKEN ($LEFT $T_DAYS)" || _fail "$T_TOKEN_SOON ($LEFT $T_DAYS)"
fi

# 4. config.sh
[[ -f "$CONFIG_FILE" ]] && _ok "$T_CONFIG" || _fail "$T_CONFIG_F"

# 5. Crontab
crontab -l 2>/dev/null | grep -q "session-starter" \
    && _ok "$T_CRONTAB" || _fail "$T_CRONTAB_F"

# 6. One real run per agent, checked in its log
for agent in $AGENTS; do
    LOG_FILE="$(agent_log "$agent")"
    echo ""
    _info "$T_RUN_AGENT $(agent_title "$agent")..."
    bash "$SESSION_FILE" morning "$agent" >/dev/null 2>&1
    LAST=$(grep -sE '\] (OK|LIMIT|ERROR)' "$LOG_FILE" | tail -1)
    [[ "$LAST" =~ \]\ (OK|LIMIT) ]] && _ok "${LAST#*] [*] }" || _fail "${LAST#*] [*] }"
done

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
