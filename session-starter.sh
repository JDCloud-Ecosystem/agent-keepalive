#!/bin/bash
# Sends one short message to Claude Code or Codex so the 5-hour usage window starts now.
#   session-starter.sh <morning|afternoon|night> [claude|codex]
# Claude uses the year-long token from login.sh when there is one, so the cron never renews (and never breaks)
# the interactive login. Codex runs headless with `codex exec`. Every run ends in the log as OK or ERROR.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
TOKEN_FILE="$SCRIPT_DIR/.claude-token"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

MAX_LINES="${MAX_LOG_LINES:-200}"
TS=$(date '+%Y-%m-%d %H:%M:%S')
SESSION_TYPE="${1:-morning}"
TOOL="${2:-claude}"
PROMPT="Keepalive check. Reply with the single word OK."

case "$SESSION_TYPE" in
    morning)   SESSION_LABEL="MORNING"   ;;
    afternoon) SESSION_LABEL="AFTERNOON" ;;
    night)     SESSION_LABEL="NIGHT"     ;;
    *)         SESSION_LABEL="SESSION"   ;;
esac

case "$TOOL" in
    codex) LOG_FILE="$SCRIPT_DIR/codex-sessions.log"; TOOL_CMD=$(command -v codex 2>/dev/null || echo "") ;;
    *)     LOG_FILE="$SCRIPT_DIR/sessions.log";       TOOL_CMD=$(command -v claude 2>/dev/null || echo "") ;;
esac

_rotate() {
    [[ ! -f "$LOG_FILE" ]] && return
    local lines
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if (( lines >= MAX_LINES )); then
        tail -n 50 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

_log() { printf "[%s] [%s] %s\n" "$TS" "$SESSION_LABEL" "$1" >> "$LOG_FILE"; }

_finish() {
    _log "$1"
    echo "---" >> "$LOG_FILE"
    exit "$2"
}

_rotate

[[ -z "$TOOL_CMD" ]] && _finish "ERROR: $TOOL not found — run install.sh" 1

if [[ "$TOOL" == "codex" ]]; then
    [[ -s "${CODEX_HOME:-$HOME/.codex}/auth.json" ]] \
        || _finish "ERROR: Codex is not logged in — run: codex login --device-auth" 1
    LAST=$(mktemp)
    RESP=$(cd "$HOME" && timeout 180 "$TOOL_CMD" exec --skip-git-repo-check -s read-only --color never \
        -o "$LAST" "$PROMPT" </dev/null 2>&1)
    CODE=$?
    [[ -s "$LAST" ]] && RESP=$(cat "$LAST")
    rm -f "$LAST"
else
    [[ -s "$TOKEN_FILE" ]] && export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$TOKEN_FILE")"
    RESP=$(cd "$HOME" && timeout 180 "$TOOL_CMD" -p "$PROMPT" </dev/null 2>&1)
    CODE=$?
fi

ONE_LINE=$(printf '%s' "$RESP" | tr '\n' ' ' | sed 's/  */ /g')
if printf '%s' "$RESP" | grep -qiE 'failed to authenticate|oauth|401|unauthorized|not logged in|please run .*login|invalid api key'; then
    if [[ "$TOOL" == "codex" ]]; then
        _finish "ERROR: Codex login expired — run: codex login --device-auth | ${ONE_LINE:0:100}" 1
    fi
    _finish "ERROR: Claude login expired — run: ~/projects/claude-keepalive/login.sh | ${ONE_LINE:0:100}" 1
fi
# A limit means a usage window is already running, which is what this script is for.
printf '%s' "$RESP" | grep -qiE 'session limit|usage limit|rate limit' && _finish "LIMIT (window already active): ${ONE_LINE:0:110}" 0
(( CODE == 124 )) && _finish "ERROR: $TOOL did not answer within 3 minutes" 1
(( CODE != 0 )) && _finish "ERROR ($CODE): ${ONE_LINE:0:140}" 1
_finish "OK: ${ONE_LINE:0:120}" 0
