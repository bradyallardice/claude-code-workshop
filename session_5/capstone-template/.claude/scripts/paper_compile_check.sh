#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOK_INPUT=$(cat 2>/dev/null || true)

SHOULD_COMPILE=$(HOOK_INPUT="$HOOK_INPUT" python3 - <<'PY'
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
print("yes" if any(path.endswith("paper/paper.tex") or path == "paper.tex" for path in paths) else "no")
PY
)

[ "$SHOULD_COMPILE" != "yes" ] && exit 0

cd "$REPO_ROOT/paper"

export LC_ALL=C
export LANG=C

MISSING=$(python3 - <<'PY'
from pathlib import Path
import re

paper = Path("paper.tex")
missing = []
for raw_line in paper.read_text(errors="ignore").splitlines():
    line = raw_line.strip()
    if not line or line.startswith("%"):
        continue
    for pattern in (r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}", r"\\input\{([^}]+)\}"):
        for match in re.findall(pattern, line):
            path = Path(match)
            if not path.suffix and pattern.startswith(r"\\includegraphics"):
                candidates = [path.with_suffix(ext) for ext in (".pdf", ".png", ".jpg", ".jpeg")]
            else:
                candidates = [path]
            if not any(candidate.exists() for candidate in candidates):
                missing.append(str(path))

print("\n".join(sorted(set(missing))))
PY
)

if [ -n "$MISSING" ]; then
    echo "Skipping paper compile check: referenced files are not created yet." >&2
    echo "$MISSING" >&2
    exit 0
fi

if command -v latexmk >/dev/null 2>&1; then
    latexmk -pdf -halt-on-error -interaction=nonstopmode paper.tex
elif command -v pdflatex >/dev/null 2>&1; then
    pdflatex -halt-on-error -interaction=nonstopmode paper.tex
else
    echo "Skipping paper compile check: neither latexmk nor pdflatex is available." >&2
    exit 0
fi
