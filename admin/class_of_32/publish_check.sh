#!/usr/bin/env bash
# publish_check.sh — run before class: confirm the student branch is complete,
# current and pushed, so start_session gives every student the right version.
#
# Run from the course repo root (AIAgentsCourse/), on the teacher branch:
#   bash admin/class_of_32/publish_check.sh          # check, then offer to push
#   bash admin/class_of_32/publish_check.sh --check  # check only, never push
#
# Checks, in order:
#   1. No half-finished sync (merge in progress, or the tree left on student)
#   2. Teacher work is committed
#   3. student contains everything on teacher (the last sync succeeded)
#   4. Every slides PDF is at least as new as its .tex (no stale compiled slides)
#   5. tools/sessions.txt points at folders and slides that exist on student
#   6. What students will receive that is not on GitHub yet; then offers to push
# Prints the "Materials version" line students should see after start_session.

set -u
CHECK_ONLY=0; [ "${1:-}" = "--check" ] && CHECK_ONLY=1
PROBLEMS=0
ok()   { printf "  \033[32mOK\033[0m    %s\n" "$1"; }
bad()  { PROBLEMS=$((PROBLEMS + 1)); printf "  \033[31mFIX\033[0m   %s\n        %s\n" "$1" "$2"; }
warn() { printf "  \033[33mWARN\033[0m  %s\n" "$1"; }

[ -f sync_student.sh ] || { echo "Run from the course repo root."; exit 1; }
echo "Publish check — $(date '+%a %d %b %H:%M')"

# 1. Half-finished sync
if [ -f .git/MERGE_HEAD ]; then
    bad "A merge is in progress on $(git branch --show-current) (usually a failed student sync)" \
        "Resolve it, or: git merge --abort && git checkout teacher   then fix sync_student.sh and rerun it"
    echo; echo "Stopping here: nothing else can be checked reliably during a merge."; exit 1
fi
BRANCH="$(git branch --show-current)"
[ "$BRANCH" = "teacher" ] && ok "On teacher" || bad "Working tree is on '$BRANCH', not teacher" "git checkout teacher"

# 2. Uncommitted teacher work
if git diff --quiet && git diff --cached --quiet; then ok "No uncommitted changes"
else bad "Uncommitted changes on $BRANCH" "commit them (the auto-commit hook usually does), then rerun ./sync_student.sh"; fi

git fetch -q origin student 2>/dev/null || warn "Could not reach GitHub; comparing with the last fetched state"

# 3. Last sync complete
if git merge-base --is-ancestor teacher student; then ok "student contains all of teacher (last sync complete)"
else
    N_BEHIND="$(git rev-list --count student..teacher)"
    bad "student is missing $N_BEHIND teacher commit(s)" "./sync_student.sh   (then rerun this check)"
fi

# 4. Stale slide PDFs: compare last commit times of each .tex and its .pdf on teacher
STALE=""
for tex in $(git ls-tree --name-only teacher slides/ | grep '\.tex$'); do
    pdf="${tex%.tex}.pdf"
    git cat-file -e "teacher:$pdf" 2>/dev/null || { STALE="$STALE $pdf(missing)"; continue; }
    T_TEX="$(git log -1 --format=%ct teacher -- "$tex")"
    T_PDF="$(git log -1 --format=%ct teacher -- "$pdf")"
    [ "$T_PDF" -lt "$T_TEX" ] && STALE="$STALE $pdf"
done
# Only decks listed in tools/sessions.txt reach students through start_session,
# so only those block publishing; other stale decks are reported as warnings.
LISTED="$(git show teacher:tools/sessions.txt 2>/dev/null | grep -v '^[[:space:]]*#' | awk -F'|' '{gsub(/ /, "", $3); print $3}')"
STALE_LISTED=""; STALE_OTHER=""
for pdf in $STALE; do
    if echo "$LISTED" | grep -qx "${pdf%(missing)}"; then STALE_LISTED="$STALE_LISTED $pdf"; else STALE_OTHER="$STALE_OTHER $pdf"; fi
done
if [ -z "$STALE_LISTED" ]; then ok "Every slides PDF listed in tools/sessions.txt is at least as new as its .tex"
else bad "Listed slides PDF older than its source:$STALE_LISTED" "recompile those decks and commit the PDFs"; fi
[ -n "$STALE_OTHER" ] && warn "Not in tools/sessions.txt, but older than (or missing) their .tex:$STALE_OTHER"

# 5. Manifest sanity, against what students will actually receive
if git cat-file -e student:tools/sessions.txt 2>/dev/null; then
    MISSING=""
    while IFS='|' read -r num folders slides; do
        case "$num" in ''|\#*) continue ;; esac
        for f in $folders; do git cat-file -e "student:$f" 2>/dev/null || MISSING="$MISSING session$(echo $num):$f"; done
        s="$(echo "$slides" | tr -d ' \r')"; [ -n "$s" ] && { git cat-file -e "student:$s" 2>/dev/null || MISSING="$MISSING session$(echo $num):$s"; }
    done < <(git show student:tools/sessions.txt | grep -v '^[[:space:]]*#')
    [ -z "$MISSING" ] && ok "tools/sessions.txt: every listed folder and slides PDF exists on student" \
                      || bad "tools/sessions.txt lists files students will not have:$MISSING" "fix the manifest or publish those files"
else
    bad "tools/sessions.txt is not on student" "install the kit (tools/) and sync"
fi
for f in tools/start_session.sh tools/start_session.ps1; do
    git cat-file -e "student:$f" 2>/dev/null || bad "$f is not on student" "install the kit (tools/) and sync"
done

# 6. Unpublished changes and push
AHEAD="$(git rev-list --count origin/student..student 2>/dev/null || echo '?')"
VERSION="$(git log -1 --format='%cd  (%h)' --date=format:'%a %d %b %H:%M' student)"
echo ""
if [ "$AHEAD" = "0" ]; then
    ok "GitHub already has the current student branch"
else
    echo "  Not on GitHub yet ($AHEAD commit(s)). Files students will receive that changed:"
    git diff --stat origin/student student | tail -15 | sed 's/^/    /'
fi
echo ""
echo "  After publishing, students' start_session should print:"
echo "    Materials version: $VERSION"

if [ "$PROBLEMS" -gt 0 ]; then
    echo ""; echo "  $PROBLEMS problem(s) above. Not offering to push."; exit 1
fi
[ "$CHECK_ONLY" -eq 1 ] || [ "$AHEAD" = "0" ] && exit 0
printf "\n  Push student to GitHub now? [y/N] "
read -r ANSWER
if [ "$ANSWER" = "y" ] || [ "$ANSWER" = "Y" ]; then
    git push -q origin student && git fetch -q origin student \
        && [ "$(git rev-parse origin/student)" = "$(git rev-parse student)" ] \
        && ok "Pushed. GitHub now serves $VERSION" \
        || { bad "Push did not complete" "run: git push origin student"; exit 1; }
    warn "If you changed start_session.sh/.ps1 themselves, GitHub's raw-file cache can serve the old script for up to 5 minutes."
else
    echo "  Not pushed."
fi
