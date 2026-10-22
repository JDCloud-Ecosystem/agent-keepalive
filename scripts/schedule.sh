#!/bin/bash
# The schedule screen: the days, the three sessions and which agents get them. Each change is saved and the cron
# rewritten as soon as it is made. Run it as `keepalive schedule`.
set -uo pipefail

KEEPALIVE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=lib/load.sh
source "$KEEPALIVE_DIR/lib/load.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "No está config.sh. Corre primero install.sh."
    exit 1
fi

T_TITLE="HORARIO Y AGENTES"
T_L_DAYS="Días       "; T_L_MORNING="Mañana     "; T_L_AFTERNOON="Tarde      "; T_L_NIGHT="Noche      "
T_L_AGENTS="Agentes    "; T_L_NEXT="Próximo    "
T_OFF="desactivada"; T_NONE="ninguno, no hay días ni sesiones activas"
T_CHANGE="CAMBIAR"
T_M_DAYS="Los días"; T_M_MORNING="La sesión de la mañana"; T_M_AFTERNOON="La sesión de la tarde"
T_M_NIGHT="La sesión de la noche"; T_M_AGENTS="Los agentes que participan"
T_DAYS_TITLE="LOS DÍAS"
T_DAYS_HOW="Escribe los números de los días y pulsa Enter, como 1-5 para lunes a viernes, 1 3 5 o 1-7 para todos."
T_DAYS_ASK="Elige los días"; T_BAD_DAYS="Usa números del 1 al 7, sueltos o en rangos como 1-5."
T_SESSION_TITLE="LA SESIÓN DE LA %s"; T_MORNING="MAÑANA"; T_AFTERNOON="TARDE"; T_NIGHT="NOCHE"
T_SESSION_NOW="Ahora"; T_SESSION_HOW="Escribe la hora como 07:30 y pulsa Enter, o escribe no para desactivarla."
T_SESSION_ASK="Escribe la hora"; T_BAD_TIME="Usa la hora como 07:30, de 00:00 a 23:59, o escribe no."
T_LAST_SESSION="Es la única sesión activa. Deja otra activa antes de quitar esta."
T_AGENTS_TITLE="LOS AGENTES QUE PARTICIPAN"
T_AGENTS_HOW="Todos usan el mismo horario. Escribe los números de los que participan y pulsa Enter, como 1 o 1 2."
T_AGENTS_ASK="Elige los agentes"; T_IN="participa"; T_OUT="no participa"; T_MISSING="no instalado"
T_BAD_AGENTS="Usa los números de la lista, al menos uno."; T_NOT_INSTALLED="%s no está instalado."
T_SAVED="Guardado, y el cron quedó al día."

# The week as the person reads it, Monday first, against cron's numbers, where Sunday is 0.
WEEK_CRON=(1 2 3 4 5 6 0)
SESSIONS=(MORNING AFTERNOON NIGHT)
PAUSE=2  # seconds a warning stays before the screen is drawn again

_save() {  # key, value; the cron follows at once
    set_config "$1" "$2"
    sed -i '/^CODEX_ENABLED=/d' "$CONFIG_FILE"
    write_crontab
    FLASH="$T_SAVED"
}

_session_text() {  # MORNING, AFTERNOON or NIGHT
    local enabled="${1}_ENABLED" hour="${1}_HOUR" minute="${1}_MINUTE"
    if [[ "${!enabled}" == "true" ]]; then printf '%02d:%02d' "${!hour}" "${!minute}"; else echo "$T_OFF"; fi
}

_agents_text() {
    local names=() agent
    for agent in $AGENTS; do names+=("$(agent_title "$agent")"); done
    join_words "${names[@]}"
}

_week_line() {  # 1 lunes  2 martes ... 7 domingo
    local i line=""
    for i in 0 1 2 3 4 5 6; do line+="${C_GREEN}$(( i + 1 ))${C_RESET} ${U_DAYS[${WEEK_CRON[i]}]}  "; done
    printf '  %s\n' "$line"
}

# 1-5, "1 3 5" or "1,3,5" as cron's list of days; fails on anything else.
_parse_days() {
    local text="${1//,/ }" word first last d picked=()
    for word in $text; do
        if [[ "$word" =~ ^([1-7])-([1-7])$ ]]; then
            first=${BASH_REMATCH[1]} last=${BASH_REMATCH[2]}
            (( first <= last )) || return 1
            for (( d = first; d <= last; d++ )); do picked+=("${WEEK_CRON[d - 1]}"); done
        elif [[ "$word" =~ ^[1-7]$ ]]; then
            picked+=("${WEEK_CRON[word - 1]}")
        else
            return 1
        fi
    done
    (( ${#picked[@]} )) || return 1
    printf '%s\n' "${picked[@]}" | sort -nu | paste -sd, -
}

_change_days() {
    local days
    while true; do
        ui_clear
        ui_section "$T_DAYS_TITLE"
        printf '\n  %s%s\n\n' "$T_L_DAYS" "$(schedule_days)"
        _week_line
        printf '\n  %s\n\n' "$T_DAYS_HOW"
        ui_option 0 "$U_BACK"
        ui_choose "$T_DAYS_ASK" 7 many || return
        [[ "$ANSWER" == 0 ]] && return
        [[ -z "$ANSWER" ]] && continue
        if days=$(_parse_days "$ANSWER"); then
            _save WEEKDAYS "\"$days\""
            return
        fi
        ui_warn "$T_BAD_DAYS"
        sleep "$PAUSE"
    done
}

# A time like 07:30 starts with 0, so here 0 alone goes back only after Enter.
_change_session() {  # MORNING, AFTERNOON or NIGHT, and its title word
    local key="$1" enabled="${1}_ENABLED" others=0 s hour minute
    for s in "${SESSIONS[@]}"; do
        local flag="${s}_ENABLED"
        [[ "$s" != "$key" && "${!flag}" == "true" ]] && others=$(( others + 1 ))
    done
    while true; do
        ui_clear
        ui_section "$(printf "$T_SESSION_TITLE" "$2")"
        printf '\n  %s %s\n\n  %s\n\n' "$T_SESSION_NOW" "$(_session_text "$key")" "$T_SESSION_HOW"
        ui_option 0 "$U_BACK"
        ui_ask "$T_SESSION_ASK" || return
        [[ "$ANSWER" == 0 ]] && return
        [[ -z "$ANSWER" ]] && continue
        if [[ "${ANSWER,,}" =~ ^(no|off|desactivar)$ ]]; then
            if [[ "${!enabled}" == "true" ]] && (( others == 0 )); then
                ui_warn "$T_LAST_SESSION"; sleep "$PAUSE"; continue
            fi
            _save "${key}_ENABLED" false
            return
        fi
        if [[ "$ANSWER" =~ ^([0-9]{1,2})(:([0-9]{2}))?$ ]]; then
            hour=$(( 10#${BASH_REMATCH[1]} )) minute=$(( 10#${BASH_REMATCH[3]:-0} ))
            if (( hour <= 23 && minute <= 59 )); then
                set_config "${key}_HOUR" "$hour"
                set_config "${key}_MINUTE" "$minute"
                _save "${key}_ENABLED" true
                return
            fi
        fi
        ui_warn "$T_BAD_TIME"
        sleep "$PAUSE"
    done
}

_change_agents() {
    local list=() agent n state word picked=() missing=""
    for agent in $AGENTS_KNOWN; do list+=("$agent"); done
    while true; do
        ui_clear
        ui_section "$T_AGENTS_TITLE"
        echo ""
        n=0
        for agent in "${list[@]}"; do
            n=$(( n + 1 ))
            if ! agent_installed "$agent"; then state="${C_DIM}$T_MISSING${C_RESET}"
            elif [[ " $AGENTS " == *" $agent "* ]]; then state="${C_GREEN}$T_IN${C_RESET}"
            else state="$T_OUT"; fi
            ui_option "$n" "$(printf '%-12s  %s' "$(agent_title "$agent")" "$state")"
        done
        printf '\n  %s\n\n' "$T_AGENTS_HOW"
        ui_option 0 "$U_BACK"
        ui_choose "$T_AGENTS_ASK" "${#list[@]}" many || return
        [[ "$ANSWER" == 0 ]] && return
        [[ -z "$ANSWER" ]] && continue
        picked=() missing=""
        for word in ${ANSWER//,/ }; do
            if [[ "$word" =~ ^[0-9]+$ ]] && (( word >= 1 && word <= ${#list[@]} )); then
                agent="${list[word - 1]}"
                agent_installed "$agent" || missing="$agent"
                [[ " ${picked[*]} " == *" $agent "* ]] || picked+=("$agent")
            else
                picked=(); break
            fi
        done
        if [[ -n "$missing" ]]; then
            ui_warn "$(printf "$T_NOT_INSTALLED" "$(agent_title "$missing")")"; sleep "$PAUSE"; continue
        fi
        if (( ${#picked[@]} == 0 )); then
            ui_warn "$T_BAD_AGENTS"; sleep "$PAUSE"; continue
        fi
        _save AGENTS "\"${picked[*]}\""
        return
    done
}

_show() {
    local next
    next=$(next_run_text) || next="$T_NONE"
    printf '\n  %s%s\n' "$T_L_DAYS" "$(schedule_days)"
    printf '  %s%s\n  %s%s\n  %s%s\n' "$T_L_MORNING" "$(_session_text MORNING)" \
        "$T_L_AFTERNOON" "$(_session_text AFTERNOON)" "$T_L_NIGHT" "$(_session_text NIGHT)"
    printf '  %s%s\n  %s%s\n' "$T_L_AGENTS" "$(_agents_text)" "$T_L_NEXT" "$next"
}

FLASH=""
while true; do
    load_config
    if [[ ! -t 0 ]]; then
        ui_section "$T_TITLE"
        _show
        exit 0
    fi
    ui_clear
    ui_section "$T_TITLE"
    _show
    [[ -n "$FLASH" ]] && { echo ""; ui_ok "$FLASH"; FLASH=""; }
    ui_group "$T_CHANGE"
    ui_option 1 "$T_M_DAYS"
    ui_option 2 "$T_M_MORNING"
    ui_option 3 "$T_M_AFTERNOON"
    ui_option 4 "$T_M_NIGHT"
    ui_option 5 "$T_M_AGENTS"
    echo ""
    ui_option 0 "$U_BACK"
    ui_choose "$U_PICK" 5 || exit 0
    case "$ANSWER" in
        0) exit 0 ;;
        1) _change_days ;;
        2) _change_session MORNING "$T_MORNING" ;;
        3) _change_session AFTERNOON "$T_AFTERNOON" ;;
        4) _change_session NIGHT "$T_NIGHT" ;;
        5) _change_agents ;;
    esac
done
