#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

MAX_LINES="${MAX_LOG_LINES:-200}"
TS=$(date '+%Y-%m-%d %H:%M:%S')

SESSION_TYPE="${1:-morning}"
TOOL="${2:-claude}"

case "$SESSION_TYPE" in
    morning)   SESSION_LABEL="MORNING"   ;;
    afternoon) SESSION_LABEL="AFTERNOON" ;;
    night)     SESSION_LABEL="NIGHT"     ;;
    *)         SESSION_LABEL="SESSION"   ;;
esac

case "$TOOL" in
    codex)
        LOG_FILE="$SCRIPT_DIR/codex-sessions.log"
        TOOL_CMD=$(command -v codex 2>/dev/null || echo "")
        ;;
    *)
        LOG_FILE="$SCRIPT_DIR/sessions.log"
        TOOL_CMD=$(command -v claude 2>/dev/null || echo "")
        ;;
esac

_rotate() {
    [[ ! -f "$LOG_FILE" ]] && return
    local lines
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if (( lines >= MAX_LINES )); then
        tail -n 50 "$LOG_FILE" > "${LOG_FILE}.tmp" \
            && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

_log() { printf "[%s] [%s] %s\n" "$TS" "$SESSION_LABEL" "$1" >> "$LOG_FILE"; }

_rotate

if [[ -z "$TOOL_CMD" ]]; then
    _log "ERROR: $TOOL not found — run install.sh"
    exit 1
fi

_log "Starting session reset"

if [[ "$TOOL" == "codex" ]]; then
    # Codex CLI (@openai/codex) accepts a task as a positional argument
    RESP=$("$TOOL_CMD" "New session initialized. Context cleared. Ready." 2>&1) || true
else
    RESP=$("$TOOL_CMD" -p "New session initialized. Context cleared. Ready." 2>&1) || true
fi
_log "Reset: ${RESP:0:120}"

sleep 2

if [[ "$TOOL" == "codex" ]]; then
    RESP=$("$TOOL_CMD" "Session active. Beginning work period." 2>&1) || true
else
    RESP=$("$TOOL_CMD" -p "Session active. Beginning work period." 2>&1) || true
fi
_log "Work:  ${RESP:0:120}"

_log "Session complete"
echo "---" >> "$LOG_FILE"
