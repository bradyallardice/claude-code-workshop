#!/usr/bin/env bash
#
# auto_commit_hook.sh — Claude Code postToolUse hook for auto-committing.
#
# Install by adding to .claude/hooks.json:
#
# {
#   "hooks": {
#     "postToolUse": [
#       {
#         "matcher": {
#           "toolNames": ["create_file", "str_replace", "bash"]
#         },
#         "command": "bash .claude/scripts/auto_commit_hook.sh"
#       }
#     ]
#   }
# }
#
# This script runs after each Claude Code tool invocation that modifies files.
# It stages all changes and commits with a descriptive [auto] tagged message.

set -euo pipefail

# Find repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
    exit 0
fi
cd "$REPO_ROOT"

# Skip if no changes
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    exit 0
fi

# Stage everything
git add -A

# Skip if nothing staged
if git diff --cached --quiet 2>/dev/null; then
    exit 0
fi

# Read hook input from stdin (JSON with toolName, etc.)
TOOL_INPUT=$(cat 2>/dev/null || echo "{}")

TOOL_NAME=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('toolName', 'unknown'))
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

# Generate commit message using a Python helper that reads diff info directly
MSG=$(python3 - << 'PYEOF'
import subprocess, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()

stat = run(["git", "diff", "--cached", "--stat"])
diff = run(["git", "diff", "--cached"])
added_files = set(run(["git", "diff", "--cached", "--diff-filter=A", "--name-only"]).split("\n"))
deleted_files = set(run(["git", "diff", "--cached", "--diff-filter=D", "--name-only"]).split("\n"))

lines = stat.strip().split("\n")
files = [l.strip().split("|")[0].strip() for l in lines if "|" in l]
n_files = len(files)

if n_files == 0:
    sys.exit(1)

parts = []
for f in files:
    name = f.split("/")[-1]
    if f in added_files:
        parts.append(f"add {name}")
    elif f in deleted_files:
        parts.append(f"remove {name}")
    else:
        parts.append(f"update {name}")

if n_files <= 3:
    msg = "[auto] " + ", ".join(parts)
else:
    dirs = set("/".join(f.split("/")[:-1]) for f in files if "/" in f)
    dir_str = ", ".join(sorted(dirs)) if dirs else "project"
    msg = f"[auto] update {n_files} files in {dir_str}"

# Add context hint from first meaningful added line
add_lines = [l[1:].strip() for l in diff.split("\n")
             if l.startswith("+") and not l.startswith("+++") and len(l[1:].strip()) > 10]
if add_lines and n_files <= 3:
    hint = add_lines[0][:60]
    if len(add_lines[0]) > 60:
        hint += "..."
    msg += f" — {hint}"

print(msg)
PYEOF
)

if [ -z "$MSG" ]; then
    FILES=$(git diff --cached --name-only 2>/dev/null | head -3 | xargs -I{} basename {})
    MSG="[auto] update ${FILES}"
fi

git commit -m "$MSG" --no-verify 2>/dev/null || true
