#!/bin/bash
# Everything the agent-keepalive scripts share, one file per topic. Source it after setting KEEPALIVE_DIR to the
# root of the install, the folder with keepalive in it:
#   KEEPALIVE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"   # a script at the root
#   source "$KEEPALIVE_DIR/lib/load.sh"
# The person's data lives outside the code, in STATE_DIR, so an update never has to step around it
# (docs/adr/0004-the-persons-data-lives-in-config.md).

# shellcheck disable=SC2034  # read by the files below and by the scripts that source this one
AGENTS_KNOWN="claude codex opencode"
STATE_DIR="$HOME/.config/agent-keepalive"
CONFIG_FILE="$STATE_DIR/config.sh"
LOG_DIR="$STATE_DIR/logs"
CLAUDE_TOKEN="$STATE_DIR/claude-token"
CLAUDE_ACCOUNT="$STATE_DIR/claude-account"  # the token carries no account details, so the login writes it here
SESSION_FILE="$KEEPALIVE_DIR/session-starter.sh"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# shellcheck source=lib/agents.sh
source "$KEEPALIVE_DIR/lib/agents.sh"
# shellcheck source=lib/settings.sh
source "$KEEPALIVE_DIR/lib/settings.sh"
# shellcheck source=lib/screens.sh
source "$KEEPALIVE_DIR/lib/screens.sh"
# shellcheck source=lib/schedule.sh
source "$KEEPALIVE_DIR/lib/schedule.sh"
# shellcheck source=lib/claude-token.sh
source "$KEEPALIVE_DIR/lib/claude-token.sh"
# shellcheck source=lib/updates.sh
source "$KEEPALIVE_DIR/lib/updates.sh"
