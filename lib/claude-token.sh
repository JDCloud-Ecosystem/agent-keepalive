#!/bin/bash
# ── Claude's year token ───────────────────────────────────────────────────────
# Claude prints its year token through a UI that breaks it into lines as wide as the terminal, about 108
# characters split over two lines in most windows, and a copy from the screen keeps those breaks. Both read
# it back whole: the line where it starts plus each following line made only of token characters.
token_from_screen() {  # a captured terminal session on stdin
    if command -v python3 >/dev/null 2>&1; then
        screen_text
    else
        sed 's/\x1b\][^\x07]*\x07//g; s/\x1b\[[0-9;?]*[a-zA-Z]//g' | tr -d '\r'
    fi | awk '
        open && /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*$/ { gsub(/[[:space:]]/, ""); token = token $0; next }
        { open = 0 }
        match($0, /sk-ant-oat01-[A-Za-z0-9_-]+/) { token = substr($0, RSTART, RLENGTH); open = 1 }
        END { if (token != "") print token }'
}

# Claude does not write its screens out in full: it jumps the cursor over spaces and over any cell that
# already shows the right character, so the bytes it sends lack letters the screen has. This plays them on
# a blank screen, like a terminal would, and prints the lines it ends with.
_SCREEN_PY='
import re, sys
data = sys.stdin.buffer.read().decode("utf-8", "replace")
rows, r, c, saved = {}, 0, 0, (0, 0)
parts = re.compile(r"\x1b\[([0-9;?>=<]*)[ -/]*([@-~])|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)?|\x1b[^\[\]]|[\r\n\b]|[^\x1b\r\n\b]+")
def line():
    return rows.setdefault(r, [])
for m in parts.finditer(data):
    s = m.group(0)
    if s == "\r":
        c = 0
    elif s == "\n":
        r += 1
    elif s == "\b":
        c = max(0, c - 1)
    elif s.startswith("\x1b["):
        args, cmd = m.group(1), m.group(2)
        if args and args[0] in "?>=<":
            continue
        n = [int(x) if x.isdigit() else 0 for x in args.split(";")] if args else []
        k = n[0] if n and n[0] else 1
        if cmd == "G":
            c = k - 1
        elif cmd == "C":
            c += k
        elif cmd == "D":
            c = max(0, c - k)
        elif cmd == "A":
            r = max(0, r - k)
        elif cmd == "B":
            r += k
        elif cmd == "E":
            r, c = r + k, 0
        elif cmd == "F":
            r, c = max(0, r - k), 0
        elif cmd in "Hf":
            r, c = k - 1, (n[1] if len(n) > 1 and n[1] else 1) - 1
        elif cmd == "K":
            mode, cells = (n[0] if n else 0), line()
            if mode == 0:
                del cells[c:]
            elif mode == 1:
                cells[:c + 1] = [" "] * min(len(cells), c + 1)
            else:
                rows[r] = []
        elif cmd == "J":
            mode = n[0] if n else 0
            if mode == 0:
                del line()[c:]
                rows = {row: cells for row, cells in rows.items() if row <= r}
            elif mode == 1:
                rows = {row: cells for row, cells in rows.items() if row >= r}
            else:
                rows = {}
        elif cmd == "P":
            del line()[c:c + k]
        elif cmd == "X":
            cells = line()
            cells[c:c + k] = [" "] * len(cells[c:c + k])
    elif s == "\x1b7":
        saved = (r, c)
    elif s == "\x1b8":
        r, c = saved
    elif s == "\x1bM":
        r = max(0, r - 1)
    elif s == "\x1bD":
        r += 1
    elif s == "\x1bE":
        r, c = r + 1, 0
    elif not s.startswith("\x1b"):
        cells = line()
        if len(cells) < c:
            cells.extend(" " * (c - len(cells)))
        cells[c:c + len(s)] = list(s)
        c += len(s)
for row in range(max(rows) + 1 if rows else 0):
    print("".join(rows.get(row, [])).rstrip())
'
screen_text() { python3 -c "$_SCREEN_PY"; }

read_token() {  # what the person pastes, without echo; the lines of one paste arrive together
    local line all="" rest
    { printf '\033[?2004l' >/dev/tty; } 2>/dev/null  # no bracketed-paste marks around what comes next
    IFS= read -rs line || return 1
    all="$line"
    while IFS= read -rs -t 1 line; do all+="$line"; done
    if [[ -n "$line" ]]; then  # the last piece came without its Enter yet; take it, then wait for the Enter
        all+="$line"
        IFS= read -rs rest && all+="$rest"
    fi
    printf '%s\n' "$all" | sed 's/\x1b\[20[01]~//g' | tr -d '[:space:]' | grep -oE 'sk-ant-oat01-[A-Za-z0-9_-]+' | head -1
}

# The year-long Claude token lives outside the repository, so moving or renaming the folder never loses it.
# Installs before 2026-10 kept it next to the scripts; it moves here the first time any script runs.
migrate_token() {
    if [[ -s "$KEEPALIVE_DIR/.claude-token" && ! -s "$CLAUDE_TOKEN" ]]; then
        mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
        mv "$KEEPALIVE_DIR/.claude-token" "$CLAUDE_TOKEN"
        [[ -f "$KEEPALIVE_DIR/.claude-token.created" ]] && mv "$KEEPALIVE_DIR/.claude-token.created" "$CLAUDE_TOKEN.created"
    fi
    # Every terminal of this user uses the token, so the interactive login cannot break either.
    if [[ -s "$CLAUDE_TOKEN" ]] && ! grep -qF "$CLAUDE_TOKEN" "$HOME/.bashrc" 2>/dev/null; then
        sed -i '/# >>> claude-keepalive token >>>/,/# <<< claude-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null
        sed -i '/# >>> agent-keepalive token >>>/,/# <<< agent-keepalive token <<</d' "$HOME/.bashrc" 2>/dev/null
        printf '\n# >>> agent-keepalive token >>>\n[ -s "%s" ] && export CLAUDE_CODE_OAUTH_TOKEN="$(cat "%s")"\n# <<< agent-keepalive token <<<\n' \
            "$CLAUDE_TOKEN" "$CLAUDE_TOKEN" >> "$HOME/.bashrc"
    fi
}

# An address made of plain ASCII, as Claude accounts are; anything with a broken or foreign byte fails.
valid_email() {
    local LC_ALL=C
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$ ]]
}
