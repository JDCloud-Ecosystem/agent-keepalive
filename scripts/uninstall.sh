#!/bin/bash
set -uo pipefail

KEEPALIVE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=lib/load.sh
source "$KEEPALIVE_DIR/lib/load.sh"
load_config

# ── String tables ─────────────────────────────────────────────────────────────
T_TITLE="DESINSTALAR AGENT-KEEPALIVE"
T_WHAT="Se quita todo esto: las entradas del crontab, config.sh, los historiales, el token de Claude y el comando keepalive."
T_CONFIRM="¿Desinstalar por completo?"
T_CLAUDE_Q="¿Desinstalar también Claude Code?"
T_NODE_Q="¿Desinstalar también Node.js?"
T_CRON_OK="Entradas del crontab eliminadas"
T_CRON_NONE="No había entradas en el crontab"
T_FILES_OK="Archivos eliminados"
T_CLAUDE_OK="Claude Code desinstalado"
T_CLAUDE_FAIL="No se pudo desinstalar Claude Code"
T_NODE_OK="Node.js desinstalado"
T_NODE_FAIL="No se pudo desinstalar Node.js"
T_SKIP="se queda instalado"
T_DONE="Desinstalación completa."
T_CANCELLED="No se quitó nada."

ui_section "$T_TITLE"
printf '\n  %s\n' "$T_WHAT"
ui_yes "$T_CONFIRM" false || { ui_note "$T_CANCELLED"; exit 0; }
echo ""

# 1. Crontab
if crontab -l 2>/dev/null | grep -q "session-starter"; then
    crontab -l 2>/dev/null \
        | grep -v "session-starter" \
        | grep -vE "^# (Claude|Codex|Agent) session" \
        | crontab -
    ui_ok "$T_CRON_OK"
else
    ui_note "$T_CRON_NONE"
fi

# 2. Generated files, the year-long Claude token and its line in ~/.bashrc
sed -i '/# >>> claude-keepalive token >>>/,/# <<< claude-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null || true
sed -i '/# >>> agent-keepalive token >>>/,/# <<< agent-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null || true
# Everything the person kept lives in STATE_DIR; an install from before also left files next to the code.
rm -rf "$STATE_DIR"
rm -f "$KEEPALIVE_DIR/config.sh" "$KEEPALIVE_DIR/.claude-token" "$KEEPALIVE_DIR/.claude-token.created" \
      "$KEEPALIVE_DIR"/sessions.log* "$KEEPALIVE_DIR"/*-sessions.log*
[[ "$(readlink -f "$HOME/.local/bin/keepalive" 2>/dev/null)" == "$KEEPALIVE_DIR/keepalive" ]] && rm -f "$HOME/.local/bin/keepalive"
ui_ok "$T_FILES_OK"

# 3. Claude Code (optional)
if command -v claude >/dev/null 2>&1; then
    if ui_yes "$T_CLAUDE_Q" false; then
        sudo npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1 \
            && ui_ok "$T_CLAUDE_OK" || ui_fail "$T_CLAUDE_FAIL"
    else
        ui_note "Claude Code $T_SKIP"
    fi
fi

# 4. Node.js (optional)
if command -v node >/dev/null 2>&1; then
    if ui_yes "$T_NODE_Q" false; then
        sudo apt-get remove -y nodejs >/dev/null 2>&1 \
            && ui_ok "$T_NODE_OK" || ui_fail "$T_NODE_FAIL"
    else
        ui_note "Node.js $T_SKIP"
    fi
fi

echo ""
ui_ok "$T_DONE"
echo ""
