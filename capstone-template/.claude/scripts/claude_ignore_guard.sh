#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOK_INPUT=$(cat 2>/dev/null || true)

TARGETS=$(HOOK_INPUT="$HOOK_INPUT" python3 - <<'PY'
import json
import os

raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    data = {}

paths = []

def walk(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"file_path", "path", "filename"} and isinstance(item, str):
                paths.append(item)
            walk(item)
    elif isinstance(value, list):
        for item in value:
            walk(item)

walk(data)
print("\n".join(paths))
PY
)

[ -z "$TARGETS" ] && exit 0

TARGETS="$TARGETS" REPO_ROOT="$REPO_ROOT" python3 - <<'PY'
from pathlib import Path
import fnmatch
import os
import sys

root = Path(os.environ["REPO_ROOT"]).resolve()
targets = [line for line in os.environ.get("TARGETS", "").splitlines() if line.strip()]

def load_patterns(target: Path):
    patterns = []
    try:
        target = target.resolve()
    except FileNotFoundError:
        target = target.parent.resolve()

    current = target.parent if target.suffix else target
    ancestors = [root]
    try:
        rel_parts = current.relative_to(root).parts
    except ValueError:
        rel_parts = ()

    acc = root
    for part in rel_parts:
        acc = acc / part
        ancestors.append(acc)

    for directory in ancestors:
        ignore_file = directory / ".claudeignore"
        if not ignore_file.exists():
            continue
        for raw in ignore_file.read_text(errors="ignore").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            patterns.append(line)
    return patterns

def matches(rel: str, pattern: str):
    rel = rel.replace("\\", "/")
    pattern = pattern.replace("\\", "/")
    if pattern.endswith("/"):
        return rel.startswith(pattern) or f"/{pattern}" in f"/{rel}"
    if "/" in pattern:
        return fnmatch.fnmatch(rel, pattern)
    return any(fnmatch.fnmatch(part, pattern) for part in rel.split("/"))

blocked = []
for raw_target in targets:
    target = Path(raw_target)
    if not target.is_absolute():
        target = root / target
    try:
        rel = str(target.resolve().relative_to(root))
    except (FileNotFoundError, ValueError):
        try:
            rel = str(target.relative_to(root))
        except ValueError:
            continue

    for pattern in load_patterns(target):
        if matches(rel, pattern):
            blocked.append((rel, pattern))
            break

if blocked:
    for rel, pattern in blocked:
        print(f"Blocked by .claudeignore: {rel} matches {pattern}", file=sys.stderr)
    sys.exit(2)
PY
