#!/bin/bash
# Connects Claude Code to this machine for a year, so neither the cron nor the terminal needs `claude login` again.
# Run it as `keepalive login claude`.
#
# `claude login` keeps a short session that renews itself; when two processes renew it at once, or a renewal
# fails, Claude blanks it and asks to log in again. `claude setup-token` instead issues a token that lasts a
# year and never renews, so nothing can break it. This script runs it, keeps only the token (readable by you
# alone, in ~/.config/agent-keepalive), checks it works, and makes every new terminal use it.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
load_config

if [[ "${LANGUAGE:-es}" == "es" ]]; then
    T_TITLE="── Conectar Claude por un año ──"
    T_STEPS="Se abre el inicio de sesión de Claude. Abre el enlace en tu navegador, autoriza y pega aquí el código."
    T_PASTE="No se pudo leer el token. Pega el que se mostró arriba, completo aunque ocupe varias líneas (empieza con sk-ant-oat01-), y pulsa Enter: "
    T_BAD="Ese no es un token de Claude."
    T_CHECK="Comprobando el token..."
    T_FAIL="Claude rechazó el token; no se guardó nada. Vuelve a intentarlo. Esto respondió:"
    T_LIMIT="Claude aceptó el token, pero la cuenta está en su límite de uso; se guarda igual. Respondió:"
    T_OK="Listo. Claude queda conectado hasta el %s, sin volver a iniciar sesión."
    T_NOTE="Las terminales nuevas ya lo usan; en esta escribe: source ~/.bashrc"
    T_WHO="¿Con qué cuenta de Claude entraste? Pulsa Enter si fue %s: "
    T_WHO_NEW="¿Con qué cuenta de Claude entraste? Escribe su correo: "
else
    T_TITLE="── Connect Claude for a year ──"
    T_STEPS="Claude's sign-in opens. Open the link in your browser, approve, and paste the code here."
    T_PASTE="Could not read the token. Paste the one shown above, whole even if it spans several lines (it starts with sk-ant-oat01-), and press Enter: "
    T_BAD="That is not a Claude token."
    T_CHECK="Checking the token..."
    T_FAIL="Claude refused the token; nothing was saved. Try again. Its answer:"
    T_LIMIT="Claude accepted the token, but the account is at its usage limit; it is saved anyway. Its answer:"
    T_OK="Done. Claude stays connected until %s, with no further logins."
    T_NOTE="New terminals use it already; in this one run: source ~/.bashrc"
    T_WHO="Which Claude account did you sign in with? Press Enter if it was %s: "
    T_WHO_NEW="Which Claude account did you sign in with? Type its email: "
fi

agent_installed claude || { echo "ERROR: claude not found — run install.sh"; exit 1; }
umask 077
CAPTURE=$(mktemp)
trap 'shred -u "$CAPTURE" 2>/dev/null || rm -f "$CAPTURE"' EXIT

echo ""
printf '\033[1;36m%s\033[0m\n\n%s\n\n' "$T_TITLE" "$T_STEPS"
script -q -e -c "claude setup-token" "$CAPTURE"

TOKEN=$(token_from_screen < "$CAPTURE")

# 0: Claude answered with it. 2: Claude refused it for a usage limit, which only an accepted token gets.
# 1: refused or no answer. What Claude said is kept in ANSWER, so a refusal can show why.
ANSWER=""
_check() {
    [[ "$1" =~ ^sk-ant-oat01-[A-Za-z0-9_-]{60,}$ ]] || return 1
    ANSWER=$(CLAUDE_CODE_OAUTH_TOKEN="$1" timeout 120 claude -p "Reply with the single word OK." </dev/null 2>&1)
    local code=$?
    (( code == 124 )) && ANSWER="(no answer in 120 s)"
    (( code == 0 )) && return 0
    grep -qiE 'limit (reached|resets)|usage limit|rate limit|weekly limit|out of (extra )?usage' <<< "$ANSWER" && return 2
    return 1
}
_answer() { sed 's/sk-ant-[A-Za-z0-9_-]*/sk-ant-…/g' <<< "$ANSWER" | grep -v '^[[:space:]]*$' | tail -3 | cut -c1-300 | sed 's/^/  /'; }

echo ""
echo "$T_CHECK"
_check "$TOKEN"; RESULT=$?
if (( RESULT == 1 )); then
    printf '%s' "$T_PASTE"
    TOKEN=$(read_token)
    echo ""
    [[ "$TOKEN" =~ ^sk-ant-oat01-[A-Za-z0-9_-]{60,}$ ]] || { echo "$T_BAD"; exit 1; }
    echo "$T_CHECK"
    _check "$TOKEN"; RESULT=$?
    (( RESULT == 1 )) && { echo "$T_FAIL"; _answer; exit 1; }
fi
(( RESULT == 2 )) && { echo "$T_LIMIT"; _answer; }

mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
printf '%s' "$TOKEN" > "$CLAUDE_TOKEN"
chmod 600 "$CLAUDE_TOKEN"
date '+%Y-%m-%d' > "$CLAUDE_TOKEN.created"
migrate_token

# The token says nothing about its account, so `keepalive status` shows the one written down here. The last
# `claude login` on this machine is the likely answer, offered as the default.
KNOWN=$(sed -nE 's/.*"emailAddress": *"([^"]+)".*/\1/p' "$HOME/.claude.json" 2>/dev/null | head -1)
echo ""
if [[ -n "$KNOWN" ]]; then printf "$T_WHO" "$KNOWN"; else printf '%s' "$T_WHO_NEW"; fi
read -r ACCOUNT
ACCOUNT="${ACCOUNT:-$KNOWN}"
if [[ -n "$ACCOUNT" ]]; then printf '%s\n' "$ACCOUNT" > "$CLAUDE_ACCOUNT"; else rm -f "$CLAUDE_ACCOUNT"; fi

echo ""
printf "\033[1;32m$T_OK\033[0m\n" "$(date -d '+1 year' '+%Y-%m-%d')"
echo "$T_NOTE"
echo ""
