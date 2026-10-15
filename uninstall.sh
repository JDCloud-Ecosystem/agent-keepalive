#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
LOG_FILE="$SCRIPT_DIR/sessions.log"
CODEX_LOG_FILE="$SCRIPT_DIR/codex-sessions.log"

# ── Colors ────────────────────────────────────────────────────────────────────
export NEWT_COLORS='
root=,black
border=yellow,black
window=yellow,black
shadow=black,black
title=yellow,black
button=black,yellow
actbutton=white,yellow
checkbox=yellow,black
actcheckbox=black,yellow
entry=yellow,black
label=yellow,black
listbox=yellow,black
actlistbox=black,yellow
textbox=yellow,black
acttextbox=black,yellow
helpline=,black
roottext=yellow,black
emptyscale=black,black
disabledentry=gray,black
'

# ── Language selection (always ask) ──────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null || true
_DEFAULT_LANG="${LANGUAGE:-en}"

if command -v whiptail >/dev/null 2>&1; then
    LANGUAGE=$(whiptail --title "Language" \
        --menu "Choose language / Elige idioma:" 10 45 2 \
        "en" "English" \
        "es" "Español" \
        3>&1 1>&2 2>&3) || LANGUAGE="$_DEFAULT_LANG"
else
    printf "\nChoose language / Elige idioma:\n  1) English\n  2) Español\n"
    read -rp "Choice [1/2, default=1]: " _c
    [[ "${_c:-1}" == "2" ]] && LANGUAGE="es" || LANGUAGE="en"
fi

# ── String tables ─────────────────────────────────────────────────────────────
if [[ "$LANGUAGE" == "es" ]]; then
    T_TITLE="Desinstalar Claude Session"
    T_CONFIRM="¿Desinstalar completamente?\n\nSe eliminará:\n  • Entradas del crontab\n  • config.sh\n  • sessions.log / codex-sessions.log"
    T_CLAUDE_Q="¿También desinstalar Claude Code?\n(npm uninstall -g @anthropic-ai/claude-code)"
    T_NODE_Q="¿También desinstalar Node.js?\n(apt-get remove nodejs)"
    T_CRON_OK="Entradas crontab eliminadas"
    T_CRON_NONE="No había entradas crontab"
    T_FILES_OK="Archivos eliminados"
    T_CLAUDE_OK="Claude Code desinstalado"
    T_NODE_OK="Node.js desinstalado"
    T_SKIP="Omitido"
    T_DONE="── Desinstalación Completa — Claude Session ──"
    T_CANCELLED="Cancelado."
else
    T_TITLE="Uninstall Claude Session"
    T_CONFIRM="Uninstall completely?\n\nThis will remove:\n  • Crontab entries\n  • config.sh\n  • sessions.log / codex-sessions.log"
    T_CLAUDE_Q="Also uninstall Claude Code?\n(npm uninstall -g @anthropic-ai/claude-code)"
    T_NODE_Q="Also uninstall Node.js?\n(apt-get remove nodejs)"
    T_CRON_OK="Crontab entries removed"
    T_CRON_NONE="No crontab entries found"
    T_FILES_OK="Files removed"
    T_CLAUDE_OK="Claude Code uninstalled"
    T_NODE_OK="Node.js uninstalled"
    T_SKIP="Skipped"
    T_DONE="── Uninstall Complete — Claude Session ──"
    T_CANCELLED="Cancelled."
fi

# ── Confirm helper ────────────────────────────────────────────────────────────
_yn() {
    if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "$T_TITLE" --yesno "$1" 14 52 3>&1 1>&2 2>&3
    else
        printf "\n%b\n" "$1"
        read -rp "[y/N]: " _r
        [[ "${_r:-n}" =~ ^[Yy]$ ]]
    fi
}

_yn "$T_CONFIRM" || { echo "$T_CANCELLED"; exit 0; }

echo ""

# 1. Crontab
if crontab -l 2>/dev/null | grep -q "session-starter"; then
    crontab -l 2>/dev/null \
        | grep -v "session-starter" \
        | grep -v "# Claude session" \
        | grep -v "# Codex session" \
        | crontab -
    echo "  ✓ $T_CRON_OK"
else
    echo "  • $T_CRON_NONE"
fi

# 2. Generated files, the year-long Claude token and its line in ~/.bashrc
sed -i '/# >>> claude-keepalive token >>>/,/# <<< claude-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null || true
rm -f "$SCRIPT_DIR/.claude-token" "$SCRIPT_DIR/.claude-token.created"
rm -f "$CONFIG_FILE" \
      "$LOG_FILE"       "${LOG_FILE}.old"       "${LOG_FILE}.tmp" \
      "$CODEX_LOG_FILE" "${CODEX_LOG_FILE}.old" "${CODEX_LOG_FILE}.tmp"
echo "  ✓ $T_FILES_OK"

# 3. Claude Code (optional)
if command -v claude >/dev/null 2>&1; then
    if _yn "$T_CLAUDE_Q"; then
        sudo npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1 \
            && echo "  ✓ $T_CLAUDE_OK" || echo "  ⚠ Could not uninstall Claude Code"
    else
        echo "  • Claude Code — $T_SKIP"
    fi
fi

# 4. Node.js (optional)
if command -v node >/dev/null 2>&1; then
    if _yn "$T_NODE_Q"; then
        sudo apt-get remove -y nodejs >/dev/null 2>&1 \
            && echo "  ✓ $T_NODE_OK" || echo "  ⚠ Could not remove Node.js"
    else
        echo "  • Node.js — $T_SKIP"
    fi
fi

echo ""
printf '\033[1;32m%s\033[0m\n' "$T_DONE"
echo ""
