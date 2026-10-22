#!/bin/bash
# Runs the terminal scenarios of tests/drive.py against this working tree, in a clean Ubuntu container with
# stand-in agents. Needs Docker; on Windows, run it from Git Bash with Docker Desktop.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="agent-keepalive-tests"

command -v docker >/dev/null 2>&1 || { echo "tests/run.sh needs Docker."; exit 2; }

echo "Building the test image..."
docker build -q -t "$IMAGE" "$ROOT/tests" >/dev/null

# Git Bash rewrites paths that start with a slash into Windows paths. The mount needs the Windows form of ROOT on
# the left and the container's own /src on the right, so the rewrite is turned off and ROOT is converted by hand.
SOURCE="$ROOT"
command -v cygpath >/dev/null 2>&1 && SOURCE="$(cygpath -w "$ROOT")"

MSYS_NO_PATHCONV=1 docker run --rm -v "$SOURCE:/src:ro" "$IMAGE" bash -c '
  bash /src/tests/setup.sh > /tmp/setup.log 2>&1 || { cat /tmp/setup.log; exit 1; }
  su - tester -c "cd /tmp && python3 /src/tests/drive.py"
'
