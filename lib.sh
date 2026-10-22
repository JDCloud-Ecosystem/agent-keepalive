#!/bin/bash
# Shared by every agent-keepalive script: which agents exist, how each one runs without a terminal, how to tell
# whether it is logged in, how the crontab is written and how a screen looks. Source it after setting SCRIPT_DIR.

AGENTS_KNOWN="claude codex opencode"
STATE_DIR="$HOME/.config/agent-keepalive"
CLAUDE_TOKEN="$STATE_DIR/claude-token"
CLAUDE_ACCOUNT="$STATE_DIR/claude-account"  # the token carries no account details, so login.sh writes it here
SESSION_FILE="$SCRIPT_DIR/session-starter.sh"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

agent_title() {
    case "$1" in
        claude) echo "Claude Code" ;; codex) echo "Codex" ;; opencode) echo "OpenCode" ;; *) echo "$1" ;;
    esac
}

agent_package() {
    case "$1" in
        claude) echo "@anthropic-ai/claude-code" ;; codex) echo "@openai/codex" ;; opencode) echo "opencode-ai" ;;
    esac
}

# Claude and Codex keep their historical log names, so existing histories carry on.
agent_log() {
    case "$1" in
        claude) echo "$SCRIPT_DIR/sessions.log" ;; codex) echo "$SCRIPT_DIR/codex-sessions.log" ;;
        *) echo "$SCRIPT_DIR/$1-sessions.log" ;;
    esac
}

agent_installed() { command -v "$1" >/dev/null 2>&1; }

agent_logged_in() {
    case "$1" in
        claude)   [[ -s "$CLAUDE_TOKEN" || -s "$HOME/.claude/.credentials.json" ]] ;;
        codex)    [[ -s "${CODEX_HOME:-$HOME/.codex}/auth.json" ]] ;;
        opencode) [[ -s "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json" ]] ;;
        *) return 1 ;;
    esac
}

agent_login_command() {
    case "$1" in
        claude) echo "keepalive login claude" ;; codex) echo "codex login --device-auth" ;;
        opencode) echo "opencode auth login" ;;
    esac
}

load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    MORNING_HOUR="${MORNING_HOUR:-7}"
    MORNING_MINUTE="${MORNING_MINUTE:-0}"
    AFTERNOON_HOUR="${AFTERNOON_HOUR:-12}"
    AFTERNOON_MINUTE="${AFTERNOON_MINUTE:-0}"
    MORNING_ENABLED="${MORNING_ENABLED:-true}"
    AFTERNOON_ENABLED="${AFTERNOON_ENABLED:-true}"
    NIGHT_ENABLED="${NIGHT_ENABLED:-false}"
    NIGHT_HOUR="${NIGHT_HOUR:-17}"
    NIGHT_MINUTE="${NIGHT_MINUTE:-0}"
    WEEKDAYS="${WEEKDAYS:-1,2,3,4,5}"
    # Older configs only knew CODEX_ENABLED; they keep meaning the same thing.
    if [[ -z "${AGENTS:-}" ]]; then
        AGENTS="claude"
        [[ "${CODEX_ENABLED:-false}" == "true" ]] && AGENTS="claude codex"
    fi
    # Only agents with a usage window belong here; one a config still names from before is dropped.
    local agent kept=""
    for agent in $AGENTS; do [[ " $AGENTS_KNOWN " == *" $agent "* ]] && kept="$kept $agent"; done
    AGENTS="${kept# }"
    [[ -n "$AGENTS" ]] || AGENTS="claude"
}

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

# ── The schedule in words ─────────────────────────────────────────────────────
join_words() {  # a, b and c
    local out="" i
    for (( i = 1; i <= $#; i++ )); do
        if (( i == 1 )); then out="${!i}"; elif (( i == $# )); then out="$out $U_AND ${!i}"; else out="$out, ${!i}"; fi
    done
    echo "$out"
}

schedule_slots() {  # every enabled sending time as HH:MM, earliest first
    {
        [[ "$MORNING_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$MORNING_HOUR" "$MORNING_MINUTE"
        [[ "$AFTERNOON_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$AFTERNOON_HOUR" "$AFTERNOON_MINUTE"
        [[ "$NIGHT_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$NIGHT_HOUR" "$NIGHT_MINUTE"
    } | sort
}

schedule_days() {  # the days of WEEKDAYS in words, Monday first
    local picked=() names=() d
    IFS=',' read -ra picked <<< "$WEEKDAYS"
    case "$(printf '%s\n' "${picked[@]}" | sort -n | tr '\n' ',')" in
        "0,1,2,3,4,5,6,") echo "$U_EVERY_DAY" ;;
        "1,2,3,4,5,") echo "$U_WEEKDAYS" ;;
        *) for d in 1 2 3 4 5 6 0; do [[ ",$WEEKDAYS," == *",$d,"* ]] && names+=("${U_DAYS[$d]}"); done
           join_words "${names[@]}" ;;
    esac
}

schedule_text() {  # "a las 07:00 y 12:00, de lunes a viernes"
    local slots=()
    mapfile -t slots < <(schedule_slots)
    (( ${#slots[@]} )) || { echo "$U_OFF"; return; }
    echo "$U_AT $(join_words "${slots[@]}"), $(schedule_days)"
}

# When the cron sends next, as "hoy a las 12:00, en 1 h 20 min"; fails when no day or session is enabled.
next_run_text() {
    local slots=() now best="" offset day dow slot epoch minutes when wait
    mapfile -t slots < <(schedule_slots)
    (( ${#slots[@]} )) || return 1
    now=$(date +%s)
    for (( offset = 0; offset <= 7; offset++ )); do
        day=$(date -d "today +$offset day" +%F)
        dow=$(date -d "$day" +%w)
        [[ ",$WEEKDAYS," == *",$dow,"* ]] || continue
        for slot in "${slots[@]}"; do
            epoch=$(date -d "$day $slot" +%s)
            (( epoch > now )) && { best=$epoch; break 2; }
        done
    done
    [[ -n "$best" ]] || return 1
    case "$offset" in
        0) when="$U_TODAY" ;; 1) when="$U_TOMORROW" ;; *) when="$U_ON ${U_DAYS[$dow]}" ;;
    esac
    minutes=$(( (best - now + 59) / 60 ))
    if (( minutes < 60 )); then
        wait="$minutes min"
    elif (( minutes < 1440 )); then
        wait="$(( minutes / 60 )) h"
        (( minutes % 60 )) && wait="$wait $(( minutes % 60 )) min"
    else
        wait="$(( minutes / 1440 )) $( (( minutes / 1440 == 1 )) && echo "$U_DAY" || echo "$U_DAYS_UNIT")"
        (( minutes % 1440 / 60 )) && wait="$wait $U_AND $(( minutes % 1440 / 60 )) h"
    fi
    echo "$when $U_AT $slot, $U_IN $wait"
}

set_config() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

# Rewrites this user's crontab: every enabled session, for every agent in AGENTS. Lines of other tools stay.
write_crontab() {
    load_config
    {
        crontab -l 2>/dev/null | grep -v "session-starter" | grep -vE "^# (Claude|Codex|Agent) session" | grep -v "^$" || true
        crontab -l 2>/dev/null | grep -q "^PATH=" || echo "PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin"
        local agent
        for agent in $AGENTS; do
            [[ "$MORNING_ENABLED" == "true" ]] && printf '# Agent session - %s morning\n%s %s * * %s %s morning %s\n' \
                "$agent" "$MORNING_MINUTE" "$MORNING_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
            [[ "$AFTERNOON_ENABLED" == "true" ]] && printf '# Agent session - %s afternoon\n%s %s * * %s %s afternoon %s\n' \
                "$agent" "$AFTERNOON_MINUTE" "$AFTERNOON_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
            [[ "$NIGHT_ENABLED" == "true" ]] && printf '# Agent session - %s night\n%s %s * * %s %s night %s\n' \
                "$agent" "$NIGHT_MINUTE" "$NIGHT_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
        done
        true
    } | crontab -
}

# Claude prints its year token through a UI that breaks it into lines as wide as the terminal, about 108
# characters split over two lines in most windows, and a copy from the screen keeps those breaks. Both read
# it back whole: the line where it starts plus each following line made only of token characters.
token_from_screen() {  # a captured terminal session on stdin
    if command -v python3 >/dev/null 2>&1; then
        screen_text
    else
        sed 's/\x1b\][^\x07]*\x07//g; s/\x1b\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
    fi | awk '
        open && /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*$/ { gsub(/[[:space:]]/, ""); token = token $0; next }
        { open = 0 }
        match($0, /sk-ant-oat01-[A-Za-z0-9_-]+/) { token = substr($0, RSTART, RLENGTH); open = 1 }
        END { if (token != "") print token }'
}

# Claude does not write its screens out in full: it jumps the cursor over spaces and over any cell that
# already shows the right character, so the bytes it sends lack letters the screen has. This plays them on
# a blank screen, like a terminal would, and prints the lines it ends with.
_SCREEN_PY='
import re, sys
data = sys.stdin.buffer.read().decode("utf-8", "replace")
rows, r, c, saved = {}, 0, 0, (0, 0)
parts = re.compile(r"\x1b\[([0-9;?>=<]*)[ -/]*([@-~])|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)?|\x1b[^\[\]]|[\r\n\b]|[^\x1b\r\n\b]+")
def line():
    return rows.setdefault(r, [])
for m in parts.finditer(data):
    s = m.group(0)
    if s == "\r":
        c = 0
    elif s == "\n":
        r += 1
    elif s == "\b":
        c = max(0, c - 1)
    elif s.startswith("\x1b["):
        args, cmd = m.group(1), m.group(2)
        if args and args[0] in "?>=<":
            continue
        n = [int(x) if x.isdigit() else 0 for x in args.split(";")] if args else []
        k = n[0] if n and n[0] else 1
        if cmd == "G":
            c = k - 1
        elif cmd == "C":
            c += k
        elif cmd == "D":
            c = max(0, c - k)
        elif cmd == "A":
            r = max(0, r - k)
        elif cmd == "B":
            r += k
        elif cmd == "E":
            r, c = r + k, 0
        elif cmd == "F":
            r, c = max(0, r - k), 0
        elif cmd in "Hf":
            r, c = k - 1, (n[1] if len(n) > 1 and n[1] else 1) - 1
        elif cmd == "K":
            mode, cells = (n[0] if n else 0), line()
            if mode == 0:
                del cells[c:]
            elif mode == 1:
                cells[:c + 1] = [" "] * min(len(cells), c + 1)
            else:
                rows[r] = []
        elif cmd == "J":
            mode = n[0] if n else 0
            if mode == 0:
                del line()[c:]
                rows = {row: cells for row, cells in rows.items() if row <= r}
            elif mode == 1:
                rows = {row: cells for row, cells in rows.items() if row >= r}
            else:
                rows = {}
        elif cmd == "P":
            del line()[c:c + k]
        elif cmd == "X":
            cells = line()
            cells[c:c + k] = [" "] * len(cells[c:c + k])
    elif s == "\x1b7":
        saved = (r, c)
    elif s == "\x1b8":
        r, c = saved
    elif s == "\x1bM":
        r = max(0, r - 1)
    elif s == "\x1bD":
        r += 1
    elif s == "\x1bE":
        r, c = r + 1, 0
    elif not s.startswith("\x1b"):
        cells = line()
        if len(cells) < c:
            cells.extend(" " * (c - len(cells)))
        cells[c:c + len(s)] = list(s)
        c += len(s)
for row in range(max(rows) + 1 if rows else 0):
    print("".join(rows.get(row, [])).rstrip())
'
screen_text() { python3 -c "$_SCREEN_PY"; }

read_token() {  # what the person pastes, without echo; the lines of one paste arrive together
    local line all="" rest
    { printf '\033[?2004l' >/dev/tty; } 2>/dev/null  # no bracketed-paste marks around what comes next
    IFS= read -rs line || return 1
    all="$line"
    while IFS= read -rs -t 1 line; do all+="$line"; done
    if [[ -n "$line" ]]; then  # the last piece came without its Enter yet; take it, then wait for the Enter
        all+="$line"
        IFS= read -rs rest && all+="$rest"
    fi
    printf '%s\n' "$all" | sed 's/\x1b\[20[01]~//g' | tr -d '[:space:]' | grep -oE 'sk-ant-oat01-[A-Za-z0-9_-]+' | head -1
}

# The year-long Claude token lives outside the repository, so moving or renaming the folder never loses it.
# Installs before 2026-10 kept it next to the scripts; it moves here the first time any script runs.
migrate_token() {
    if [[ -s "$SCRIPT_DIR/.claude-token" && ! -s "$CLAUDE_TOKEN" ]]; then
        mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
        mv "$SCRIPT_DIR/.claude-token" "$CLAUDE_TOKEN"
        [[ -f "$SCRIPT_DIR/.claude-token.created" ]] && mv "$SCRIPT_DIR/.claude-token.created" "$CLAUDE_TOKEN.created"
    fi
    # Every terminal of this user uses the token, so the interactive login cannot break either.
    if [[ -s "$CLAUDE_TOKEN" ]] && ! grep -qF "$CLAUDE_TOKEN" "$HOME/.bashrc" 2>/dev/null; then
        sed -i '/# >>> claude-keepalive token >>>/,/# <<< claude-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/# >>> agent-keepalive token >>>/,/# <<< agent-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null
        printf '\n# >>> agent-keepalive token >>>\n[ -s "%s" ] && export CLAUDE_CODE_OAUTH_TOKEN="$(cat "%s")"\n# <<< agent-keepalive token <<<\n' \
            "$CLAUDE_TOKEN" "$CLAUDE_TOKEN" >> "$HOME/.bashrc"
    fi
}

# An address made of plain ASCII, as Claude accounts are; anything with a broken or foreign byte fails.
valid_email() {
    local LC_ALL=C
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$ ]]
}

# ── Updates ───────────────────────────────────────────────────────────────────
# Every install follows main (docs/adr/0002-every-install-follows-main.md). Looking for a new version is a git
# fetch of main, at most once every UPDATE_EVERY seconds, started by each send and by the menu. What it brings in
# stays in origin/main, so telling whether there is a newer version, and what it changes, needs no network.
UPDATE_EVERY=72000  # 20 hours, so there is one check a day even when the sends move a little
FETCH_SECONDS=60    # a fetch that takes longer is given up, so a machine with no network never waits on it
VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

installed_version() {
    local version
    version=$(tr -d '[:space:]' < "$SCRIPT_DIR/version.txt" 2>/dev/null)
    [[ "$version" =~ $VERSION_RE ]] && echo "$version"
}

latest_version() {  # the version on main as of the last check
    local version
    version=$(git -C "$SCRIPT_DIR" show origin/main:version.txt 2>/dev/null | tr -d '[:space:]')
    [[ "$version" =~ $VERSION_RE ]] && echo "$version"
}

version_newer() {  # a b: whether version a comes after b; an empty b, an install with no number, comes before all
    [[ "$1" =~ $VERSION_RE ]] || return 1
    [[ -z "$2" ]] && return 0
    [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" == "$1" ]]
}

newer_version() {  # the version on main, when it is newer than the installed one
    local latest
    latest=$(latest_version) && version_newer "$latest" "$(installed_version)" && echo "$latest"
}

_seconds_since_check() {
    local head
    head=$(git -C "$SCRIPT_DIR" rev-parse --git-path FETCH_HEAD 2>/dev/null) || { echo "$UPDATE_EVERY"; return; }
    [[ "$head" == /* ]] || head="$SCRIPT_DIR/$head"
    [[ -f "$head" ]] || { echo "$UPDATE_EVERY"; return; }
    echo $(( $(date +%s) - $(stat -c %Y "$head") ))
}

# Fetches main. With --if-stale it does nothing when the last check is recent, and leaves it to a check already
# running, so two sends in the same minute fetch once. Never asks for a password or a host key.
check_update() {  # [--if-stale]
    local wait=(-w "$FETCH_SECONDS")
    if [[ "${1:-}" == --if-stale ]]; then
        (( $(_seconds_since_check) < UPDATE_EVERY )) && return 0
        wait=(-n)
    fi
    mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
    (
        if command -v flock >/dev/null 2>&1; then flock "${wait[@]}" 9 || exit 0; fi
        GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" \
            timeout "$FETCH_SECONDS" git -C "$SCRIPT_DIR" fetch -q origin main
    ) 9>"$STATE_DIR/update.lock"
}
