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

# Generate commit message
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -5)
N_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

if [ "$N_FILES" -eq 0 ]; then
    exit 0
fi

if [ "$N_FILES" -eq 1 ]; then
    FILE=$(echo "$CHANGED_FILES" | head -1)
    BASENAME=$(basename "$FILE")
    EXT="${BASENAME##*.}"

    case "$EXT" in
        py)              PREFIX="analysis" ;;
        md)              PREFIX="docs" ;;
        json|yaml|yml)   PREFIX="config" ;;
        csv|parquet|dta) PREFIX="data" ;;
        tex|bib)         PREFIX="paper" ;;
        sh)              PREFIX="script" ;;
        *)               PREFIX="update" ;;
    esac

    if git diff --cached --diff-filter=A --name-only | grep -q "$FILE"; then
        ACTION="add"
    elif git diff --cached --diff-filter=D --name-only | grep -q "$FILE"; then
        ACTION="remove"
    else
        ACTION="modify"
    fi

    MSG="[auto] ${PREFIX}: ${ACTION} ${BASENAME}"
else
    COMMON_DIR=$(echo "$CHANGED_FILES" | sed 's|/[^/]*$||' | sort -u | head -1)
    MSG="[auto] update: ${N_FILES} files in ${COMMON_DIR:-project}"
fi

git commit -m "$MSG" --no-verify 2>/dev/null || true
