#!/bin/bash
# start_demo.sh
# One command to start the Session 1 live demo in the clean "demo" workspace.
# Rebuilds ~/claude_demo from the current teacher files (via make_demo_branch.sh),
# then opens it in VS Code. Start a Claude Code session in that window and paste the
# prompt from session_1/docs/demo_prompt.md.
#
# Run from the repo root (AIAgentsCourse/):
#   ./start_demo.sh            open the demo workspace in VS Code
#   ./start_demo.sh terminal   launch Claude Code in the terminal instead
#
# Note: every run rebuilds the workspace, so output from a previous demo run is wiped.

set -e

if [ ! -f "make_demo_branch.sh" ]; then
    echo "Error: Run this from the repo root (AIAgentsCourse/)"
    exit 1
fi

DEMO_DIR="$HOME/claude_demo"
./make_demo_branch.sh "$DEMO_DIR" > /dev/null

if [ "$1" = "terminal" ]; then
    cd "$DEMO_DIR"
    exec claude
else
    code "$DEMO_DIR"
fi
