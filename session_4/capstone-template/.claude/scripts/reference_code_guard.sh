#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOK_INPUT=$(cat 2>/dev/null || true)

CHECK=$(HOOK_INPUT="$HOOK_INPUT" REPO_ROOT="$REPO_ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

raw = os.environ.get("HOOK_INPUT", "")
root = Path(os.environ["REPO_ROOT"]).resolve()
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    data = {}

tool = data.get("toolName") or data.get("tool_name") or data.get("tool", "")
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

def under_reference_code(raw_path):
    path = Path(raw_path)
    if not path.is_absolute():
        path = root / path
    try:
        rel = path.resolve().relative_to(root)
    except (FileNotFoundError, ValueError):
        try:
            rel = path.relative_to(root)
        except ValueError:
            return False
    return rel.parts[:1] == ("reference_code",)

blocked = []
for path in paths:
    if under_reference_code(path):
        blocked.append(f"file target {path}")

write_markers = [
    "sed -i",
    "perl -pi",
    "rm ",
    "rmdir ",
    "touch reference_code/",
    "tee reference_code/",
    "> reference_code/",
    ">> reference_code/",
    "chmod ",
    "chown ",
]

for command in commands:
    compact = " ".join(command.split())
    if "reference_code/" in compact and any(marker in compact for marker in write_markers):
        blocked.append(f"bash command {compact}")

print("\n".join(blocked))
PY
)

if [ -n "$CHECK" ]; then
    echo "Blocked: reference_code/ is read-only for the capstone." >&2
    echo "$CHECK" >&2
    exit 2
fi
