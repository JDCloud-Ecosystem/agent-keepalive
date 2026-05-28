#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LOG_FILE="$SCRIPT_DIR/sessions.log"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

MAX_LINES="${MAX_LOG_LINES:-200}"
TS=$(date '+%Y-%m-%d %H:%M:%S')

_rotate() {
    [[ ! -f "$LOG_FILE" ]] && return
    local lines
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if (( lines >= MAX_LINES )); then
        tail -n 50 "$LOG_FILE" > "${LOG_FILE}.tmp" \
            && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

_log() { printf "[%s] %s\n" "$TS" "$1" >> "$LOG_FILE"; }

_rotate

CLAUDE_CMD=$(command -v claude 2>/dev/null || echo "")
if [[ -z "$CLAUDE_CMD" ]]; then
    _log "ERROR: claude not found — run install.sh"
    exit 1
fi

_log "Starting session reset"

RESP=$("$CLAUDE_CMD" -p "New session initialized. Context cleared. Ready." 2>&1) || true
_log "Reset: ${RESP:0:120}"

sleep 2

RESP=$("$CLAUDE_CMD" -p "Session active. Beginning work period." 2>&1) || true
_log "Work:  ${RESP:0:120}"

_log "Session complete"
echo "---" >> "$LOG_FILE"
