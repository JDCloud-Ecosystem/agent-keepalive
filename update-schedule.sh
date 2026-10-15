#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config.sh not found / config.sh no encontrado. Run install.sh first."
    exit 1
fi

if ! command -v whiptail >/dev/null 2>&1; then
    echo "ERROR: whiptail not found. Run install.sh to install it."
    exit 1
fi

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
source "$CONFIG_FILE"
_DEFAULT_LANG="${LANGUAGE:-en}"

LANGUAGE=$(whiptail --title "Language" \
    --menu "Choose language / Elige idioma:" 10 45 2 \
    "en" "English" \
    "es" "Español" \
    3>&1 1>&2 2>&3) || LANGUAGE="$_DEFAULT_LANG"

# Re-source for schedule values (MORNING_HOUR, etc.) without overriding LANGUAGE
_SAVED_LANG="$LANGUAGE"
source "$CONFIG_FILE"
LANGUAGE="$_SAVED_LANG"

# Defaults for variables not present in older config.sh
MORNING_ENABLED="${MORNING_ENABLED:-true}"
AFTERNOON_ENABLED="${AFTERNOON_ENABLED:-true}"
NIGHT_ENABLED="${NIGHT_ENABLED:-false}"
NIGHT_HOUR="${NIGHT_HOUR:-17}"
NIGHT_MINUTE="${NIGHT_MINUTE:-0}"
# Older configs only knew CODEX_ENABLED; they keep meaning the same thing.
if [[ -z "${AGENTS:-}" ]]; then AGENTS="claude"; [[ "${CODEX_ENABLED:-false}" == "true" ]] && AGENTS="claude codex"; fi

# ── String tables ─────────────────────────────────────────────────────────────
if [[ "$LANGUAGE" == "es" ]]; then
    T_TITLE="Horario de tus agentes"
    T_DAYS="Selecciona los días activos:"
    T_SUN="Domingo"   T_MON="Lunes"    T_TUE="Martes"  T_WED="Miércoles"
    T_THU="Jueves"    T_FRI="Viernes"  T_SAT="Sábado"
    T_SESSIONS="Activa o desactiva las sesiones:"
    T_MORNING_S="Sesión matutina"
    T_AFTERNOON_S="Sesión vespertina"
    T_NIGHT_S="Sesión nocturna (opcional)"
    T_M_HOUR="Hora de la sesión matutina (0-23):"
    T_M_MIN="Minuto de la sesión matutina (0-59):"
    T_A_HOUR="Hora de la sesión vespertina (0-23):"
    T_A_MIN="Minuto de la sesión vespertina (0-59):"
    T_N_HOUR="Hora de la sesión nocturna (0-23):"
    T_N_MIN="Minuto de la sesión nocturna (0-59):"
    T_CONFIRM="¿Aplicar este horario?"
    T_M_FMT="Mañana:    %02d:%02d"
    T_A_FMT="Tarde:     %02d:%02d"
    T_N_FMT="Noche:     %02d:%02d"
    T_M_DIS="Mañana:    desactivada"
    T_A_DIS="Tarde:     desactivada"
    T_N_DIS="Noche:     desactivada"
    T_D_FMT="Días:      %s"
    T_DONE="── Horario aplicado ──"
    T_CANCELLED="Cancelado."
    T_BAD_HOUR="ERROR: La hora debe ser un número entre 0 y 23."
    T_BAD_MIN="ERROR: El minuto debe ser un número entre 0 y 59."
    T_AGENTS_Q="¿Qué agentes reciben la sesión automática? Todos usan el mismo horario."
    T_AGENTS_FMT="Agentes:   %s"
    T_MISSING="no instalado"
    T_NO_AGENTS="ERROR: Elige al menos un agente."
    T_NO_DAYS="ERROR: Selecciona al menos un día."
    T_NO_SESSIONS="ERROR: Activa al menos una sesión."
else
    T_TITLE="Your agents' schedule"
    T_DAYS="Select active days:"
    T_SUN="Sunday"    T_MON="Monday"   T_TUE="Tuesday"  T_WED="Wednesday"
    T_THU="Thursday"  T_FRI="Friday"   T_SAT="Saturday"
    T_SESSIONS="Enable or disable sessions:"
    T_MORNING_S="Morning session"
    T_AFTERNOON_S="Afternoon session"
    T_NIGHT_S="Night session (optional)"
    T_M_HOUR="Morning session hour (0-23):"
    T_M_MIN="Morning session minute (0-59):"
    T_A_HOUR="Afternoon session hour (0-23):"
    T_A_MIN="Afternoon session minute (0-59):"
    T_N_HOUR="Night session hour (0-23):"
    T_N_MIN="Night session minute (0-59):"
    T_CONFIRM="Apply this schedule?"
    T_M_FMT="Morning:   %02d:%02d"
    T_A_FMT="Afternoon: %02d:%02d"
    T_N_FMT="Night:     %02d:%02d"
    T_M_DIS="Morning:   disabled"
    T_A_DIS="Afternoon: disabled"
    T_N_DIS="Night:     disabled"
    T_D_FMT="Days:      %s"
    T_DONE="── Schedule applied ──"
    T_CANCELLED="Cancelled."
    T_BAD_HOUR="ERROR: Hour must be a number between 0 and 23."
    T_BAD_MIN="ERROR: Minute must be a number between 0 and 59."
    T_AGENTS_Q="Which agents get the automatic session? They all share the schedule."
    T_AGENTS_FMT="Agents:    %s"
    T_MISSING="not installed"
    T_NO_AGENTS="ERROR: Choose at least one agent."
    T_NO_DAYS="ERROR: Select at least one day."
    T_NO_SESSIONS="ERROR: Enable at least one session."
fi

# ── Helper: check if a day is in WEEKDAYS ─────────────────────────────────────
_has_day() {
    local d="$1"
    local IFS=','
    for _d in $WEEKDAYS; do
        [[ "$_d" == "$d" ]] && return 0
    done
    return 1
}
_on()  { _has_day "$1" && echo "ON" || echo "OFF"; }
_son() { [[ "${!1}" == "true" ]] && echo "ON" || echo "OFF"; }

# ── Day checklist ─────────────────────────────────────────────────────────────
DAYS_RAW=$(whiptail --title "$T_TITLE" --checklist \
    "$T_DAYS" 18 42 7 \
    "0" "$T_SUN" "$(_on 0)" \
    "1" "$T_MON" "$(_on 1)" \
    "2" "$T_TUE" "$(_on 2)" \
    "3" "$T_WED" "$(_on 3)" \
    "4" "$T_THU" "$(_on 4)" \
    "5" "$T_FRI" "$(_on 5)" \
    "6" "$T_SAT" "$(_on 6)" \
    3>&1 1>&2 2>&3) || { echo "$T_CANCELLED"; exit 0; }

NEW_WEEKDAYS=$(echo "$DAYS_RAW" | tr -d '"' | xargs | tr ' ' ',')

if [[ -z "$NEW_WEEKDAYS" ]]; then
    echo "$T_NO_DAYS"; exit 1
fi

# ── Session enable/disable checklist ─────────────────────────────────────────
SESSIONS_RAW=$(whiptail --title "$T_TITLE" --checklist \
    "$T_SESSIONS" 12 52 3 \
    "morning"   "$T_MORNING_S"   "$(_son MORNING_ENABLED)" \
    "afternoon" "$T_AFTERNOON_S" "$(_son AFTERNOON_ENABLED)" \
    "night"     "$T_NIGHT_S"     "$(_son NIGHT_ENABLED)" \
    3>&1 1>&2 2>&3) || { echo "$T_CANCELLED"; exit 0; }

NEW_MORNING_ENABLED=false
NEW_AFTERNOON_ENABLED=false
NEW_NIGHT_ENABLED=false
[[ "$SESSIONS_RAW" == *'"morning"'*   ]] && NEW_MORNING_ENABLED=true
[[ "$SESSIONS_RAW" == *'"afternoon"'* ]] && NEW_AFTERNOON_ENABLED=true
[[ "$SESSIONS_RAW" == *'"night"'*     ]] && NEW_NIGHT_ENABLED=true

if [[ "$NEW_MORNING_ENABLED" == "false" && \
      "$NEW_AFTERNOON_ENABLED" == "false" && \
      "$NEW_NIGHT_ENABLED" == "false" ]]; then
    echo "$T_NO_SESSIONS"; exit 1
fi

# ── Agents ────────────────────────────────────────────────────────────────────
_agent_rows=()
for _a in $AGENTS_KNOWN; do
    _label="$(agent_title "$_a")"
    agent_installed "$_a" || _label="$_label ($T_MISSING)"
    [[ " $AGENTS " == *" $_a "* ]] && _state=ON || _state=OFF
    _agent_rows+=("$_a" "$_label" "$_state")
done
AGENTS_RAW=$(whiptail --title "$T_TITLE" --checklist "$T_AGENTS_Q" 16 64 5 "${_agent_rows[@]}" \
    3>&1 1>&2 2>&3) || { echo "$T_CANCELLED"; exit 0; }
NEW_AGENTS=$(echo "$AGENTS_RAW" | tr -d '"' | xargs)
[[ -n "$NEW_AGENTS" ]] || { echo "$T_NO_AGENTS"; exit 1; }

# ── Time inputs ───────────────────────────────────────────────────────────────
_ask() {
    whiptail --title "$T_TITLE" --inputbox "$1" 8 42 "$2" 3>&1 1>&2 2>&3
}

if [[ "$NEW_MORNING_ENABLED" == "true" ]]; then
    NEW_M_H=$(_ask "$T_M_HOUR" "$MORNING_HOUR")   || { echo "$T_CANCELLED"; exit 0; }
    NEW_M_M=$(_ask "$T_M_MIN"  "$MORNING_MINUTE") || { echo "$T_CANCELLED"; exit 0; }
else
    NEW_M_H="$MORNING_HOUR"
    NEW_M_M="$MORNING_MINUTE"
fi

if [[ "$NEW_AFTERNOON_ENABLED" == "true" ]]; then
    NEW_A_H=$(_ask "$T_A_HOUR" "$AFTERNOON_HOUR")   || { echo "$T_CANCELLED"; exit 0; }
    NEW_A_M=$(_ask "$T_A_MIN"  "$AFTERNOON_MINUTE") || { echo "$T_CANCELLED"; exit 0; }
else
    NEW_A_H="$AFTERNOON_HOUR"
    NEW_A_M="$AFTERNOON_MINUTE"
fi

if [[ "$NEW_NIGHT_ENABLED" == "true" ]]; then
    NEW_N_H=$(_ask "$T_N_HOUR" "$NIGHT_HOUR")   || { echo "$T_CANCELLED"; exit 0; }
    NEW_N_M=$(_ask "$T_N_MIN"  "$NIGHT_MINUTE") || { echo "$T_CANCELLED"; exit 0; }
else
    NEW_N_H="$NIGHT_HOUR"
    NEW_N_M="$NIGHT_MINUTE"
fi

# ── Validate ──────────────────────────────────────────────────────────────────
_is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }
_check_h() { _is_uint "$1" && (( $1 >= 0 && $1 <= 23 )) || { echo "$T_BAD_HOUR"; exit 1; }; }
_check_m() { _is_uint "$1" && (( $1 >= 0 && $1 <= 59 )) || { echo "$T_BAD_MIN";  exit 1; }; }

if [[ "$NEW_MORNING_ENABLED"   == "true" ]]; then _check_h "$NEW_M_H"; _check_m "$NEW_M_M"; fi
if [[ "$NEW_AFTERNOON_ENABLED" == "true" ]]; then _check_h "$NEW_A_H"; _check_m "$NEW_A_M"; fi
if [[ "$NEW_NIGHT_ENABLED"     == "true" ]]; then _check_h "$NEW_N_H"; _check_m "$NEW_N_M"; fi

# ── Confirmation ──────────────────────────────────────────────────────────────
[[ "$NEW_MORNING_ENABLED"   == "true" ]] && _ml=$(printf "$T_M_FMT" "$NEW_M_H" "$NEW_M_M") || _ml="$T_M_DIS"
[[ "$NEW_AFTERNOON_ENABLED" == "true" ]] && _al=$(printf "$T_A_FMT" "$NEW_A_H" "$NEW_A_M") || _al="$T_A_DIS"
[[ "$NEW_NIGHT_ENABLED"     == "true" ]] && _nl=$(printf "$T_N_FMT" "$NEW_N_H" "$NEW_N_M") || _nl="$T_N_DIS"
_cl=$(printf "$T_AGENTS_FMT" "$NEW_AGENTS")

SUMMARY=$(printf "%s\n%s\n%s\n%s\n%s" \
    "$_ml" \
    "$_al" \
    "$_nl" \
    "$(printf "$T_D_FMT" "$NEW_WEEKDAYS")" \
    "$_cl")

whiptail --title "$T_TITLE" --yesno "$T_CONFIRM\n\n$SUMMARY" 18 56 \
    3>&1 1>&2 2>&3 || { echo "$T_CANCELLED"; exit 0; }

# ── Update config.sh ──────────────────────────────────────────────────────────
_set_conf() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

_set_conf 'MORNING_HOUR'      "$NEW_M_H"
_set_conf 'MORNING_MINUTE'    "$NEW_M_M"
_set_conf 'MORNING_ENABLED'   "$NEW_MORNING_ENABLED"
_set_conf 'AFTERNOON_HOUR'    "$NEW_A_H"
_set_conf 'AFTERNOON_MINUTE'  "$NEW_A_M"
_set_conf 'AFTERNOON_ENABLED' "$NEW_AFTERNOON_ENABLED"
_set_conf 'NIGHT_HOUR'        "$NEW_N_H"
_set_conf 'NIGHT_MINUTE'      "$NEW_N_M"
_set_conf 'NIGHT_ENABLED'     "$NEW_NIGHT_ENABLED"
_set_conf 'AGENTS'            "\"$NEW_AGENTS\""
sed -i '/^CODEX_ENABLED=/d' "$CONFIG_FILE"
_set_conf 'WEEKDAYS'          "\"$NEW_WEEKDAYS\""

# ── Update crontab ────────────────────────────────────────────────────────────
write_crontab

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
printf '\033[1;32m%s\033[0m\n' "$T_DONE"
printf "  %s\n" "$_ml"
printf "  %s\n" "$_al"
printf "  %s\n" "$_nl"
printf "  $T_D_FMT\n" "$NEW_WEEKDAYS"
printf "  %s\n" "$_cl"
echo ""
