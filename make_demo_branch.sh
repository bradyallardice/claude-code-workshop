#!/bin/bash
# make_demo_branch.sh
# Builds the live-demo workspace for Session 1: a separate folder, on its own
# history-free branch called "demo", that contains ONLY the data, the loose demo
# prompt, and a CLAUDE.md that keeps Claude working autonomously. Nothing that
# gives away the answers (output/, scripts, decisions.md, slides, other sessions)
# is in it, and the branch shares no commits with teacher.
#
# Run from the repo root (AIAgentsCourse/). Optional argument: target folder
# (default ~/claude_demo). Re-running rebuilds the folder and branch from scratch.
#
# Files are copied from your working tree, so uncommitted edits to the demo prompt
# or data are picked up. The folder is a git worktree, so your teacher checkout is
# never switched or touched.

set -e

if [ ! -f "CLAUDE.md" ] || [ ! -f "sync_student.sh" ]; then
    echo "Error: Run this from the repo root (AIAgentsCourse/)"
    exit 1
fi

DEMO_DIR="${1:-$HOME/claude_demo}"
REPO_ROOT="$(pwd)"

# Rebuild: remove an earlier demo worktree, but refuse to delete any other folder
if [ -e "$DEMO_DIR" ]; then
    if git worktree list --porcelain | grep -q "^worktree $DEMO_DIR$"; then
        git worktree remove --force "$DEMO_DIR"
    else
        echo "Error: $DEMO_DIR exists and is not a demo worktree. Remove it or pass another path."
        exit 1
    fi
fi
git worktree prune
git branch -D demo 2>/dev/null || true

# New worktree on an orphan branch (no shared history with teacher)
git worktree add --detach "$DEMO_DIR" HEAD --quiet
cd "$DEMO_DIR"
git checkout --orphan demo --quiet
git rm -rf --quiet .

# Whitelist: only the data and the demo prompt
mkdir -p session_1/data session_1/docs
cp -R "$REPO_ROOT/session_1/data/election" session_1/data/election
cp -R "$REPO_ROOT/session_1/data/ipums"    session_1/data/ipums
cp "$REPO_ROOT/session_1/docs/demo_prompt.md" session_1/docs/demo_prompt.md
find . -name ".DS_Store" -not -path "./.git/*" -delete

cat > CLAUDE.md <<'CLAUDEMD'
# Live demo: an underspecified request

This folder is a stripped-down copy of the course repo, built for a live classroom
demo. It contains only the data (`session_1/data/`) and the demo prompt
(`session_1/docs/demo_prompt.md`).

How to work here:

- Carry out the request end to end, in one pass.
- Do not ask clarifying questions and do not pause for confirmation. Where the
  request leaves something open, pick a sensible default yourself and keep going.
- Run the code yourself and fix any errors that come up.
- Use only the files in this folder. Do not look elsewhere on disk, and do not
  inspect git history or other branches.
- Write all outputs to `session_1/output/`.
- Use Python.
- When you are done, summarize what you produced.
CLAUDEMD

mkdir -p .claude
cat > .claude/settings.json <<'SETTINGS'
{
  "permissions": {
    "deny": [
      "Bash(git:*)"
    ]
  }
}
SETTINGS

git add -A
git commit --quiet -m "Live-demo workspace (data + prompt only)"

echo ""
echo "Demo workspace ready: $DEMO_DIR  (branch: demo)"
echo "Open that folder in VS Code and start a fresh Claude Code session there."
echo "Do not push the demo branch."
