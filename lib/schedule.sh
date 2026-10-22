#!/bin/bash
# ── The schedule in words ─────────────────────────────────────────────────────
join_words() {  # a, b and c
    local out="" i
    for (( i = 1; i <= $#; i++ )); do
        if (( i == 1 )); then out="${!i}"; elif (( i == $# )); then out="$out $U_AND ${!i}"; else out="$out, ${!i}"; fi
    done
    echo "$out"
}

schedule_slots() {  # every enabled sending time as HH:MM, earliest first
    {
        [[ "$MORNING_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$MORNING_HOUR" "$MORNING_MINUTE"
        [[ "$AFTERNOON_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$AFTERNOON_HOUR" "$AFTERNOON_MINUTE"
        [[ "$NIGHT_ENABLED" == "true" ]] && printf '%02d:%02d\n' "$NIGHT_HOUR" "$NIGHT_MINUTE"
    } | sort
}

schedule_days() {  # the days of WEEKDAYS in words, Monday first
    local picked=() names=() d
    IFS=',' read -ra picked <<< "$WEEKDAYS"
    case "$(printf '%s\n' "${picked[@]}" | sort -n | tr '\n' ',')" in
        "0,1,2,3,4,5,6,") echo "$U_EVERY_DAY" ;;
        "1,2,3,4,5,") echo "$U_WEEKDAYS" ;;
        *) for d in 1 2 3 4 5 6 0; do [[ ",$WEEKDAYS," == *",$d,"* ]] && names+=("${U_DAYS[$d]}"); done
           join_words "${names[@]}" ;;
    esac
}

schedule_text() {  # "a las 07:00 y 12:00, de lunes a viernes"
    local slots=()
    mapfile -t slots < <(schedule_slots)
    (( ${#slots[@]} )) || { echo "$U_OFF"; return; }
    echo "$U_AT $(join_words "${slots[@]}"), $(schedule_days)"
}

# When the cron sends next, as "hoy a las 12:00, en 1 h 20 min"; fails when no day or session is enabled.
next_run_text() {
    local slots=() now best="" offset day dow slot epoch minutes when wait
    mapfile -t slots < <(schedule_slots)
    (( ${#slots[@]} )) || return 1
    now=$(date +%s)
    for (( offset = 0; offset <= 7; offset++ )); do
        day=$(date -d "today +$offset day" +%F)
        dow=$(date -d "$day" +%w)
        [[ ",$WEEKDAYS," == *",$dow,"* ]] || continue
        for slot in "${slots[@]}"; do
            epoch=$(date -d "$day $slot" +%s)
            (( epoch > now )) && { best=$epoch; break 2; }
        done
    done
    [[ -n "$best" ]] || return 1
    case "$offset" in
        0) when="$U_TODAY" ;; 1) when="$U_TOMORROW" ;; *) when="$U_ON ${U_DAYS[$dow]}" ;;
    esac
    minutes=$(( (best - now + 59) / 60 ))
    if (( minutes < 60 )); then
        wait="$minutes min"
    elif (( minutes < 1440 )); then
        wait="$(( minutes / 60 )) h"
        (( minutes % 60 )) && wait="$wait $(( minutes % 60 )) min"
    else
        wait="$(( minutes / 1440 )) $( (( minutes / 1440 == 1 )) && echo "$U_DAY" || echo "$U_DAYS_UNIT")"
        (( minutes % 1440 / 60 )) && wait="$wait $U_AND $(( minutes % 1440 / 60 )) h"
    fi
    echo "$when $U_AT $slot, $U_IN $wait"
}
