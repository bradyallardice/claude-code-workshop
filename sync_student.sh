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

# Remove teacher-only files. -f forces removal even when the merge re-added or
# modified the file (-X theirs leaves it staged, not unmerged); --ignore-unmatch
# stays quiet for paths that aren't present. Either way the file ends up deleted.

# Admin folder (lesson plans, syllabus — instructor only)
git rm -f -r --quiet --ignore-unmatch admin/

# Remove this sync script itself, and the script that builds the live-demo branch
git rm -f --quiet --ignore-unmatch sync_student.sh
git rm -f --quiet --ignore-unmatch make_demo_branch.sh

# .vscode/settings.json is tracked but hardcodes the instructor's local Stata
# path (/Applications/StataNow), which is wrong on students' machines.
git rm -f --quiet --ignore-unmatch .vscode/settings.json

# Session 1: output and full data
git rm -f -r --quiet --ignore-unmatch session_1/output/
git rm -f -r --quiet --ignore-unmatch session_1/data/full/

# Remove docs: instructor notes, answer keys, correct prompts, decisions
git ls-files 'session_*/docs/instructor_notes.md' | sort -u | xargs -r git rm -f --quiet --ignore-unmatch
git ls-files 'session_*/docs/instructor_answer_key.md' | sort -u | xargs -r git rm -f --quiet --ignore-unmatch
git rm -f --quiet --ignore-unmatch session_1/docs/demo_prompt_correct.md
git rm -f --quiet --ignore-unmatch session_1/docs/decisions.md

# Session 1 demo answers: finished panel-building and regression scripts, the
# Stata-to-Python port, and the data copies prepared for the web-chat upload
git rm -f --quiet --ignore-unmatch session_1/build_panel.py
git rm -f --quiet --ignore-unmatch session_1/build_county_panel.py
git rm -f --quiet --ignore-unmatch session_1/demo_county_panel.py
git rm -f --quiet --ignore-unmatch session_1/regression_ethnicity.py
git rm -f --quiet --ignore-unmatch session_1/stata_demo/analysis.py
git rm -f -r --quiet --ignore-unmatch session_1/demo_chat_upload/

# Remove solution scripts
git ls-files 'session_*/scripts/solution_*' | sort -u | xargs -r git rm -f --quiet --ignore-unmatch

# Remove the instructor verification suite (students write their own tests in the exercise)
git rm -f -r --quiet --ignore-unmatch session_2/tests/

# Remove teacher-only scripts
git rm -f --quiet --ignore-unmatch session_1/scripts/build_county_panel.py session_1/scripts/create_sample_data.py
git rm -f --quiet --ignore-unmatch session_2/scripts/build_county_panel.py
git rm -f --quiet --ignore-unmatch session_4/scripts/base_regression.py
git rm -f --quiet --ignore-unmatch session_4/scripts/buggy_script.py
git rm -f --quiet --ignore-unmatch session_8/scripts/api_template.py

# Remove pre-computed output students should generate themselves
git rm -f --quiet --ignore-unmatch session_2/output/merged_survey.csv
git rm -f --quiet --ignore-unmatch session_2/output/robustness_table.png
git rm -f --quiet --ignore-unmatch session_2/output/robustness_table.tex
git rm -f --quiet --ignore-unmatch session_3/output/fx_rate_figure.png
git rm -f --quiet --ignore-unmatch session_2/output/main_table.tex
git rm -f --quiet --ignore-unmatch session_2/output/summary_stats.tex

# Remove teacher-only figure generation script
git ls-files 'session_*/scripts/generate_fx_figure.*' | sort -u | xargs -r git rm -f --quiet --ignore-unmatch

# Session 3 (git + LaTeX): remove instructor-only demo code and data
# Session 4: remove instructor-only docs
git rm -f -r --quiet --ignore-unmatch session_3/code/
git rm -f --quiet --ignore-unmatch session_3/data/course_participants.csv
git rm -f --quiet --ignore-unmatch session_3/data/satisfaction.csv
git rm -f --quiet --ignore-unmatch session_4/docs/methods_paragraph.md
git rm -f --quiet --ignore-unmatch session_4/docs/instructor_notes_debugging.md
git rm -f --quiet --ignore-unmatch session_4/github_collaboration_practice/INSTRUCTOR.md

# Session 3 Option B: remove the instructor demo folder and reference paper
git rm -f -r --quiet --ignore-unmatch session_3/option_b/exercise_2/demo/
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/paper.tex
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/paper.pdf

# Session 3 Option B Exercise 2: students generate these themselves in Exercise 1
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/tables/summary_stats.tex
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/tables/main_table.tex
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/tables/robustness_table.tex
git rm -f --quiet --ignore-unmatch session_3/option_b/exercise_2/figures/fx_rate_figure.png

# Session 3 Option B output: students generate merged_survey.csv themselves
git rm -f --quiet --ignore-unmatch session_3/option_b/output/merged_survey.csv

# Session 5 capstone: keep student-facing materials, remove instructor-only notes.
git rm -f --quiet --ignore-unmatch session_5/capstone-template/INSTRUCTOR.md
git rm -f --quiet --ignore-unmatch session_5/session5_slides.tex
git rm -f --quiet --ignore-unmatch session_5/session5_slides.pdf

# Remove slide source files and images (keep only PDFs)
git rm -f -r --quiet --ignore-unmatch slides/img/
git ls-files slides/ | grep -v '\.pdf$' | sort -u | xargs -r git rm -f --quiet --ignore-unmatch

# Remove old module-numbered slide PDFs (superseded by session-numbered slides)
git rm -f --quiet --ignore-unmatch slides/module1_slides.pdf
git rm -f --quiet --ignore-unmatch slides/module2_slides.pdf
git rm -f --quiet --ignore-unmatch slides/module3_slides.pdf

# Guard: fail loudly if any known answer file is still in the student tree.
# Add new teacher-only paths here whenever you add them to the rm pass above.
FORBIDDEN_PATHS=(
    admin
    sync_student.sh
    make_demo_branch.sh
    session_1/output
    session_1/data/full
    session_1/demo_chat_upload
    session_1/build_panel.py
    session_1/build_county_panel.py
    session_1/demo_county_panel.py
    session_1/regression_ethnicity.py
    session_1/stata_demo/analysis.py
    session_1/docs/decisions.md
    session_1/docs/demo_prompt_correct.md
    session_1/docs/instructor_notes.md
    session_1/scripts/build_county_panel.py
    session_1/scripts/create_sample_data.py
)
LEAKS=$(git ls-files -- "${FORBIDDEN_PATHS[@]}")
if [ -n "$LEAKS" ]; then
    echo "Error: teacher-only files would be published to the student branch:"
    echo "$LEAKS"
    echo ""
    echo "Abort with: git merge --abort && git checkout teacher"
    exit 1
fi

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
