#!/bin/bash
# Shared by every agent-keepalive script: which agents exist, how each one runs without a terminal, how to tell
# whether it is logged in, and how the crontab is written. Source it after setting SCRIPT_DIR.

AGENTS_KNOWN="claude codex opencode"
STATE_DIR="$HOME/.config/agent-keepalive"
CLAUDE_TOKEN="$STATE_DIR/claude-token"
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
