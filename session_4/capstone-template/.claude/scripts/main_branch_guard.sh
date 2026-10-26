#!/usr/bin/env bash
set -euo pipefail

# Find a Python that actually runs. On Windows, 'python3' is often a Microsoft
# Store placeholder that exists on PATH but does nothing.
PYTHON=""
for candidate in python3 python py; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c "import sys" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "Hook ${0##*/} is NOT active: no working Python found (tried python3, python, py)." >&2
    exit 1
fi

START_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REPO_ROOT=$(git -C "$START_DIR" rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$REPO_ROOT" ] && exit 0
cd "$REPO_ROOT"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
case "$BRANCH" in
  main|master) ;;
  *) exit 0 ;;
esac

HOOK_INPUT=$(cat 2>/dev/null || true)

CHECK=$(HOOK_INPUT="$HOOK_INPUT" REPO_ROOT="$REPO_ROOT" "$PYTHON" - <<'PY'
import json
import os
from pathlib import Path

raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    data = {}

paths = []
commands = []

def walk(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"file_path", "path", "filename"} and isinstance(item, str):
                paths.append(item)
            if key in {"command", "cmd"} and isinstance(item, str):
                commands.append(item)
            walk(item)
    elif isinstance(value, list):
        for item in value:
            walk(item)

walk(data)

allowed_setup_files = {"ROLES.md", "CLAUDE.md"}
blocked = []

root = Path(os.environ["REPO_ROOT"]).resolve()

for raw_path in paths:
    # Claude sends absolute paths; make them repo-relative before comparing.
    path = Path(raw_path)
    if path.is_absolute():
        try:
            rel = path.resolve().relative_to(root).as_posix()
        except ValueError:
            rel = path.as_posix()
    else:
        rel = path.as_posix()
        if rel.startswith("./"):
            rel = rel[2:]
    if rel and rel not in allowed_setup_files:
        blocked.append(f"edit target {rel}")

print("\n".join(blocked))
PY
)

COMMIT_COMMAND=$(HOOK_INPUT="$HOOK_INPUT" "$PYTHON" - <<'PY'
import json
import os

raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    data = {}

commands = []

def walk(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"command", "cmd"} and isinstance(item, str):
                commands.append(item)
            walk(item)
    elif isinstance(value, list):
        for item in value:
            walk(item)

walk(data)
print("yes" if any("git commit" in " ".join(command.split()) for command in commands) else "no")
PY
)

if [ "$COMMIT_COMMAND" = "yes" ]; then
    BAD_CHANGED=$(
        {
            git diff --name-only
            git diff --cached --name-only
            git ls-files --others --exclude-standard
        } | sort -u | grep -Ev '^(ROLES.md|CLAUDE.md)$' || true
    )
    if [ -n "$BAD_CHANGED" ]; then
        CHECK="${CHECK}"$'\n'"commit on $BRANCH would include non-setup files:"$'\n'"$BAD_CHANGED"
    fi
fi

if [ -n "$CHECK" ]; then
    echo "Blocked: work on a branch, not on $BRANCH. Create replication or extension first." >&2
    echo "$CHECK" >&2
    exit 2
fi
