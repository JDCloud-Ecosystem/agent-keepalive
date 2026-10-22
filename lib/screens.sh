#!/bin/bash
# ── Screens ───────────────────────────────────────────────────────────────────
# Every screen looks the same: its title in capitals between two rules, numbered options under small headings,
# lists as tables, and 0 to go back. An option nothing else starts with is taken as soon as its key is pressed,
# so up to nine options need no Enter. A program that opens the menu for someone, such as a login gateway, may
# set three variables: KEEPALIVE_HEADER (base64) is drawn above every screen, KEEPALIVE_NOTICE (base64) once
# above the first one, and KEEPALIVE_EXIT_LABEL names option 0 of the menu.
# shellcheck disable=SC2034  # BACK, the colours and the U_ words are for the scripts that source this file
BACK=10  # what a screen returns when the person picked 0, so the screen before it is drawn again with no pause
RULE="────────────────────────────────────────────────────────────────────────"
C_CYAN=$'\033[1;36m' C_YELLOW=$'\033[1;33m' C_GREEN=$'\033[1;32m' C_RED=$'\033[1;31m' C_DIM=$'\033[0;37m'
C_BOLD=$'\033[1;37m' C_RESET=$'\033[0m'

# shellcheck disable=SC2034  # for the scripts that source this file
U_BACK="Volver"
U_PICK="Elige una opción"; U_BACK_MENU="Volver al menú"
U_AT="a las"; U_AND="y"; U_OFF="sin sesiones activas"; U_EVERY_DAY="todos los días"; U_WEEKDAYS="de lunes a viernes"
U_DAYS=("domingo" "lunes" "martes" "miércoles" "jueves" "viernes" "sábado")
U_TODAY="hoy"; U_TOMORROW="mañana"; U_ON="el"; U_IN="en"; U_DAY="día"; U_DAYS_UNIT="días"
U_RUN_OK="salió bien"; U_RUN_LIMIT="la ventana ya estaba abierta"; U_RUN_ERROR="falló"
U_RUN_WEEKLY="la cuenta llegó a su límite semanal"; U_RUN_SILENT="no respondió en 3 minutos"
U_FIX="para arreglarlo corre"

ui_clear() {
    [[ -t 1 ]] && printf '\033[2J\033[H'
    [[ -n "${KEEPALIVE_HEADER:-}" ]] && printf '%s\n' "$(printf '%s' "$KEEPALIVE_HEADER" | base64 -d 2>/dev/null)"
    return 0
}

ui_section() {
    printf '\n  %s%s%s\n  %s%s%s\n  %s%s%s\n' "$C_CYAN" "$RULE" "$C_RESET" "$C_BOLD" "$1" "$C_RESET" \
        "$C_CYAN" "$RULE" "$C_RESET"
}

ui_group() { printf '\n  %s%s%s\n' "$C_DIM" "$1" "$C_RESET"; }
ui_option() { printf '  %s%s%s  %s\n' "$C_GREEN" "$1" "$C_RESET" "$2"; }
ui_ok() { printf '  %s✓ %s%s\n' "$C_GREEN" "$1" "$C_RESET"; }
ui_fail() { printf '  %s✗ %s%s\n' "$C_RED" "$1" "$C_RESET"; }
ui_warn() { printf '  %s%s%s\n' "$C_YELLOW" "$1" "$C_RESET"; }
ui_note() { printf '  %s%s%s\n' "$C_DIM" "$1" "$C_RESET"; }

_ui_drain() {  # keys pressed before a question appeared never answer it
    local _
    while IFS= read -rsn1 -t 0.01 _; do :; done 2>/dev/null
    return 0
}

_ui_trim() {
    ANSWER="${ANSWER#"${ANSWER%%[![:space:]]*}"}"
    ANSWER="${ANSWER%"${ANSWER##*[![:space:]]}"}"
}

ui_ask() {  # prompt, for an answer ended with Enter; it goes to ANSWER, trimmed. Fails when the input has ended.
    [[ -t 0 ]] && _ui_drain
    printf '\n  %s ' "$1"
    IFS= read -r ANSWER || { ANSWER=""; echo ""; return 1; }
    _ui_trim
}

# Whether typed is a number from 0 to max, and whether it is already whole: no other number up to max starts
# with it, as 1 is with 12 options and 3 is with 8.
_ui_fits() { [[ "$1" =~ ^(0|[1-9][0-9]{0,2})$ ]] && (( 10#$1 <= $2 )); }
_ui_whole() { _ui_fits "$1" "$2" && { [[ "$1" == 0 ]] || (( 10#$1 * 10 > $2 )); }; }

# An option from 0 to max, read key by key; the answer goes to ANSWER. A whole number is taken at once, with no
# Enter. With "text" a name can be typed too, ended with Enter; with "many", a list or range such as 1-5 or 1 3,
# so only 0 is taken alone. Without a terminal it reads a line. Fails when the input has ended.
ui_choose() {  # prompt, max, [text|many]
    local max="$2" mode="${3:-}" key typed=""
    [[ -t 0 ]] || { ui_ask "$1"; return; }
    _ui_drain
    printf '\n  %s ' "$1"
    while IFS= read -rsn1 key; do
        case "$key" in
            "") break ;;
            $'\x04') [[ -z "$typed" ]] && { echo ""; ANSWER=""; return 1; }; continue ;;
            $'\x7f'|$'\b') [[ -n "$typed" ]] && { typed="${typed%?}"; printf '\b \b'; }; continue ;;
            $'\x1b') read -rsn2 -t 0.01 _ 2>/dev/null; continue ;;
        esac
        [[ "$key" == [[:cntrl:]] ]] && continue
        if [[ -z "$mode" ]] && ! _ui_fits "$typed$key" "$max"; then continue; fi
        typed+="$key"
        printf '%s' "$key"
        if [[ "$mode" == many ]]; then
            [[ "$typed" == 0 ]] && break
        elif _ui_whole "$typed" "$max"; then
            break
        fi
    done
    echo ""
    ANSWER="$typed"
    _ui_trim
}

ui_yes() {  # question, then whether Enter alone counts as yes; s or n is taken as soon as it is pressed
    local key
    if [[ ! -t 0 ]]; then
        printf '\n  %s (s o n) ' "$1"
        IFS= read -r key || key=""
        [[ -z "$key" ]] && { [[ "$2" == true ]]; return; }
        [[ "${key,,}" =~ ^(s|si|sí)$ ]]
        return
    fi
    _ui_drain
    printf '\n  %s (s o n) ' "$1"
    while IFS= read -rsn1 key; do
        case "${key,,}" in
            s) echo "s"; return 0 ;;
            n) echo "n"; return 1 ;;
            "") echo ""; [[ "$2" == true ]]; return ;;
        esac
    done
    echo ""
    return 1
}

ui_pause() {
    printf '\n  %s%s%s\n' "$C_CYAN" "$RULE" "$C_RESET"
    ui_option 0 "$U_BACK_MENU"
    ui_choose "$U_PICK" 0 || true
}

# What a cell looks like without its colour, in PLAIN, so colour never counts toward a column's width.
_ui_plain() {
    local code
    PLAIN="$1"
    for code in "$C_CYAN" "$C_YELLOW" "$C_GREEN" "$C_RED" "$C_DIM" "$C_BOLD" "$C_RESET"; do PLAIN="${PLAIN//"$code"/}"; done
}

# A table drawn with box lines, each column as wide as its widest cell. The rows come on standard input, the
# first one the headers, cells split by the unit separator $'\x1f'; a row that is only -- draws a line between
# groups of rows. A cell may carry colour.
ui_table() {
    local LC_ALL=C.UTF-8 rows=() widths=() cells=() row cell i j line pad bar
    mapfile -t rows
    (( ${#rows[@]} )) || return 0
    for row in "${rows[@]}"; do
        [[ "$row" == "--" ]] && continue
        IFS=$'\x1f' read -ra cells <<< "$row"
        for i in "${!cells[@]}"; do
            _ui_plain "${cells[i]}"
            (( ${#PLAIN} > ${widths[i]:-0} )) && widths[i]=${#PLAIN}
        done
    done
    local top="┌" middle="├" bottom="└"
    for (( j = 0; j < ${#widths[@]}; j++ )); do
        printf -v bar '%*s' $(( ${widths[j]:-0} + 2 )) ''
        bar="${bar// /─}"
        if (( j > 0 )); then top+="┬"; middle+="┼"; bottom+="┴"; fi
        top+="$bar" middle+="$bar" bottom+="$bar"
    done
    printf '  %s┐\n' "$top"
    for i in "${!rows[@]}"; do
        row="${rows[i]}"
        if [[ "$row" == "--" ]]; then printf '  %s┤\n' "$middle"; continue; fi
        IFS=$'\x1f' read -ra cells <<< "$row"
        line="  │"
        for (( j = 0; j < ${#widths[@]}; j++ )); do
            cell="${cells[j]:-}"
            _ui_plain "$cell"
            pad=$(( ${widths[j]:-0} - ${#PLAIN} ))
            (( i == 0 )) && cell="$C_BOLD$cell$C_RESET"
            printf -v bar '%*s' "$pad" ''
            line+=" $cell$bar │"
        done
        printf '%s\n' "$line"
        (( i == 0 )) && printf '  %s┤\n' "$middle"
    done
    printf '  %s┘\n' "$bottom"
}

# One line of an agent's log as "result|dd/mm HH:MM|what happened", result being ok, limit, weekly or error.
describe_run() {
    local when fix
    when=$(echo "$1" | sed -E 's/^\[[0-9]{4}-([0-9]{2})-([0-9]{2}) ([0-9]{2}:[0-9]{2}).*/\2\/\1 \3/')
    case "$1" in
        *"] OK"*) echo "ok|$when|$U_RUN_OK" ;;
        *"] LIMIT (weekly"*) echo "weekly|$when|$U_RUN_WEEKLY" ;;
        *"] LIMIT"*) echo "limit|$when|$U_RUN_LIMIT" ;;
        *"did not answer"*) echo "error|$when|$U_RUN_SILENT" ;;
        *)
            fix=$(echo "$1" | sed -nE 's/.*run: ([^|]*).*/\1/p' | sed 's/ *$//')
            echo "error|$when|$U_RUN_ERROR${fix:+, $U_FIX $fix}" ;;
    esac
}
