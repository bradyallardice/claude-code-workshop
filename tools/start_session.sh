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
#   3. Brings today's folders in ~/my_workspace up to date:
#        - a folder you do not have yet is copied in;
#        - a file you have NOT edited is replaced by the instructor's newer version;
#        - a file you HAVE edited is never touched: the newer version is saved beside it
#          as <name>.new, and you decide what to keep;
#        - files you created, and files you deleted, are left alone.
#      (A small record of what was delivered last time is kept in ~/my_workspace/.workshop/.)
#   4. Copies today's slides into ~/my_workspace/slides/ (always the newest version).
#   5. Opens ~/my_workspace in VS Code.
# Work only in ~/my_workspace. The course repo is a disposable mirror that this script resets.
# If git does not work at all, it downloads a zip of the materials instead.
#
# Settings for testing (students never need these):
#   WORKSHOP_GITHUB_REPO  WORKSHOP_REPO_URL  WORKSHOP_BRANCH  WORKSHOP_HOME  WORKSHOP_ZIP_URL  WORKSHOP_NO_OPEN=1

set -u

SESSION="${1:-}"
# ---- Where the public student repo lives. This is the one place in this script to change
# ---- if the repo is renamed or moved (admin/publishing.md lists the other files).
GITHUB_REPO="${WORKSHOP_GITHUB_REPO:-bradyallardice/claude-code-workshop}"
BRANCH="${WORKSHOP_BRANCH:-student}"
REPO_URL="${WORKSHOP_REPO_URL:-https://github.com/$GITHUB_REPO.git}"
ZIP_URL="${WORKSHOP_ZIP_URL:-https://github.com/$GITHUB_REPO/archive/refs/heads/$BRANCH.zip}"
MANIFEST_URL="${WORKSHOP_MANIFEST_URL:-https://raw.githubusercontent.com/$GITHUB_REPO/$BRANCH/tools/sessions.txt}"
BASE="${WORKSHOP_HOME:-$HOME}"
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

# Hash method for the delivery records: git's blob hash of the bytes on disk (no line-ending
# conversion), or plain SHA-1 if git is missing. The method is written into each record, and a
# record made with a different method is ignored (every differing file then gets a .new).
if have git; then HASH_METHOD="git"; elif have shasum || have sha1sum; then HASH_METHOD="sha1"; else HASH_METHOD="none"; fi
STATE_DIR="$WORKSPACE/.workshop"
TAB="$(printf '\t')"
NEW_FILES=""

# hash_list ROOT LISTFILE: prints "<hash><TAB><path>" for each path in LISTFILE (paths relative to ROOT).
hash_list() {
    local root="$1" list="$2" hashes p h
    [ -s "$list" ] || return 0
    case "$HASH_METHOD" in
        git)
            hashes="$list.h"
            ( cd "$root" && git hash-object --no-filters --stdin-paths ) < "$list" > "$hashes"
            paste -d "$TAB" "$hashes" "$list"
            rm -f "$hashes" ;;
        sha1)
            while IFS= read -r p; do
                if have shasum; then h="$(shasum -a 1 < "$root/$p" | cut -d' ' -f1)"; else h="$(sha1sum < "$root/$p" | cut -d' ' -f1)"; fi
                printf '%s\t%s\n' "$h" "$p"
            done < "$list" ;;
        *) : ;;
    esac
}

# update_folder FOLDER: copy it if it is new, otherwise update it without touching the student's work.
update_folder() {
    local folder="$1" up="$REPO/$1" ws="$WORKSPACE/$1" mf="$STATE_DIR/$1.manifest" tmp act p
    local n_add=0 n_upd=0 n_new=0 n_gone=0
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/workshop-upd.XXXXXX")" || die "Cannot create a temporary folder"
    mkdir -p "$(dirname "$mf")"
    ( cd "$REPO" && find "$folder" -type f ! -name '.DS_Store' ) | LC_ALL=C sort > "$tmp/up.list"
    hash_list "$REPO" "$tmp/up.list" > "$tmp/up.hash"

    if [ ! -e "$ws" ]; then
        cp -R "$up" "$ws" || die "Copy of $folder failed"
        { echo "#method=$HASH_METHOD"; cat "$tmp/up.hash"; } > "$mf"
        ok "Copied $folder into $WORKSPACE"
        rm -rf "$tmp"; return 0
    fi

    # Hash the student's copy of every file the instructor has published.
    while IFS= read -r p; do [ -f "$WORKSPACE/$p" ] && printf '%s\n' "$p"; done < "$tmp/up.list" > "$tmp/ws.list"
    hash_list "$WORKSPACE" "$tmp/ws.list" > "$tmp/ws.hash"
    : > "$tmp/old.hash"
    if [ -f "$mf" ] && [ "$(head -n 1 "$mf")" = "#method=$HASH_METHOD" ]; then tail -n +2 "$mf" > "$tmp/old.hash"; fi

    # Decide file by file. old = hash delivered last time, ws = hash in the student's folder now,
    # u = hash of the version published now.
    #   not in your folder, delivered before                -> you deleted it: stays deleted (GONE)
    #   not in your folder, never delivered                 -> new from the instructor (ADD)
    #   same as published                                   -> nothing to do (SAME)
    #   unchanged since delivered, newer one published      -> replace it (UPDATE)
    #   anything else (you edited it, or no record)        -> keep yours, save the new one as .new (NEW)
    # For NEW the record is set to the version just offered, so a student who adopts it (copies the
    # .new over their file) gets silent updates from then on; a student who keeps their own file
    # keeps getting a fresh .new beside it.
    : > "$tmp/new.hash"
    awk -F'\t' -v newmf="$tmp/new.hash" '
        FILENAME == ARGV[1] { old[$2] = $1; next }
        FILENAME == ARGV[2] { ws[$2] = $1; next }
        { u = $1; p = $2
          if (!(p in ws)) {
              if (p in old) { print "GONE\t" p; print old[p] "\t" p >> newmf }
              else          { print "ADD\t" p;  print u "\t" p >> newmf }
          } else if (ws[p] == u)                     { print "SAME\t" p;   print u "\t" p >> newmf }
          else if ((p in old) && old[p] == ws[p])    { print "UPDATE\t" p; print u "\t" p >> newmf }
          else                                       { print "NEW\t" p;    print u "\t" p >> newmf }
        }' "$tmp/old.hash" "$tmp/ws.hash" "$tmp/up.hash" > "$tmp/actions"

    while IFS="$TAB" read -r act p; do
        case "$act" in
            ADD)    mkdir -p "$(dirname "$WORKSPACE/$p")"; cp -f "$REPO/$p" "$WORKSPACE/$p"; n_add=$((n_add + 1)) ;;
            UPDATE) cp -f "$REPO/$p" "$WORKSPACE/$p"; n_upd=$((n_upd + 1)) ;;
            NEW)    cp -f "$REPO/$p" "$WORKSPACE/$p.new"; n_new=$((n_new + 1)); NEW_FILES="${NEW_FILES}    $WORKSPACE/$p.new"$'\n' ;;
            GONE)   n_gone=$((n_gone + 1)) ;;
        esac
    done < "$tmp/actions"
    { echo "#method=$HASH_METHOD"; cat "$tmp/new.hash"; } > "$mf"

    ok "$folder: $n_upd updated, $n_add added, $n_new of your edited files have a newer version (saved as <name>.new)"
    [ "$n_gone" -gt 0 ] && say "($n_gone files you deleted were not restored)"
    rm -rf "$tmp"
    return 0
}

for folder in $FOLDERS; do
    if [ -d "$REPO/$folder" ]; then
        update_folder "$folder"
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
printf "  (Do not edit inside the course repo; it is reset every time you run this.)\n"
if [ -n "$NEW_FILES" ]; then
    printf "\n  The instructor changed files you had already edited. Yours were NOT touched.\n"
    printf "  The newer versions are next to them, ending in .new:\n%s" "$NEW_FILES"
    printf "  Ask Claude Code to compare each pair and tell you what changed.\n\n"
fi
if [ "$OPENED" = "yes" ]; then
    printf "  VS Code is opening that folder. Start Claude Code there.\n"
else
    printf "  Open VS Code, then File > Open Folder > %s\n" "$WORKSPACE"
fi
printf "  \033[1m=======================================\033[0m\n\n"
