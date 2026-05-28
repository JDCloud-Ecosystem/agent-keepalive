#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
SESSION_FILE="$SCRIPT_DIR/session-starter.sh"

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

# ── String tables ─────────────────────────────────────────────────────────────
if [[ "$LANGUAGE" == "es" ]]; then
    T_TITLE="Horario de Claude"
    T_DAYS="Selecciona los días activos:"
    T_SUN="Domingo"   T_MON="Lunes"    T_TUE="Martes"  T_WED="Miércoles"
    T_THU="Jueves"    T_FRI="Viernes"  T_SAT="Sábado"
    T_M_HOUR="Hora de la sesión matutina (0-23):"
    T_M_MIN="Minuto de la sesión matutina (0-59):"
    T_A_HOUR="Hora de la sesión vespertina (0-23):"
    T_A_MIN="Minuto de la sesión vespertina (0-59):"
    T_CONFIRM="¿Aplicar este horario?"
    T_M_FMT="Mañana:    %02d:%02d"
    T_A_FMT="Tarde:     %02d:%02d"
    T_D_FMT="Días:      %s"
    T_DONE="── Horario Aplicado — Claude Session ──"
    T_CANCELLED="Cancelado."
    T_BAD_HOUR="ERROR: La hora debe ser un número entre 0 y 23."
    T_BAD_MIN="ERROR: El minuto debe ser un número entre 0 y 59."
    T_NO_DAYS="ERROR: Selecciona al menos un día."
else
    T_TITLE="Claude Schedule"
    T_DAYS="Select active days:"
    T_SUN="Sunday"    T_MON="Monday"   T_TUE="Tuesday"  T_WED="Wednesday"
    T_THU="Thursday"  T_FRI="Friday"   T_SAT="Saturday"
    T_M_HOUR="Morning session hour (0-23):"
    T_M_MIN="Morning session minute (0-59):"
    T_A_HOUR="Afternoon session hour (0-23):"
    T_A_MIN="Afternoon session minute (0-59):"
    T_CONFIRM="Apply this schedule?"
    T_M_FMT="Morning:   %02d:%02d"
    T_A_FMT="Afternoon: %02d:%02d"
    T_D_FMT="Days:      %s"
    T_DONE="── Schedule Applied — Claude Session ──"
    T_CANCELLED="Cancelled."
    T_BAD_HOUR="ERROR: Hour must be a number between 0 and 23."
    T_BAD_MIN="ERROR: Minute must be a number between 0 and 59."
    T_NO_DAYS="ERROR: Select at least one day."
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
_on() { _has_day "$1" && echo "ON" || echo "OFF"; }

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

# ── Time inputs ───────────────────────────────────────────────────────────────
_ask() {
    whiptail --title "$T_TITLE" --inputbox "$1" 8 42 "$2" 3>&1 1>&2 2>&3
}

NEW_M_H=$(_ask "$T_M_HOUR" "$MORNING_HOUR")     || { echo "$T_CANCELLED"; exit 0; }
NEW_M_M=$(_ask "$T_M_MIN"  "$MORNING_MINUTE")   || { echo "$T_CANCELLED"; exit 0; }
NEW_A_H=$(_ask "$T_A_HOUR" "$AFTERNOON_HOUR")   || { echo "$T_CANCELLED"; exit 0; }
NEW_A_M=$(_ask "$T_A_MIN"  "$AFTERNOON_MINUTE") || { echo "$T_CANCELLED"; exit 0; }

# ── Validate ──────────────────────────────────────────────────────────────────
_is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

for _h in "$NEW_M_H" "$NEW_A_H"; do
    _is_uint "$_h" && (( _h >= 0 && _h <= 23 )) || { echo "$T_BAD_HOUR"; exit 1; }
done

for _m in "$NEW_M_M" "$NEW_A_M"; do
    _is_uint "$_m" && (( _m >= 0 && _m <= 59 )) || { echo "$T_BAD_MIN"; exit 1; }
done

# ── Confirmation ──────────────────────────────────────────────────────────────
SUMMARY=$(printf "%s\n%s\n%s" \
    "$(printf "$T_M_FMT" "$NEW_M_H" "$NEW_M_M")" \
    "$(printf "$T_A_FMT" "$NEW_A_H" "$NEW_A_M")" \
    "$(printf "$T_D_FMT" "$NEW_WEEKDAYS")")

whiptail --title "$T_TITLE" --yesno "$T_CONFIRM\n\n$SUMMARY" 12 42 \
    3>&1 1>&2 2>&3 || { echo "$T_CANCELLED"; exit 0; }

# ── Update config.sh ──────────────────────────────────────────────────────────
sed -i \
    -e "s/^MORNING_HOUR=.*/MORNING_HOUR=$NEW_M_H/" \
    -e "s/^MORNING_MINUTE=.*/MORNING_MINUTE=$NEW_M_M/" \
    -e "s/^AFTERNOON_HOUR=.*/AFTERNOON_HOUR=$NEW_A_H/" \
    -e "s/^AFTERNOON_MINUTE=.*/AFTERNOON_MINUTE=$NEW_A_M/" \
    -e "s|^WEEKDAYS=.*|WEEKDAYS=\"$NEW_WEEKDAYS\"|" \
    "$CONFIG_FILE"

# ── Update crontab ────────────────────────────────────────────────────────────
{
    crontab -l 2>/dev/null | grep -v "session-starter" | grep -v "# Claude session" || true
    echo ""
    echo "# Claude session - morning"
    echo "$NEW_M_M $NEW_M_H * * $NEW_WEEKDAYS $SESSION_FILE"
    echo "# Claude session - afternoon"
    echo "$NEW_A_M $NEW_A_H * * $NEW_WEEKDAYS $SESSION_FILE"
} | crontab -

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
printf '\033[1;32m%s\033[0m\n' "$T_DONE"
printf "  $T_M_FMT\n" "$NEW_M_H" "$NEW_M_M"
printf "  $T_A_FMT\n" "$NEW_A_H" "$NEW_A_M"
printf "  $T_D_FMT\n" "$NEW_WEEKDAYS"
echo ""
