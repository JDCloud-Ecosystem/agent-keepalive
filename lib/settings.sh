#!/bin/bash
# The person's settings in config.sh, the crontab built from them, and the move of both out of the code folder.

load_config() {
    migrate_data
    # shellcheck source=/dev/null
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    MORNING_HOUR="${MORNING_HOUR:-7}"
    MORNING_MINUTE="${MORNING_MINUTE:-0}"
    AFTERNOON_HOUR="${AFTERNOON_HOUR:-12}"
    AFTERNOON_MINUTE="${AFTERNOON_MINUTE:-0}"
    MORNING_ENABLED="${MORNING_ENABLED:-true}"
    AFTERNOON_ENABLED="${AFTERNOON_ENABLED:-true}"
    NIGHT_ENABLED="${NIGHT_ENABLED:-false}"
    NIGHT_HOUR="${NIGHT_HOUR:-17}"
    NIGHT_MINUTE="${NIGHT_MINUTE:-0}"
    WEEKDAYS="${WEEKDAYS:-1,2,3,4,5}"
    # Older configs only knew CODEX_ENABLED; they keep meaning the same thing.
    if [[ -z "${AGENTS:-}" ]]; then
        AGENTS="claude"
        [[ "${CODEX_ENABLED:-false}" == "true" ]] && AGENTS="claude codex"
    fi
    # Only agents with a usage window belong here; one a config still names from before is dropped.
    local agent kept=""
    for agent in $AGENTS; do [[ " $AGENTS_KNOWN " == *" $agent "* ]] && kept="$kept $agent"; done
    AGENTS="${kept# }"
    [[ -n "$AGENTS" ]] || AGENTS="claude"
}

set_config() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

# Rewrites this user's crontab: every enabled session, for every agent in AGENTS. Lines of other tools stay.
write_crontab() {
    load_config
    {
        crontab -l 2>/dev/null | grep -v "session-starter" | grep -vE "^# (Claude|Codex|Agent) session" | grep -v "^$" || true
        crontab -l 2>/dev/null | grep -q "^PATH=" || echo "PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin"
        local agent
        for agent in $AGENTS; do
            [[ "$MORNING_ENABLED" == "true" ]] && printf '# Agent session - %s morning\n%s %s * * %s %s morning %s\n' \
                "$agent" "$MORNING_MINUTE" "$MORNING_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
            [[ "$AFTERNOON_ENABLED" == "true" ]] && printf '# Agent session - %s afternoon\n%s %s * * %s %s afternoon %s\n' \
                "$agent" "$AFTERNOON_MINUTE" "$AFTERNOON_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
            [[ "$NIGHT_ENABLED" == "true" ]] && printf '# Agent session - %s night\n%s %s * * %s %s night %s\n' \
                "$agent" "$NIGHT_MINUTE" "$NIGHT_HOUR" "$WEEKDAYS" "$SESSION_FILE" "$agent"
        done
        true
    } | crontab -
}

# Installs from before kept config.sh and the logs next to the code. They move to STATE_DIR the first time any
# script of this version runs, under a lock, so two sends that start together move them once. When both places
# have a config.sh, the one in STATE_DIR wins; a log found in both places keeps every line, the old ones last,
# since only an older version still running could have written them.
migrate_data() {
    local agent old new suffix
    [[ -f "$KEEPALIVE_DIR/config.sh" ]] || compgen -G "$KEEPALIVE_DIR/*sessions.log*" >/dev/null || return 0
    mkdir -p "$LOG_DIR" && chmod 700 "$STATE_DIR"
    (
        if command -v flock >/dev/null 2>&1; then flock -w 30 9 || exit 0; fi
        if [[ -f "$KEEPALIVE_DIR/config.sh" ]]; then
            if [[ -f "$CONFIG_FILE" ]]; then rm -f "$KEEPALIVE_DIR/config.sh"; else mv "$KEEPALIVE_DIR/config.sh" "$CONFIG_FILE"; fi
        fi
        for agent in $AGENTS_KNOWN; do
            old=$(legacy_agent_log "$agent") new=$(agent_log "$agent")
            for suffix in "" .old; do
                [[ -f "$old$suffix" ]] || continue
                if [[ -f "$new$suffix" ]]; then
                    cat "$old$suffix" >> "$new$suffix" && rm -f "$old$suffix"
                else
                    mv "$old$suffix" "$new$suffix"
                fi
            done
            rm -f "$old.tmp"
        done
    ) 9>"$STATE_DIR/migrate.lock"
}
