#!/usr/bin/env bash
# build_story_repo.sh — build a fresh Session 4 collaborative-story repo sized to
# the class roster (the scaffold ships 16 chapter files and 8 prompts per premise).
#
# Usage, from the course repo root (AIAgentsCourse/):
#   bash admin/class_of_32/build_story_repo.sh roster.csv ~/class_collab
#
# What it does:
#   - copies session_4/github_collaboration_practice/ to the target folder,
#     leaving out INSTRUCTOR.md
#   - replaces ALL chapter files with fresh placeholders, one per student.
#     (The scaffold's chapters 2, 3, 5, 6 and 8 already contain prose from an
#     earlier run.) Placeholders contain the "Drafter: replace this comment"
#     marker that assemble.sh uses to skip unwritten chapters.
#   - writes CHAPTERS.md from the roster, with the premise prompt for each
#     chapter: chapter N uses prompt ((N-1) mod 8) + 1, so with 32 students each
#     scene gets four independent takes.
#   - fixes the premise files' references to PAIRS.md (the file is CHAPTERS.md)
# It does not touch git or GitHub; it prints the commands for that at the end.

set -euo pipefail

ROSTER="${1:-}"; TARGET="${2:-}"
SCAFFOLD="session_4/github_collaboration_practice"
PROMPTS_PER_PREMISE=8

if [ -z "$ROSTER" ] || [ -z "$TARGET" ]; then sed -n '2,8p' "$0"; exit 1; fi
[ -d "$SCAFFOLD" ] || { echo "Error: run from the course repo root ($SCAFFOLD not found)"; exit 1; }
[ -f "$ROSTER" ] || { echo "Error: roster not found: $ROSTER"; exit 1; }
[ -e "$TARGET" ] && { echo "Error: $TARGET already exists; pick a new folder"; exit 1; }

# Roster rows: skip header, comments, blank lines; strip CR from Excel CSVs.
ROWS="$(tail -n +2 "$ROSTER" | tr -d '\r' | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' || true)"
N="$(echo "$ROWS" | grep -c . || true)"
[ "$N" -gt 0 ] || { echo "Error: roster has no students"; exit 1; }
[ "$N" -le 99 ] || { echo "Error: more than 99 students; chapter numbers are two digits"; exit 1; }

mkdir -p "$TARGET"
cp -R "$SCAFFOLD"/. "$TARGET"/
rm -f "$TARGET/INSTRUCTOR.md"
rm -f "$TARGET"/chapters/chapter_*.md
find "$TARGET" -name .DS_Store -delete

{
    echo "# Chapter Assignments"
    echo ""
    echo "Find your name. Write \`chapters/chapter_NN.md\` (two digits) using the prompt"
    echo "number shown, from the premise we vote on in class."
    echo ""
    echo "| Chapter | Writer | GitHub | Prompt |"
    echo "|---------|--------|--------|--------|"
} > "$TARGET/CHAPTERS.md"

i=0
echo "$ROWS" | while IFS=, read -r NAME HANDLE _rest; do
    i=$((i + 1))
    NN="$(printf '%02d' "$i")"
    PROMPT=$(( (i - 1) % PROMPTS_PER_PREMISE + 1 ))
    HANDLE="$(echo "$HANDLE" | tr -d ' ' | sed -e 's|^https\{0,1\}://github.com/||' -e 's|/.*$||' -e 's|^@||')"
    echo "| $NN | $NAME | ${HANDLE:-?} | $PROMPT |" >> "$TARGET/CHAPTERS.md"
    cat > "$TARGET/chapters/chapter_$NN.md" <<CHAPTER
# Chapter $i

<!-- Drafter: replace this comment with your chapter (premise prompt $PROMPT).
     Feature at least one of the named characters (see characters.md).
     Length doesn't matter. Five minutes. Write, push, merge, move on. -->
CHAPTER
done

# Premise files and README point students to PAIRS.md, which does not exist.
for f in "$TARGET"/premises/*.md "$TARGET"/README.md; do
    [ -f "$f" ] || continue
    sed -e 's/PAIRS\.md/CHAPTERS.md/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
for f in "$TARGET"/premises/premise_*.md; do
    printf '\n---\n\n**More than %d writers?** Your prompt number is in the Prompt column of `CHAPTERS.md`. Several people write the same scene; that is intended.\n' "$PROMPTS_PER_PREMISE" >> "$f"
done

echo "Built $TARGET with $N chapter files."
echo ""
echo "Next:"
echo "  cd $TARGET && git init -b main && git add . && git commit -m 'Initial scaffold'"
echo "  gh repo create <you>/class-collab --public --source=. --push"
echo "  then protect main (Settings > Branches > require a pull request) and run:"
echo "  bash <course repo>/admin/class_of_32/invite_collaborators.sh invite <you>/class-collab $ROSTER"
