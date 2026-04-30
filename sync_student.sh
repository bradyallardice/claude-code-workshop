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

# Admin folder (lesson plans, syllabus — instructor only)
git rm -r --quiet admin/ 2>/dev/null || true

# Remove this sync script itself
git rm --quiet sync_student.sh 2>/dev/null || true

# Module 1: output and full data
git rm -r --quiet session_1/output/ 2>/dev/null || true
git rm -r --quiet session_1/data/full/ 2>/dev/null || true

# Remove docs: instructor notes, answer keys, correct prompts, decisions
git ls-files 'session_*/docs/instructor_notes.md' | xargs -r git rm --quiet 2>/dev/null || true
git ls-files 'session_*/docs/instructor_answer_key.md' | xargs -r git rm --quiet 2>/dev/null || true
git rm --quiet session_1/docs/demo_prompt_correct.md 2>/dev/null || true
git rm --quiet session_1/docs/decisions.md 2>/dev/null || true

# Remove solution scripts
git ls-files 'session_*/scripts/solution_*.py' | xargs -r git rm --quiet 2>/dev/null || true

# Remove teacher-only scripts
git rm --quiet session_1/scripts/build_county_panel.py session_1/scripts/create_sample_data.py 2>/dev/null || true
git rm --quiet session_2/scripts/build_county_panel.py 2>/dev/null || true
git rm --quiet session_4/scripts/base_regression.py 2>/dev/null || true
git rm --quiet session_4/scripts/buggy_script.py 2>/dev/null || true
git rm --quiet session_8/scripts/api_template.py 2>/dev/null || true

# Remove pre-computed output students should generate themselves
git rm --quiet session_3/output/merged_survey.csv 2>/dev/null || true
git rm --quiet session_3/output/robustness_table.png 2>/dev/null || true
git rm --quiet session_3/output/robustness_table.tex 2>/dev/null || true
git rm --quiet session_3/output/fx_rate_figure.png 2>/dev/null || true
git rm --quiet session_3/output/main_table.tex 2>/dev/null || true
git rm --quiet session_3/output/summary_stats.tex 2>/dev/null || true

# Remove teacher-only figure generation script
git rm --quiet session_3/scripts/generate_fx_figure.py 2>/dev/null || true

# Session 4 moved-in debugging/capstone-prep material: remove instructor-only demo code, data, and docs
git rm -r --quiet session_4/code/ 2>/dev/null || true
git rm --quiet session_4/data/course_participants.csv 2>/dev/null || true
git rm --quiet session_4/data/satisfaction.csv 2>/dev/null || true
git rm --quiet session_4/docs/methods_paragraph.md 2>/dev/null || true
git rm --quiet session_4/docs/instructor_notes_debugging.md 2>/dev/null || true
git rm --quiet session_4/github_collaboration_practice/INSTRUCTOR.md 2>/dev/null || true

# Session 4 Option B: remove the instructor demo folder and reference paper
git rm -r --quiet session_4/option_b/exercise_2/demo/ 2>/dev/null || true
git rm --quiet session_4/option_b/exercise_2/paper.tex 2>/dev/null || true
git rm --quiet session_4/option_b/exercise_2/paper.pdf 2>/dev/null || true

# Session 4 Option B Exercise 2: students generate these themselves in Exercise 1
git rm --quiet session_4/option_b/exercise_2/tables/summary_stats.tex 2>/dev/null || true
git rm --quiet session_4/option_b/exercise_2/tables/main_table.tex 2>/dev/null || true
git rm --quiet session_4/option_b/exercise_2/tables/robustness_table.tex 2>/dev/null || true
git rm --quiet session_4/option_b/exercise_2/figures/fx_rate_figure.png 2>/dev/null || true

# Session 4 Option B output: students generate merged_survey.csv themselves
git rm --quiet session_4/option_b/output/merged_survey.csv 2>/dev/null || true

# Session 5 capstone: keep student-facing materials, remove instructor-only notes.
git rm --quiet session_5/capstone-template/INSTRUCTOR.md 2>/dev/null || true
git rm --quiet session_5/session5_slides.tex 2>/dev/null || true

# Remove slide source files and images (keep only PDFs)
git rm -r --quiet slides/img/ 2>/dev/null || true
git ls-files slides/ | grep -v '\.pdf$' | xargs -r git rm --quiet 2>/dev/null || true

# Remove old module-numbered slide PDFs (superseded by session-numbered slides)
# Use separate rm calls so a missing file doesn't abort removal of the others
git rm --quiet slides/module1_slides.pdf 2>/dev/null || true
git rm --quiet slides/module2_slides.pdf 2>/dev/null || true
git rm --quiet slides/module3_slides.pdf 2>/dev/null || true

# Commit
git commit -m "Sync student branch from teacher ($(date +%Y-%m-%d))"

echo ""
echo "Done. Student branch updated."
echo "Run 'git checkout teacher' to go back."
