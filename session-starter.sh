#!/bin/bash
# Sends one short message to an AI agent so its usage window starts now. Cron runs it.
#   session-starter.sh <morning|afternoon|night> [claude|codex|opencode|gemini|qwen]
# Each agent runs in its own non-interactive mode. Claude uses the year-long token from `keepalive login claude`
# when there is one, so the cron never renews (and never breaks) a login. Every run ends in the agent's log as
# OK, LIMIT (a window was already open) or an ERROR that says what to run.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config
migrate_token

MAX_LINES="${MAX_LOG_LINES:-200}"
TS=$(date '+%Y-%m-%d %H:%M:%S')
SESSION_TYPE="${1:-morning}"
AGENT="${2:-claude}"
PROMPT="Keepalive check. Reply with the single word OK."
LOG_FILE="$(agent_log "$AGENT")"

case "$SESSION_TYPE" in
    morning) SESSION_LABEL="MORNING" ;; afternoon) SESSION_LABEL="AFTERNOON" ;;
    night) SESSION_LABEL="NIGHT" ;; *) SESSION_LABEL="SESSION" ;;
esac

if [[ -f "$LOG_FILE" ]] && (( $(wc -l < "$LOG_FILE") >= MAX_LINES )); then
    tail -n 50 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

_finish() {
    printf "[%s] [%s] %s\n---\n" "$TS" "$SESSION_LABEL" "$1" >> "$LOG_FILE"
    exit "$2"
}

[[ " $AGENTS_KNOWN " == *" $AGENT "* ]] || _finish "ERROR: unknown agent $AGENT" 1
agent_installed "$AGENT" || _finish "ERROR: $(agent_title "$AGENT") is not installed — run: sudo npm install -g $(agent_package "$AGENT")" 1
agent_logged_in "$AGENT" || _finish "ERROR: $(agent_title "$AGENT") is not logged in — run: $(agent_login_command "$AGENT")" 1

LAST=$(mktemp)
trap 'rm -f "$LAST"' EXIT
[[ -s "$CLAUDE_TOKEN" ]] && export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$CLAUDE_TOKEN")"
case "$AGENT" in
    claude)   COMMAND=(claude -p "$PROMPT") ;;
    codex)    COMMAND=(codex exec --skip-git-repo-check -s read-only --color never -o "$LAST" "$PROMPT") ;;
    opencode) COMMAND=(opencode run "$PROMPT") ;;
    gemini)   COMMAND=(gemini -p "$PROMPT") ;;
    qwen)     COMMAND=(qwen -p "$PROMPT") ;;
esac
RESP=$(cd "$HOME" && timeout 180 "${COMMAND[@]}" </dev/null 2>&1)
CODE=$?
[[ -s "$LAST" ]] && RESP=$(cat "$LAST")

ONE_LINE=$(printf '%s' "$RESP" | tr '\n' ' ' | sed 's/  */ /g')
if printf '%s' "$RESP" | grep -qiE 'failed to authenticate|oauth|401|unauthorized|not logged in|please (run|log)|invalid api key|re-?authenticate'; then
    _finish "ERROR: $(agent_title "$AGENT") login expired — run: $(agent_login_command "$AGENT") | ${ONE_LINE:0:100}" 1
fi
# A limit means a usage window is already running, which is what this script is for.
printf '%s' "$RESP" | grep -qiE 'session limit|usage limit|rate limit|quota' \
    && _finish "LIMIT (window already active): ${ONE_LINE:0:110}" 0
(( CODE == 124 )) && _finish "ERROR: $(agent_title "$AGENT") did not answer within 3 minutes" 1
(( CODE != 0 )) && _finish "ERROR ($CODE): ${ONE_LINE:0:140}" 1
_finish "OK: ${ONE_LINE:0:120}" 0
