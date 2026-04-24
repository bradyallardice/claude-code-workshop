#!/bin/bash
# sync_student.sh
# Syncs the student branch with teacher by MERGING (not resetting), so student
# keeps a linear append-only history. Students can always `git pull` fast-forward
# — no force-push required, no history rewrites, no merge conflicts on their end.
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

git checkout student

# If teacher is already fully contained in student's history, nothing to sync
if git merge-base --is-ancestor teacher student; then
    echo "Student is already up to date with teacher. Nothing to sync."
    git checkout teacher
    exit 0
fi

# Merge teacher into student without committing yet. -X theirs auto-resolves
# content conflicts in teacher's favor (teacher is the source of truth).
# Modify/delete conflicts — where teacher modifies a file student has previously
# removed — are resolved below by the `git rm` pass.
# `|| true` so we can continue past the non-zero exit when conflicts exist.
git merge teacher --no-ff --no-commit -X theirs || true

# Remove teacher-only files. --ignore-unmatch keeps the script quiet for paths
# that aren't present, and `git rm` on a file that's in an unmerged state from
# the merge above resolves the conflict by choosing "delete."

# Admin folder (lesson plans, syllabus — instructor only)
git rm -r --quiet --ignore-unmatch admin/

# Remove this sync script itself
git rm --quiet --ignore-unmatch sync_student.sh

# Session 1: output and full data
git rm -r --quiet --ignore-unmatch session_1/output/
git rm -r --quiet --ignore-unmatch session_1/data/full/

# Remove docs: instructor notes, answer keys, correct prompts, decisions
git ls-files 'session_*/docs/instructor_notes.md' | sort -u | xargs -r git rm --quiet --ignore-unmatch
git ls-files 'session_*/docs/instructor_answer_key.md' | sort -u | xargs -r git rm --quiet --ignore-unmatch
git rm --quiet --ignore-unmatch session_1/docs/demo_prompt_correct.md
git rm --quiet --ignore-unmatch session_1/docs/decisions.md

# Remove solution scripts
git ls-files 'session_*/scripts/solution_*.py' | sort -u | xargs -r git rm --quiet --ignore-unmatch

# Remove teacher-only scripts
git rm --quiet --ignore-unmatch session_1/scripts/build_county_panel.py session_1/scripts/create_sample_data.py
git rm --quiet --ignore-unmatch session_2/scripts/build_county_panel.py
git rm --quiet --ignore-unmatch session_4/scripts/base_regression.py
git rm --quiet --ignore-unmatch session_5/scripts/buggy_script.py
git rm --quiet --ignore-unmatch session_8/scripts/api_template.py

# Remove pre-computed output students should generate themselves
git rm --quiet --ignore-unmatch session_3/output/merged_survey.csv
git rm --quiet --ignore-unmatch session_3/output/robustness_table.png
git rm --quiet --ignore-unmatch session_3/output/robustness_table.tex
git rm --quiet --ignore-unmatch session_3/output/fx_rate_figure.png
git rm --quiet --ignore-unmatch session_3/output/main_table.tex
git rm --quiet --ignore-unmatch session_3/output/summary_stats.tex

# Remove teacher-only figure generation script
git rm --quiet --ignore-unmatch session_3/scripts/generate_fx_figure.py

# Session 5: remove instructor-only demo code, data, and docs
git rm -r --quiet --ignore-unmatch session_5/code/
git rm -r --quiet --ignore-unmatch session_5/data/
git rm --quiet --ignore-unmatch session_5/docs/methods_paragraph.md

# Session 5 Option B: remove the instructor demo folder and reference paper
git rm -r --quiet --ignore-unmatch session_5/option_b/exercise_2/demo/
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/paper.tex
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/paper.pdf

# Session 5 Option B Exercise 2: students generate these themselves in Exercise 1
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/tables/summary_stats.tex
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/tables/main_table.tex
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/tables/robustness_table.tex
git rm --quiet --ignore-unmatch session_5/option_b/exercise_2/figures/fx_rate_figure.png

# Session 5 Option B output: students generate merged_survey.csv themselves
git rm --quiet --ignore-unmatch session_5/option_b/output/merged_survey.csv

# Remove slide source files and images (keep only PDFs)
git rm -r --quiet --ignore-unmatch slides/img/
git ls-files slides/ | grep -v '\.pdf$' | sort -u | xargs -r git rm --quiet --ignore-unmatch

# Remove old module-numbered slide PDFs (superseded by session-numbered slides)
git rm --quiet --ignore-unmatch slides/module1_slides.pdf
git rm --quiet --ignore-unmatch slides/module2_slides.pdf
git rm --quiet --ignore-unmatch slides/module3_slides.pdf

# If anything is still unmerged after the rm pass, bail loudly so a human can resolve
if git ls-files --unmerged | grep -q .; then
    echo "Error: unresolved merge conflicts remain on files the sync does not remove:"
    git ls-files --unmerged | awk '{print $4}' | sort -u
    echo ""
    echo "Resolve manually (git add <file> after editing), then run:"
    echo "  git commit -m \"Sync student branch from teacher ($(date +%Y-%m-%d))\""
    exit 1
fi

# Commit the merge + file removals as one merge commit
git commit -m "Sync student branch from teacher ($(date +%Y-%m-%d))"

echo ""
echo "Done. Student branch updated."
echo "Push with: git push origin student  (no --force needed)"
echo "Run 'git checkout teacher' to go back."
