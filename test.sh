#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

PASS=0
FAIL=0
RENEW_DAYS=30  # how long before the year token ends the test fails, so it gets renewed in time
load_config

T_TITLE="PRUEBA DE TUS AGENTES"
T_ASK="Esto le envía ahora un mensaje a cada agente de la sesión automática, y su ventana de uso empieza en este momento. ¿Seguir?"
T_NOT_SENT="No se envió nada."
T_OS="Sistema operativo Linux"
T_OS_F="Requiere Linux, corre esta prueba en tu servidor"
T_CRON="El servicio cron está activo"
T_CRON_F="Cron no está activo, actívalo con sudo systemctl start cron"
T_CONFIG="config.sh encontrado"
T_CONFIG_F="Falta config.sh, corre install.sh"
T_CRONTAB="El crontab tiene sus entradas"
T_CRONTAB_F="El crontab no tiene entradas, corre keepalive update"
T_ALL_OK="Todas las pruebas pasaron."
T_FAIL_ONE="Falló una prueba."; T_FAIL_MANY="Fallaron %d pruebas."
T_TOKEN="El token de Claude está vigente"
T_TOKEN_SOON="El token de Claude vence pronto, vuelve a conectar Claude"
T_DAYS="días"
T_AGENT_OK="instalado y con sesión"
T_AGENT_NO_LOGIN="sin sesión, conéctalo con"
T_AGENT_MISSING="no instalado, instálalo con"
T_RUN_AGENT="Enviando a %s"
T_G_SETUP="LA INSTALACIÓN"; T_G_RUNS="UN ENVÍO A CADA AGENTE"

_ok()   { ui_ok "$*"; (( PASS++ )) || true; }
_fail() { ui_fail "$*"; (( FAIL++ )) || true; }

ui_section "$T_TITLE"
if [[ "${1:-}" == "--ask" ]]; then
    ui_yes "$T_ASK" false || { ui_note "$T_NOT_SENT"; exit "$BACK"; }
fi
ui_group "$T_G_SETUP"

# 1. OS
[[ "$(uname -s)" == "Linux" ]] && _ok "$T_OS" || _fail "$T_OS_F"

# 2. Cron
systemctl is-active cron >/dev/null 2>&1 && _ok "$T_CRON" || _fail "$T_CRON_F"

# 3. Every agent in the automatic session, and the year-long Claude token
for agent in $AGENTS; do
    if ! agent_installed "$agent"; then
        _fail "$(agent_title "$agent") $T_AGENT_MISSING sudo npm install -g $(agent_package "$agent")"
    elif agent_logged_in "$agent"; then
        _ok "$(agent_title "$agent") $T_AGENT_OK"
    else
        _fail "$(agent_title "$agent") $T_AGENT_NO_LOGIN $(agent_login_command "$agent")"
    fi
done
if [[ -s "$CLAUDE_TOKEN" ]]; then
    CREATED=$(cat "$CLAUDE_TOKEN.created" 2>/dev/null || date +%F)
    LEFT=$(( ( $(date -d "$CREATED +1 year" +%s) - $(date +%s) ) / 86400 ))
    (( LEFT > RENEW_DAYS )) && _ok "$T_TOKEN ($LEFT $T_DAYS)" || _fail "$T_TOKEN_SOON ($LEFT $T_DAYS)"
fi

# 4. config.sh
[[ -f "$CONFIG_FILE" ]] && _ok "$T_CONFIG" || _fail "$T_CONFIG_F"

# 5. Crontab
crontab -l 2>/dev/null | grep -q "session-starter" \
    && _ok "$T_CRONTAB" || _fail "$T_CRONTAB_F"

# 6. One real run per agent, checked in its log
ui_group "$T_G_RUNS"
for agent in $AGENTS; do
    LOG_FILE="$(agent_log "$agent")"
    printf '  %s\r' "$(printf "$T_RUN_AGENT" "$(agent_title "$agent")")"
    bash "$SESSION_FILE" morning "$agent" >/dev/null 2>&1
    printf '\033[2K'
    LAST=$(grep -sE '\] (OK|LIMIT|ERROR)' "$LOG_FILE" | tail -1)
    RUN=$(describe_run "$LAST")
    WHEN="${RUN#*|}" WHEN="${WHEN%%|*}" WHAT="${RUN##*|}"
    if [[ "${RUN%%|*}" == error ]]; then
        _fail "$(agent_title "$agent"), $WHEN, $WHAT"
    else
        _ok "$(agent_title "$agent"), $WHEN, $WHAT"
    fi
done

echo ""
if (( FAIL == 0 )); then
    ui_ok "$T_ALL_OK"
elif (( FAIL == 1 )); then
    ui_fail "$T_FAIL_ONE"
else
    ui_fail "$(printf "$T_FAIL_MANY" "$FAIL")"
fi
echo ""
(( FAIL == 0 ))
