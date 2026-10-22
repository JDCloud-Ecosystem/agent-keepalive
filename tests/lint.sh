#!/bin/bash
# Checks every shell script of the repository: it parses, shellcheck finds no error, and the warnings do not grow.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The warnings left today, two sources shellcheck cannot follow, a name only another script reads and one local
# declared and assigned together. Lower it when one goes; never raise it.
MAX_WARNINGS=4

cd "$ROOT"

_files() {  # the repository's files, without what git ignores; every file when there is no git
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git ls-files --cached --others --exclude-standard
    else
        find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './tmp/*' | sed 's|^\./||'
    fi
}

# Every file with a .sh name or a bash first line.
mapfile -t SCRIPTS < <(
    _files | grep -v '^node_modules/' | sort | while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        if [[ "$file" == *.sh ]] || head -n 1 "$file" | grep -qE '^#!.*\bbash\b'; then
            printf '%s\n' "$file"
        fi
    done
)
(( ${#SCRIPTS[@]} )) || { echo "No shell scripts found."; exit 1; }

for script in "${SCRIPTS[@]}"; do
    bash -n "$script"
done
echo "${#SCRIPTS[@]} scripts parse."

command -v shellcheck >/dev/null 2>&1 || { echo "tests/lint.sh needs shellcheck (apt install shellcheck)."; exit 2; }
shellcheck -x --severity=error "${SCRIPTS[@]}"
echo "No shellcheck errors."

warnings=$(shellcheck -x --severity=warning -f gcc "${SCRIPTS[@]}" | grep -c ': warning:' || true)
if (( warnings > MAX_WARNINGS )); then
    shellcheck -x --severity=warning "${SCRIPTS[@]}" || true
    echo "$warnings shellcheck warnings, more than the $MAX_WARNINGS allowed."
    exit 1
fi
echo "$warnings shellcheck warnings, at most $MAX_WARNINGS allowed."
