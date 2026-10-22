#!/bin/bash
# The agents: what each one is called, its package, its log, and how to tell it is installed and logged in.

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

agent_log() { echo "$LOG_DIR/$1.log"; }

# Where an install from before kept an agent's log, next to the code; Claude and Codex had names of their own.
legacy_agent_log() {
    case "$1" in
        claude) echo "$KEEPALIVE_DIR/sessions.log" ;; codex) echo "$KEEPALIVE_DIR/codex-sessions.log" ;;
        *) echo "$KEEPALIVE_DIR/$1-sessions.log" ;;
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
