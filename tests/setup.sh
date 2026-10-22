#!/bin/bash
# Run as root inside the test container: stand-in agents, a bare "GitHub" repository with the code under test, and
# an install for the user tester like the one install.sh leaves.
set -euo pipefail
mkdir -p /var/lib/stub && chmod 777 /var/lib/stub
echo 2.1.0 > /var/lib/stub/claude; echo 0.50.0 > /var/lib/stub/codex; echo 1.0.0 > /var/lib/stub/opencode
chmod 666 /var/lib/stub/*

cat > /usr/local/bin/claude <<'EOF'
#!/bin/bash
v=$(cat /var/lib/stub/claude)
case "${1:-}" in
  --version) echo "$v (Claude Code)" ;;
  -p) [ -f /var/lib/stub/claude-fails ] && { echo "Failed to authenticate. API Error: 401"; exit 1; }; echo "OK" ;;
  auth) [ "${2:-}" = logout ] && rm -f "$HOME/.claude/.credentials.json"; exit 0 ;;
  *) echo "claude stub" ;;
esac
EOF
cat > /usr/local/bin/codex <<'EOF'
#!/bin/bash
v=$(cat /var/lib/stub/codex)
case "${1:-}" in
  --version) echo "codex-cli $v" ;;
  login)
    mkdir -p "$HOME/.codex"
    python3 - > "$HOME/.codex/auth.json" <<'PY'
import base64, json
def part(d): return base64.urlsafe_b64encode(json.dumps(d).encode()).decode().rstrip("=")
token = part({"alg": "none"}) + "." + part({"email": "dev@example.com", "https://api.openai.com/auth": {"chatgpt_plan_type": "plus"}}) + ".sig"
print(json.dumps({"tokens": {"id_token": token}}))
PY
    echo "Successfully logged in" ;;
  logout) rm -f "$HOME/.codex/auth.json" ;;
  exec) out=""; while [ $# -gt 0 ]; do [ "$1" = -o ] && out="$2"; shift; done; echo OK > "$out" ;;
esac
EOF
cat > /usr/local/bin/opencode <<'EOF'
#!/bin/bash
v=$(cat /var/lib/stub/opencode)
case "${1:-}" in
  --version) echo "$v" ;;
  auth) mkdir -p "$HOME/.local/share/opencode"; echo '{"opencode": {"type": "api", "key": "x"}}' > "$HOME/.local/share/opencode/auth.json" ;;
  run) echo OK ;;
esac
EOF
cat > /usr/local/bin/npm <<'EOF'
#!/bin/bash
case "$1 ${2:-}" in
  "prefix -g") echo /usr/local ;;
  "install -g")
    [ -f /var/lib/stub/npm-fails ] && { echo "npm ERR! network request failed"; exit 1; }
    case "$3" in
      @anthropic-ai/claude-code@latest) a=claude ;; @openai/codex@latest) a=codex ;; opencode-ai@latest) a=opencode ;;
      *) exit 1 ;;
    esac
    [ -w /var/lib/stub/$a ] && [ "$(id -u)" = 0 ] || { echo "EACCES: permission denied"; exit 243; }
    v=$(cat /var/lib/stub/$a); echo "${v%.*}.$(( ${v##*.} + 1 ))" > /var/lib/stub/$a; echo "added 1 package" ;;
esac
EOF
chmod 755 /usr/local/bin/claude /usr/local/bin/codex /usr/local/bin/opencode /usr/local/bin/npm

rm -rf /srv/ka.git /srv/work
git config --global --add safe.directory '*'
git config --global user.email t@t; git config --global user.name t
# The code under test is the working tree as it would be committed (tracked files plus new ones git does not
# ignore), so it becomes one commit on a throwaway copy, never in /src.
mkdir -p /srv/work
if git -C /src rev-parse --git-dir >/dev/null 2>&1; then
  # A file deleted in the working tree is still in the index; it is left out, as a commit would.
  (cd /src && git -c core.fsmonitor=false ls-files -z --cached --others --exclude-standard |
    while IFS= read -r -d '' file; do [ -e "$file" ] && cp -a --parents "$file" /srv/work; done; true)
else
  cp -a /src/. /srv/work
fi
git -C /srv/work init -q -b main && git -C /srv/work add -A
git -C /srv/work -c core.hooksPath=/dev/null commit -q -m "test: code under test"
git clone -q --bare /srv/work /srv/ka.git
chown -R tester:tester /srv/ka.git
su - tester -c '
  git config --global user.email t@t; git config --global user.name t; git config --global --add safe.directory "*"
  d="$HOME/projects/agent-keepalive"
  rm -rf "$HOME/projects" "$HOME/.config/agent-keepalive" "$HOME/.codex" "$HOME/.local/share/opencode" "$HOME/.claude"
  git clone -q /srv/ka.git "$d"
  git -C "$d" config core.fileMode false
  printf "%s\n" "#!/bin/bash" "LANGUAGE=\"es\"" "MORNING_HOUR=7" "MORNING_MINUTE=0" "MORNING_ENABLED=true" \
    "AFTERNOON_HOUR=12" "AFTERNOON_MINUTE=0" "AFTERNOON_ENABLED=true" "NIGHT_HOUR=17" "NIGHT_MINUTE=0" \
    "NIGHT_ENABLED=false" "AGENTS=\"claude\"" "WEEKDAYS=\"1,2,3,4,5\"" "MAX_LOG_LINES=200" > "$d/config.sh"
  mkdir -p "$HOME/.local/bin" && ln -sf "$d/keepalive" "$HOME/.local/bin/keepalive"
  bash -c "SCRIPT_DIR=$d; . $d/lib.sh; write_crontab"
  mkdir -p "$HOME/.config/agent-keepalive" && chmod 700 "$HOME/.config/agent-keepalive"
  echo -n sk-ant-oat01-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx > "$HOME/.config/agent-keepalive/claude-token"
  date -d "-20 days" +%F > "$HOME/.config/agent-keepalive/claude-token.created"
  echo persona@example.com > "$HOME/.config/agent-keepalive/claude-account"
  printf "[%s] [MORNING] OK: OK\n---\n" "$(date -d "-1 day" "+%Y-%m-%d 07:00:01")" > "$d/sessions.log"
'
echo "setup done: $(su - tester -c 'crontab -l | grep -c session-starter') cron lines"
# No systemd in the container: cron counts as active, as on a real server.
printf '#!/bin/sh\n[ "$1 $2" = "is-active cron" ] && exit 0\nexit 3\n' > /usr/local/bin/systemctl && chmod 755 /usr/local/bin/systemctl
