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
START_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REPO_ROOT=$(git -C "$START_DIR" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
    exit 0
fi
cd "$REPO_ROOT"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "Auto-commit skipped on $BRANCH. Create a replication or extension branch first." >&2
    exit 0
fi

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

# Haiku-generated commit message disabled to reduce token usage.
# Fall back to filename-based message.
MSG=""

if [ -z "$MSG" ]; then
    FILES=$(git diff --cached --name-only 2>/dev/null | head -3 | xargs -I{} basename {})
    MSG="[auto] update ${FILES}"
fi

git commit -m "$MSG" --no-verify 2>/dev/null || true
