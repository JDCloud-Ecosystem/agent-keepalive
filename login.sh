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

T_TITLE="CONECTAR CLAUDE POR UN AÑO"
T_STEPS="Se abre el inicio de sesión de Claude. Abre el enlace en tu navegador, autoriza y pega aquí el código."
T_PASTE="No se pudo leer el token. Pega el que se mostró arriba, completo aunque ocupe varias líneas (empieza con sk-ant-oat01-), y pulsa Enter "
T_BAD="Ese no es un token de Claude."
T_CHECK="Comprobando el token."
T_FAIL="Claude rechazó el token y no se guardó nada. Vuelve a intentarlo. Esto respondió Claude."
T_LIMIT="Claude aceptó el token, pero la cuenta está en su límite de uso, así que se guarda igual. Esto respondió Claude."
T_OK="Listo. Claude queda conectado hasta el %s, sin volver a iniciar sesión."
T_NOTE="Las terminales nuevas ya lo usan. En una que ya estaba abierta escribe source ~/.bashrc."
T_WHO="¿Con qué cuenta de Claude entraste? Pulsa Enter si fue %s "
T_WHO_NEW="¿Con qué cuenta de Claude entraste? Escribe su correo "
T_WHO_BAD="Eso no parece un correo. Escríbelo otra vez, sin acentos, o pulsa Enter para dejarlo en blanco."
T_NO_CLAUDE="Claude Code no está instalado. Corre install.sh primero."

agent_installed claude || { ui_fail "$T_NO_CLAUDE"; exit 1; }
umask 077
CAPTURE=$(mktemp)
trap 'shred -u "$CAPTURE" 2>/dev/null || rm -f "$CAPTURE"' EXIT

ui_section "$T_TITLE"
printf '\n  %s\n\n' "$T_STEPS"
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
    # The same answers session-starter.sh takes for a limit, such as "You've hit your session limit · resets 3pm".
    grep -qiE 'weekly limit|weekly usage|session limit|usage limit|rate limit|quota|hit your .*limit|limit reached' \
        <<< "$ANSWER" && return 2
    return 1
}
_answer() { sed 's/sk-ant-[A-Za-z0-9_-]*/sk-ant-…/g' <<< "$ANSWER" | grep -v '^[[:space:]]*$' | tail -3 | cut -c1-300 | sed 's/^/  /'; }

echo ""
ui_note "$T_CHECK"
_check "$TOKEN"; RESULT=$?
if (( RESULT == 1 )); then
    printf '\n  %s' "$T_PASTE"
    TOKEN=$(read_token)
    echo ""
    [[ "$TOKEN" =~ ^sk-ant-oat01-[A-Za-z0-9_-]{60,}$ ]] || { ui_fail "$T_BAD"; exit 1; }
    ui_note "$T_CHECK"
    _check "$TOKEN"; RESULT=$?
    (( RESULT == 1 )) && { ui_fail "$T_FAIL"; _answer; exit 1; }
fi
(( RESULT == 2 )) && { ui_warn "$T_LIMIT"; _answer; }

mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
printf '%s' "$TOKEN" > "$CLAUDE_TOKEN"
chmod 600 "$CLAUDE_TOKEN"
date '+%Y-%m-%d' > "$CLAUDE_TOKEN.created"
migrate_token

# The token says nothing about its account, so `keepalive status` shows the one written down here. The last
# `claude login` on this machine is the likely answer, offered as the default.
KNOWN=$(sed -nE 's/.*"emailAddress": *"([^"]+)".*/\1/p' "$HOME/.claude.json" 2>/dev/null | head -1)
echo ""
# Only a plain email is written: a terminal that drops half of a typed character would otherwise leave a
# broken byte in the file, and every tool that reads it would trip on it.
while true; do
    if [[ -n "$KNOWN" ]]; then printf "  $T_WHO" "$KNOWN"; else printf '  %s' "$T_WHO_NEW"; fi
    read -r ACCOUNT
    ACCOUNT="${ACCOUNT:-$KNOWN}"
    [[ -z "$ACCOUNT" ]] && break
    valid_email "$ACCOUNT" && break
    ui_warn "$T_WHO_BAD"
    KNOWN=""
done
if [[ -n "$ACCOUNT" ]]; then printf '%s\n' "$ACCOUNT" > "$CLAUDE_ACCOUNT"; else rm -f "$CLAUDE_ACCOUNT"; fi

echo ""
ui_ok "$(printf "$T_OK" "$(date -d '+1 year' '+%d/%m/%Y')")"
ui_note "$T_NOTE"
