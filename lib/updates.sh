#!/bin/bash
# ── Updates ───────────────────────────────────────────────────────────────────
# Every install follows main (docs/adr/0002-every-install-follows-main.md). Looking for a new version is a git
# fetch of main, at most once every UPDATE_EVERY seconds, started by each send and by the menu. What it brings in
# stays in origin/main, so telling whether there is a newer version, and what it changes, needs no network.
UPDATE_EVERY=72000  # 20 hours, so there is one check a day even when the sends move a little
FETCH_SECONDS=60    # a fetch that takes longer is given up, so a machine with no network never waits on it
VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

installed_version() {
    local version
    version=$(tr -d '[:space:]' < "$KEEPALIVE_DIR/version.txt" 2>/dev/null)
    [[ "$version" =~ $VERSION_RE ]] && echo "$version"
}

latest_version() {  # the version on main as of the last check
    local version
    version=$(git -C "$KEEPALIVE_DIR" show origin/main:version.txt 2>/dev/null | tr -d '[:space:]')
    [[ "$version" =~ $VERSION_RE ]] && echo "$version"
}

version_newer() {  # a b: whether version a comes after b; an empty b, an install with no number, comes before all
    [[ "$1" =~ $VERSION_RE ]] || return 1
    [[ -z "$2" ]] && return 0
    [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" == "$1" ]]
}

newer_version() {  # the version on main, when it is newer than the installed one
    local latest
    latest=$(latest_version) && version_newer "$latest" "$(installed_version)" && echo "$latest"
}

_seconds_since_check() {
    local head
    head=$(git -C "$KEEPALIVE_DIR" rev-parse --git-path FETCH_HEAD 2>/dev/null) || { echo "$UPDATE_EVERY"; return; }
    [[ "$head" == /* ]] || head="$KEEPALIVE_DIR/$head"
    [[ -f "$head" ]] || { echo "$UPDATE_EVERY"; return; }
    echo $(( $(date +%s) - $(stat -c %Y "$head") ))
}

# Fetches main. With --if-stale it does nothing when the last check is recent, and leaves it to a check already
# running, so two sends in the same minute fetch once. Never asks for a password or a host key.
check_update() {  # [--if-stale]
    local wait=(-w "$FETCH_SECONDS")
    if [[ "${1:-}" == --if-stale ]]; then
        (( $(_seconds_since_check) < UPDATE_EVERY )) && return 0
        wait=(-n)
    fi
    mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
    (
        if command -v flock >/dev/null 2>&1; then flock "${wait[@]}" 9 || exit 0; fi
        GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" \
            timeout "$FETCH_SECONDS" git -C "$KEEPALIVE_DIR" fetch -q origin main
    ) 9>"$STATE_DIR/update.lock"
}
