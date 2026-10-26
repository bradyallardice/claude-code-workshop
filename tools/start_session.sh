#!/usr/bin/env bash
# start_session.sh — get the current course materials and today's folders, in one step.
#
# Students run (Mac, Linux, or Git Bash on Windows), replacing 2 with today's session:
#   curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 2
#
# What it does, in order:
#   1. Finds the course repo (~/claude-code-workshop, ~/Documents/..., ~/Desktop/...),
#      or downloads it if missing.
#   2. Backs up anything you changed inside the course repo (git stash + a backup
#      branch), then moves the repo to exactly the version the instructor published.
#      It fetches only the latest snapshot, so there is nothing to merge or conflict.
#   3. Copies today's folders into ~/my_workspace. A folder you already have there
#      is NEVER overwritten.
#   4. Copies today's slides into ~/my_workspace/slides/ (always the newest version).
#   5. Opens ~/my_workspace in VS Code.
# If git does not work at all, it downloads a zip of the materials instead.
#
# Settings for testing (students never need these):
#   WORKSHOP_REPO_URL  WORKSHOP_BRANCH  WORKSHOP_HOME  WORKSHOP_ZIP_URL  WORKSHOP_NO_OPEN=1

set -u

SESSION="${1:-}"
REPO_URL="${WORKSHOP_REPO_URL:-https://github.com/bradyallardice/claude-code-workshop.git}"
BRANCH="${WORKSHOP_BRANCH:-student}"
BASE="${WORKSHOP_HOME:-$HOME}"
ZIP_URL="${WORKSHOP_ZIP_URL:-https://github.com/bradyallardice/claude-code-workshop/archive/refs/heads/$BRANCH.zip}"
MANIFEST_URL="${WORKSHOP_MANIFEST_URL:-https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/$BRANCH/tools/sessions.txt}"
WORKSPACE="$BASE/my_workspace"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf "  %s\n" "$1"; }
ok()   { printf "  \033[32mOK\033[0m    %s\n" "$1"; }
note() { printf "  \033[33mNOTE\033[0m  %s\n" "$1"; }
die()  { printf "\n  \033[31mSTOPPED\033[0m %s\n  Raise your red sticky note and show this screen.\n\n" "$1"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

case "$SESSION" in
    [0-9]|[0-9][0-9]) ;;
    *) die "Give the session number, e.g.:  ... | bash -s -- 2" ;;
esac

echo ""
echo "Starting session $SESSION"

# ---------------------------------------------------------------------------
# 1-2. Get the published version of the course repo
REPO=""
for candidate in "$BASE/claude-code-workshop" "$BASE/Documents/claude-code-workshop" "$BASE/Desktop/claude-code-workshop"; do
    if [ -d "$candidate/.git" ]; then REPO="$candidate"; break; fi
done

# git stash and backup branches need an identity; supply one so a missing
# git config never blocks the update.
# core.longpaths matters on Windows (paths near the 260-character limit); other
# platforms ignore it.
G() { git -c user.name="workshop" -c user.email="workshop@localhost" -c advice.detachedHead=false -c core.longpaths=true "$@"; }

# Fresh shallow clone into $1; also used to replace a copy that cannot be updated.
fresh_clone() {
    G clone -q --depth 1 --branch "$BRANCH" --single-branch "$REPO_URL" "$1" && git -C "$1" config core.longpaths true
}

# Replace a copy that cannot be updated: clone fresh beside it first, and only
# then swap, so nothing moves if the network is the problem. The old copy is kept.
replace_with_fresh() {
    local NEW="$REPO.new-$STAMP"
    fresh_clone "$NEW" || { rm -rf "$NEW"; return 1; }
    if mv "$REPO" "$REPO.old-$STAMP" 2>/dev/null; then
        if mv "$NEW" "$REPO"; then note "Kept your previous copy, untouched, as $REPO.old-$STAMP"; else REPO="$NEW"; fi
    else
        REPO="$NEW"
        note "Your previous copy is in use (open in an editor?), so the fresh copy is at $REPO"
    fi
}

USE_ZIP=0
if ! have git; then
    note "git not found; downloading a zip of the materials instead"
    USE_ZIP=1
elif [ -z "$REPO" ]; then
    REPO="$BASE/claude-code-workshop"
    if [ -e "$REPO" ]; then
        mv "$REPO" "$REPO.old-$STAMP"
        note "Moved a non-git folder out of the way: $REPO.old-$STAMP"
    fi
    say "Downloading the course materials (first time on this computer)..."
    if fresh_clone "$REPO"; then
        ok "Downloaded to $REPO"
    else
        note "git clone failed; trying the zip download instead"
        USE_ZIP=1
    fi
else
    cd "$REPO" || die "Cannot enter $REPO"
    # A pull that stopped half way leaves a merge or rebase open; close it first.
    # Aborting returns the files to how they were before that pull.
    [ -f .git/MERGE_HEAD ] && G merge --abort 2>/dev/null && note "Closed an unfinished merge from an earlier git pull"
    { [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; } && G rebase --abort 2>/dev/null && note "Closed an unfinished rebase"
    rm -f .git/index.lock 2>/dev/null
    git config core.longpaths true

    say "Fetching the latest version..."
    # Update in place: back up edits, keep local commits on a branch, switch.
    # If any step fails (no network, or a copy damaged e.g. by Windows'
    # path-length limit), fall back to a fresh copy.
    UPDATED=0
    if G fetch -q --depth 1 "$REPO_URL" "$BRANCH"; then
        UPDATED=1
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            if G stash push -q -u -m "start_session backup $STAMP" 2>/dev/null; then
                note "You had changed files inside the course repo. Saved them: git stash list (in $REPO)"
            else
                UPDATED=0
            fi
        fi
        if [ "$UPDATED" -eq 1 ]; then
            if git rev-parse -q --verify HEAD >/dev/null && [ "$(git rev-parse HEAD)" != "$(git rev-parse FETCH_HEAD)" ]; then
                G branch -q -f "backup-$STAMP" HEAD   # keeps any commits you made; harmless otherwise
            fi
            G checkout -q -B "$BRANCH" FETCH_HEAD 2>/dev/null || UPDATED=0
        fi
    fi
    if [ "$UPDATED" -eq 1 ]; then
        ok "Course repo updated: $REPO"
    else
        cd "$BASE" || die "Cannot enter $BASE"
        say "Your copy could not be updated in place; downloading a fresh copy..."
        if replace_with_fresh; then
            ok "Fresh copy: $REPO"
        else
            note "Download failed (network?); trying the zip download instead"
            USE_ZIP=1
        fi
    fi
fi

if [ "$USE_ZIP" -eq 1 ]; then
    have curl || die "Neither git nor curl works. Ask a helper for the USB stick."
    # Unpack beside the destination (same drive), so the final move is a rename,
    # not a file-by-file copy that can fail part way.
    TMP="$BASE/.workshop-download-$STAMP"
    mkdir -p "$TMP" || die "Cannot create $TMP"
    curl -fsSL "$ZIP_URL" -o "$TMP/materials.zip" || die "Download failed. Check the Wi-Fi, then run the command again."
    # macOS's unzip cannot create files whose names contain non-ASCII characters
    # (one capstone PDF has a non-breaking space), so prefer Apple's ditto there.
    if [ "$(uname -s)" = "Darwin" ] && have ditto; then
        ditto -x -k "$TMP/materials.zip" "$TMP" || die "Could not unpack the download."
    elif have unzip; then
        unzip -q "$TMP/materials.zip" -d "$TMP" || die "Could not unpack the download."
    else
        die "No unzip tool found. Ask a helper for the USB stick."
    fi
    rm -f "$TMP/materials.zip"
    EXTRACTED=""
    for d in "$TMP"/*/; do [ -d "$d" ] && EXTRACTED="${d%/}" && break; done
    [ -n "$EXTRACTED" ] || die "The download unpacked to nothing."
    REPO="$BASE/claude-code-workshop-zip"
    [ -e "$REPO" ] && mv "$REPO" "$REPO.old-$STAMP"
    mv "$EXTRACTED" "$REPO" || die "Could not move the unpacked materials to $REPO"
    rm -rf "$TMP"
    ok "Materials unpacked to $REPO (zip copy; fix git later with the troubleshooting sheet)"
fi

if [ -d "$REPO/.git" ]; then
    VERSION="$(git -C "$REPO" log -1 --format='%cd  (%h)' --date=format:'%a %d %b %H:%M')"
else
    VERSION="zip download $(date '+%a %d %b %H:%M')"
fi

# ---------------------------------------------------------------------------
# 3-4. Copy today's folders and slides into the workspace
MANIFEST="$REPO/tools/sessions.txt"
FOLDERS=""; SLIDES=""
if [ -f "$MANIFEST" ]; then
    MANIFEST_TEXT="$(cat "$MANIFEST")"
else
    # The copy may be incomplete (e.g. a zip unpacked with errors): fetch just the list.
    MANIFEST_TEXT="$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || true)"
fi
if [ -n "$MANIFEST_TEXT" ]; then
    LINE="$(echo "$MANIFEST_TEXT" | grep -v '^[[:space:]]*#' | tr -d '\r' | awk -F'|' -v s="$SESSION" '{ key = $1; gsub(/ /, "", key) } key == s')"  # never assign to a field: awk would rebuild the line without the | separators
    FOLDERS="$(echo "$LINE" | awk -F'|' '{print $2}')"
    SLIDES="$(echo "$LINE" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')"
fi
if [ -z "$FOLDERS" ]; then
    [ -n "$MANIFEST_TEXT" ] || note "No session list found (tools/sessions.txt); guessing session_$SESSION"
    FOLDERS="session_$SESSION"
    SLIDES="slides/session${SESSION}_slides.pdf"
fi
say "Today's folders: $(echo $FOLDERS | sed 's/ /, /g')"

mkdir -p "$WORKSPACE" || die "Cannot create $WORKSPACE"
for folder in $FOLDERS; do
    if [ -e "$WORKSPACE/$folder" ]; then
        ok "Kept your existing $WORKSPACE/$folder (not overwritten)"
    elif [ -d "$REPO/$folder" ]; then
        cp -R "$REPO/$folder" "$WORKSPACE/$folder" || die "Copy of $folder failed"
        ok "Copied $folder into $WORKSPACE"
    else
        note "$folder is not in the published materials yet; tell the instructor"
    fi
done
if [ -n "$SLIDES" ] && [ -f "$REPO/$SLIDES" ]; then
    mkdir -p "$WORKSPACE/slides"
    cp -f "$REPO/$SLIDES" "$WORKSPACE/slides/" && ok "Slides: $WORKSPACE/slides/$(basename "$SLIDES")"
else
    note "Slides for session $SESSION are not published yet"
fi

# ---------------------------------------------------------------------------
# 5. Open the workspace (the parent folder, so paths like session_1/data/... work)
OPENED="no"
if [ -z "${WORKSHOP_NO_OPEN:-}" ]; then
    if have code; then
        code "$WORKSPACE" && OPENED="yes"
    elif [ "$(uname -s)" = "Darwin" ] && open -Ra "Visual Studio Code" 2>/dev/null; then
        open -a "Visual Studio Code" "$WORKSPACE" && OPENED="yes"
    fi
fi

echo ""
printf "  \033[1m================ READY ================\033[0m\n"
printf "  Materials version: %s\n" "$VERSION"
printf "  Work in:           %s\n" "$WORKSPACE"
if [ "$OPENED" = "yes" ]; then
    printf "  VS Code is opening that folder. Start Claude Code there.\n"
else
    printf "  Open VS Code, then File > Open Folder > %s\n" "$WORKSPACE"
fi
printf "  \033[1m=======================================\033[0m\n\n"
