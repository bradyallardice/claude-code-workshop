#!/bin/bash
# sync_student.sh
# Syncs the student branch with teacher, removing teacher-only files.
# Run from the repo root while on the teacher branch.

set -e

# Verify we're in the repo root
if [ ! -f "CLAUDE.md" ]; then
    echo "Error: Run this from the repo root (AIAgentsCourse/)"
    exit 1
fi

# Verify we're on teacher
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "teacher" ]; then
    echo "Error: Switch to the teacher branch first (git checkout teacher)"
    exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: Commit your changes on teacher before syncing"
    exit 1
fi

echo "Syncing student branch from teacher..."

# Switch to student and reset it to match teacher
git checkout student
git reset --hard teacher

# Remove teacher-only files
git rm -r --quiet module_1/output/ 2>/dev/null || true
git rm -r --quiet module_1/data/full/ 2>/dev/null || true

# Remove docs: instructor notes, correct prompts, decisions
git ls-files 'module_*/docs/instructor_notes.md' | xargs -r git rm --quiet 2>/dev/null || true
git rm --quiet module_1/docs/demo_prompt_correct.md 2>/dev/null || true
git rm --quiet module_1/docs/decisions.md 2>/dev/null || true

# Remove teacher-only scripts (keep only module_1/scripts/exercise_build_panel.py)
git rm --quiet module_1/scripts/build_county_panel.py module_1/scripts/create_sample_data.py 2>/dev/null || true
git rm --quiet module_2/scripts/build_county_panel.py 2>/dev/null || true
git rm --quiet module_4/scripts/base_regression.py 2>/dev/null || true
git rm --quiet module_5/scripts/buggy_script.py 2>/dev/null || true
git rm --quiet module_8/scripts/api_template.py 2>/dev/null || true

# Remove slide source files (keep only PDFs)
git rm -r --quiet slides/img/ 2>/dev/null || true
git ls-files slides/ | grep -v '\.pdf$' | xargs -r git rm --quiet 2>/dev/null || true

# Commit
git commit -m "Sync student branch from teacher ($(date +%Y-%m-%d))"

echo ""
echo "Done. Student branch updated."
echo "Run 'git checkout teacher' to go back."
