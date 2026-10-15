#!/bin/bash
# Connects Claude Code to this machine for a year, so neither the cron nor the terminal needs `claude login` again.
#
# `claude login` keeps a short session that renews itself; when two processes renew it at once, or a renewal
# fails, Claude blanks it and asks to log in again. `claude setup-token` instead issues a token that lasts a
# year and never renews, so nothing can break it. This script runs it, keeps only the token in .claude-token
# (readable by you alone), checks it works, and makes every new terminal use it.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
TOKEN_FILE="$SCRIPT_DIR/.claude-token"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

if [[ "${LANGUAGE:-es}" == "es" ]]; then
    T_TITLE="── Conectar Claude por un año ──"
    T_STEPS="Se abre el inicio de sesión de Claude. Abre el enlace en tu navegador, autoriza y pega aquí el código."
    T_PASTE="No se pudo leer el token. Pega el que se mostró arriba (empieza con sk-ant-oat01-): "
    T_BAD="Ese no es un token de Claude."
    T_CHECK="Comprobando el token..."
    T_FAIL="Claude rechazó el token; no se guardó nada. Vuelve a intentarlo."
    T_OK="Listo. Claude queda conectado hasta el %s, sin volver a iniciar sesión."
    T_NOTE="Las terminales nuevas ya lo usan; en esta escribe: source ~/.bashrc"
else
    T_TITLE="── Connect Claude for a year ──"
    T_STEPS="Claude's sign-in opens. Open the link in your browser, approve, and paste the code here."
    T_PASTE="Could not read the token. Paste the one shown above (it starts with sk-ant-oat01-): "
    T_BAD="That is not a Claude token."
    T_CHECK="Checking the token..."
    T_FAIL="Claude refused the token; nothing was saved. Try again."
    T_OK="Done. Claude stays connected until %s, with no further logins."
    T_NOTE="New terminals use it already; in this one run: source ~/.bashrc"
fi

command -v claude >/dev/null 2>&1 || { echo "ERROR: claude not found — run install.sh"; exit 1; }
umask 077
CAPTURE=$(mktemp)
trap 'shred -u "$CAPTURE" 2>/dev/null || rm -f "$CAPTURE"' EXIT

echo ""
printf '\033[1;36m%s\033[0m\n\n%s\n\n' "$T_TITLE" "$T_STEPS"
script -q -e -c "claude setup-token" "$CAPTURE"

# The screen may wrap the token, so a match only counts when it is whole and Claude accepts it below.
TOKEN=$(sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g' "$CAPTURE" | grep -aoE 'sk-ant-oat01-[A-Za-z0-9_-]{60,}' | tail -1)
_works() { CLAUDE_CODE_OAUTH_TOKEN="$1" timeout 120 claude -p "Reply with the single word OK." </dev/null >/dev/null 2>&1; }

echo ""
echo "$T_CHECK"
if [[ -z "$TOKEN" ]] || ! _works "$TOKEN"; then
    read -rsp "$T_PASTE" TOKEN
    echo ""
    [[ "$TOKEN" =~ ^sk-ant-oat01-[A-Za-z0-9_-]{60,}$ ]] || { echo "$T_BAD"; exit 1; }
    echo "$T_CHECK"
    _works "$TOKEN" || { echo "$T_FAIL"; exit 1; }
fi

printf '%s' "$TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
date '+%Y-%m-%d' > "$TOKEN_FILE.created"

# Every new terminal of this user uses the token too, so the interactive login cannot break either.
BLOCK_START="# >>> claude-keepalive token >>>"
if ! grep -qF "$BLOCK_START" "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ""
        echo "$BLOCK_START"
        echo "[ -s \"$TOKEN_FILE\" ] && export CLAUDE_CODE_OAUTH_TOKEN=\"\$(cat \"$TOKEN_FILE\")\""
        echo "# <<< claude-keepalive token <<<"
    } >> "$HOME/.bashrc"
fi

echo ""
printf "\033[1;32m$T_OK\033[0m\n" "$(date -d '+1 year' '+%Y-%m-%d')"
echo "$T_NOTE"
echo ""
