#!/usr/bin/env bash
# setup.sh - do the pre-course setup in one command (Mac).
#
# Students run (Windows students use tools/setup.ps1):
#   curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/setup.sh | bash
# To also install the big programs (VS Code, Python, R, TeX, Zotero) when they are missing:
#   curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/setup.sh | bash -s -- --full
# To see what it would do without changing anything, add --dry-run (can be combined with --full).
#
# Safe to run again: every step first checks whether the thing is already there.
#
# Default (light) mode, in order:
#   1. Git and your git name/email          (asks for the name/email if they are not set)
#   2. VS Code extensions: Python, R, Claude Code, LaTeX Workshop   (if VS Code is installed)
#   3. Claude Code command-line tool        (installs it if missing, then updates it)
#   4. The course materials                 (runs the start-of-session command for session 1)
#   5. Python packages, and the Zotero MCP package
#   6. R packages                           (only if R is installed)
#   7. GitHub and Zotero MCPs               (asks you to paste the two keys; Enter skips)
#   8. The course checker (doctor.sh), a compile test of setup_check.tex, and a summary table
# --full mode also INSTALLS what is missing among: Xcode command line tools, VS Code, Python 3.12,
#   R, BasicTeX, Zotero. It installs Homebrew first if it is needed (and asks before doing so).
#   It needs your Mac password (sudo) for Python, R and TeX, and takes 20 to 40 minutes.
#
# What no script can do for you (printed at the end): sign in to Claude, create the GitHub account,
# create the two keys, enable Zotero's local connection, import the practice library.
#
# Settings for testing (students never need these):
#   WORKSHOP_GITHUB_REPO  WORKSHOP_BRANCH  WORKSHOP_HOME  WORKSHOP_SETUP_SESSION  WORKSHOP_NO_TTY=1
#
# Written for bash 3.2 (the macOS default): no associative arrays, no ${var,,}.

set -u

FULL=0; DRY=0; ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --full) FULL=1 ;;
        --dry-run) DRY=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,31p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg  (use --full, --dry-run, --yes)"; exit 2 ;;
    esac
done

GITHUB_REPO="${WORKSHOP_GITHUB_REPO:-bradyallardice/claude-code-workshop}"
BRANCH="${WORKSHOP_BRANCH:-student}"
RAW="https://raw.githubusercontent.com/$GITHUB_REPO/$BRANCH"
SESSION_TO_FETCH="${WORKSHOP_SETUP_SESSION:-1}"
BASE="${WORKSHOP_HOME:-$HOME}"
WORKSPACE="$BASE/my_workspace"

PY_FULL_VERSION="3.12.10"   # python.org installer used by --full (same installer the guide points to)
PY_FRAMEWORK_BIN="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
PIP_PACKAGES="pandas numpy statsmodels scipy linearmodels matplotlib seaborn scikit-learn openpyxl"
VSCODE_EXTENSIONS="ms-python.python REditorSupport.r anthropic.claude-code James-Yu.latex-workshop"
TLMGR_PACKAGES="latexmk collection-fontsrecommended booktabs makecell geometry setspace float caption lm"
R_PACKAGES='"readr", "dplyr", "tidyr", "ggplot2", "MASS"'

# ---------------------------------------------------------------------------
# Output helpers. Every step ends in exactly one record(): OK (already fine), DONE (did it now),
# MANUAL (you must do it), SKIPPED (declined or nothing to ask), FAIL (tried and it did not work).
RESULTS=""; N_FAIL=0
say()  { printf "  %s\n" "$1"; }
head_() { printf "\n\033[1m%s\033[0m\n" "$1"; }
record() {
    [ "$DRY" -eq 1 ] && [ "$1" = "DONE" ] && set -- WOULD "$2" "$3"   # a dry run never claims to have done anything
    RESULTS="${RESULTS}$1|$2|$3"$'\n'
    case "$1" in
        WOULD)   printf "  \033[36mWOULD\033[0m   %s\n" "$2" ;;
        OK)      printf "  \033[32mOK\033[0m      %s\n" "$2" ;;
        DONE)    printf "  \033[32mDONE\033[0m    %s\n" "$2" ;;
        MANUAL)  printf "  \033[33mMANUAL\033[0m  %s\n" "$2" ;;
        SKIPPED) printf "  \033[33mSKIPPED\033[0m %s\n" "$2" ;;
        FAIL)    N_FAIL=$((N_FAIL + 1)); printf "  \033[31mFAIL\033[0m    %s\n" "$2" ;;
    esac
    [ -n "$3" ] && printf "          %s\n" "$3"
    return 0
}
have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or only print it in --dry-run. Never hides a failure: the caller checks $?.
run() {
    if [ "$DRY" -eq 1 ]; then printf "  [dry-run] %s\n" "$*"; return 0; fi
    "$@"
}

# Prompts must read /dev/tty: when this script is piped from curl, stdin is the script itself.
TTY_OK=0
if [ -z "${WORKSHOP_NO_TTY:-}" ] && ( : </dev/tty ) 2>/dev/null; then TTY_OK=1; fi
REPLY=""
ask() {          # ask "prompt"  -> sets REPLY; returns 1 when no terminal (or dry run)
    REPLY=""
    if [ "$DRY" -eq 1 ]; then printf "  [dry-run] would ask: %s\n" "$1"; return 1; fi
    [ "$TTY_OK" -eq 1 ] || return 1
    printf "  %s " "$1" >/dev/tty
    IFS= read -r REPLY </dev/tty
}
ask_secret() {   # same, but nothing is shown while typing or pasting
    REPLY=""
    if [ "$DRY" -eq 1 ]; then printf "  [dry-run] would ask (hidden): %s\n" "$1"; return 1; fi
    [ "$TTY_OK" -eq 1 ] || return 1
    printf "  %s " "$1" >/dev/tty
    IFS= read -r -s REPLY </dev/tty
    printf "\n" >/dev/tty
}
confirm() {      # confirm "question"  -> 0 for yes
    [ "$ASSUME_YES" -eq 1 ] && return 0
    ask "$1 [y/N]" || return 1
    case "$REPLY" in y|Y|yes|Yes|YES) return 0 ;; esac
    return 1
}

ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n | head -1)" = "$2" ]; }   # $1 >= $2

# ---------------------------------------------------------------------------
if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for a Mac. On Windows, use tools/setup.ps1 (see the README on GitHub)."
    exit 2
fi
# Programs these installers add are not on this shell's PATH yet; add the usual places at the END,
# so a student's own PATH order (and therefore which python3 they get) is not changed.
export PATH="$PATH:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/Library/TeX/texbin:/Library/Frameworks/Python.framework/Versions/3.12/bin"

echo ""
printf "\033[1mWorkshop setup\033[0m  (%s mode%s)\n" "$([ "$FULL" -eq 1 ] && echo full || echo light)" "$([ "$DRY" -eq 1 ] && echo ", DRY RUN: nothing will be changed")"
[ "$TTY_OK" -eq 1 ] || say "No terminal for questions: steps that need typing will be listed under MANUAL."
[ "$FULL" -eq 1 ] && say "Full mode may ask for your Mac password and can take 20 to 40 minutes. You can stop with Ctrl+C and rerun later."

# Homebrew is only installed when a --full step needs it, and only after asking.
HAVE_BREW=0
ensure_brew() {
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
    if have brew; then HAVE_BREW=1; return 0; fi
    say "Homebrew (a Mac package installer) is needed for this step and is not installed."
    if confirm "Install Homebrew now? It asks for your Mac password."; then
        if [ "$DRY" -eq 1 ]; then say "[dry-run] would run the official Homebrew installer"; return 1; fi
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
        have brew && { HAVE_BREW=1; return 0; }
    fi
    return 1
}

# ---------------------------------------------------------------------------
head_ "1. Git"
# /usr/bin/git on a Mac without the Xcode command line tools is a stub that pops up an installer.
GIT_OK=0
if xcode-select -p >/dev/null 2>&1 || { have git && [ "$(command -v git)" != "/usr/bin/git" ]; }; then
    GIT_OK=1; record OK "git $(git --version | awk '{print $3}')" ""
elif [ "$FULL" -eq 1 ]; then
    say "Installing the Xcode command line tools (a window will open: click Install and wait)."
    run xcode-select --install >/dev/null 2>&1
    if [ "$DRY" -eq 0 ]; then
        waited=0
        until xcode-select -p >/dev/null 2>&1 || [ "$waited" -ge 1800 ]; do sleep 10; waited=$((waited + 10)); done
    fi
    if [ "$DRY" -eq 1 ] || xcode-select -p >/dev/null 2>&1; then GIT_OK=1; record DONE "Xcode command line tools (git)" ""
    else record FAIL "Xcode command line tools did not finish installing" "Run 'xcode-select --install' yourself, wait for it to finish, then run this command again."; fi
else
    record MANUAL "git is not installed" "Type 'git --version' in Terminal and click Install in the window that opens, wait, then run this command again."
fi

if [ "$GIT_OK" -eq 1 ]; then
    GN="$(git config --global user.name 2>/dev/null)"; GE="$(git config --global user.email 2>/dev/null)"
    if [ -n "$GN" ] && [ -n "$GE" ]; then
        record OK "git identity: $GN <$GE>" ""
    else
        if ask "Your full name (as you want it on commits):" && [ -n "$REPLY" ]; then GN="$REPLY"; fi
        if ask "The email you used for GitHub (create the account at github.com first if you have none):" && [ -n "$REPLY" ]; then GE="$REPLY"; fi
        case "$GE" in *@*.*) EMAIL_SHAPED=1 ;; *) EMAIL_SHAPED=0 ;; esac
        if [ -n "$GN" ] && [ "$EMAIL_SHAPED" -eq 1 ]; then
            run git config --global user.name "$GN" && run git config --global user.email "$GE" \
                && record DONE "git identity: $GN <$GE>" "" || record FAIL "could not write git config" ""
        else
            record MANUAL "git name/email not set" "Run: git config --global user.name \"Your Name\"   and   git config --global user.email \"you@example.com\""
        fi
    fi
fi

# ---------------------------------------------------------------------------
head_ "2. VS Code and its extensions"
CODE_BIN=""
if have code; then CODE_BIN="code"
elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; fi
if [ -z "$CODE_BIN" ] && [ "$FULL" -eq 1 ]; then
    if ensure_brew && run brew install --cask visual-studio-code; then
        [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ] && CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        [ "$DRY" -eq 1 ] && CODE_BIN="code"
        record DONE "VS Code installed" ""
    else
        record FAIL "VS Code did not install" "Download it from https://code.visualstudio.com and rerun."
    fi
elif [ -z "$CODE_BIN" ]; then
    record MANUAL "VS Code is not installed" "Download it from https://code.visualstudio.com, open it once, then run this command again."
else
    record OK "VS Code found" ""
fi
if [ -n "$CODE_BIN" ]; then
    INSTALLED_EXT="$("$CODE_BIN" --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')"
    for ext in $VSCODE_EXTENSIONS; do
        lower="$(echo "$ext" | tr 'A-Z' 'a-z')"
        if echo "$INSTALLED_EXT" | grep -qx "$lower"; then record OK "extension $ext" ""
        elif run "$CODE_BIN" --install-extension "$ext" >/dev/null 2>&1; then record DONE "extension $ext installed" ""
        else record FAIL "extension $ext did not install" "In VS Code: Extensions (Cmd+Shift+X), search for it, Install."; fi
    done
fi

# ---------------------------------------------------------------------------
head_ "3. Claude Code (command line)"
if have claude; then
    record OK "claude $(claude --version 2>/dev/null | head -1)" ""
else
    say "Installing Claude Code..."
    if [ "$DRY" -eq 1 ]; then say "[dry-run] curl -fsSL https://claude.ai/install.sh | bash"
    else curl -fsSL https://claude.ai/install.sh | bash
    fi
    if have claude || [ "$DRY" -eq 1 ]; then record DONE "Claude Code installed" ""
    else record FAIL "Claude Code did not install" "Run: curl -fsSL https://claude.ai/install.sh | bash   then close and reopen Terminal."; fi
fi
if have claude; then
    run claude update >/dev/null 2>&1 || say "(claude update did not finish; not fatal)"
    CV="$(claude --version 2>/dev/null | head -1 | awk '{print $1}')"
    if [ -n "$CV" ] && ver_ge "$(echo "$CV" | cut -d. -f1-2)" "2.1"; then record OK "Claude Code version $CV is new enough (2.1 or newer is needed for the MCP commands)" ""
    else record FAIL "Claude Code version '$CV' is older than 2.1" "Run: claude update"; fi
fi
record MANUAL "Sign in to Claude (needs your Claude Pro or Max account)" "In Terminal run: claude   then follow the browser prompts and type /exit. Also sign in inside VS Code (Claude Code panel)."

# ---------------------------------------------------------------------------
head_ "4. Course materials"
# Same command students run every session (it falls back to a zip download if git is missing).
# NO_OPEN: VS Code is opened by hand at the end.
if [ "$DRY" -eq 1 ]; then
    say "[dry-run] curl -fsSL $RAW/tools/start_session.sh | bash -s -- $SESSION_TO_FETCH"
    record DONE "course materials (session $SESSION_TO_FETCH)" ""
elif curl -fsSL "$RAW/tools/start_session.sh" | WORKSHOP_NO_OPEN=1 bash -s -- "$SESSION_TO_FETCH"; then
    record DONE "course materials copied to $WORKSPACE" "Session $SESSION_TO_FETCH folder and slides are in my_workspace. Run the start-of-session command at the start of every session."
else
    record FAIL "start-of-session command failed" "Copy the screen above and email it to the instructor."
fi

# ---------------------------------------------------------------------------
head_ "5. Python and packages"
PY=""; PY_VER=""
find_python() {
    for cand in "$PY_FRAMEWORK_BIN" python3 python3.13 python3.12 python3.11 python3.10 python3.9 python; do
        case "$cand" in
            /*) [ -x "$cand" ] || continue; p="$cand" ;;
            *) have "$cand" || continue; p="$(command -v "$cand")"
               # /usr/bin/python3 without the command line tools is the installer stub: do not run it
               [ "$p" = "/usr/bin/python3" ] && ! xcode-select -p >/dev/null 2>&1 && continue ;;
        esac
        v="$("$p" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)" || continue
        if ver_ge "$v" "3.9"; then PY="$p"; PY_VER="$v"; return 0; fi
    done
    return 1
}
if ! find_python && [ "$FULL" -eq 1 ]; then
    PKG="/tmp/python-$PY_FULL_VERSION-macos11.pkg"
    say "Downloading Python $PY_FULL_VERSION from python.org (46 MB), then installing it (asks for your Mac password)."
    if [ "$DRY" -eq 1 ]; then say "[dry-run] curl -fsSL -o $PKG https://www.python.org/ftp/python/$PY_FULL_VERSION/python-$PY_FULL_VERSION-macos11.pkg && sudo installer -pkg $PKG -target /"; PY="python3"; PY_VER="3.12"
    elif curl -fsSL -o "$PKG" "https://www.python.org/ftp/python/$PY_FULL_VERSION/python-$PY_FULL_VERSION-macos11.pkg" && sudo installer -pkg "$PKG" -target / >/dev/null; then
        rm -f "$PKG"; find_python && record DONE "Python $PY_VER installed ($PY)" ""
    else
        rm -f "$PKG"; record FAIL "Python did not install" "Download Python 3.12 from https://www.python.org/downloads/ and run its installer."
    fi
elif [ -z "$PY" ]; then
    record MANUAL "No Python 3.9 or newer found" "Install Python 3.12 from https://www.python.org/downloads/ (or rerun this command with --full), then run this command again."
else
    record OK "Python $PY_VER ($PY)" ""
fi

if [ -n "$PY" ]; then
    MISSING=""
    for spec in pandas:pandas numpy:numpy statsmodels:statsmodels scipy:scipy linearmodels:linearmodels matplotlib:matplotlib seaborn:seaborn sklearn:scikit-learn openpyxl:openpyxl; do
        mod="${spec%%:*}"; pipname="${spec##*:}"
        [ "$DRY" -eq 1 ] || "$PY" -c "import $mod" >/dev/null 2>&1 || MISSING="$MISSING $pipname"
    done
    [ "$DRY" -eq 1 ] && MISSING=" $PIP_PACKAGES"
    "$PY" -m pip show zotero-mcp-server >/dev/null 2>&1 || MISSING="$MISSING zotero-mcp-server"
    if [ -z "$MISSING" ]; then
        record OK "all Python packages already installed" ""
    elif [ "$DRY" -eq 0 ] && "$PY" -c 'import sysconfig, os, sys; sys.exit(0 if os.path.exists(os.path.join(sysconfig.get_path("stdlib"), "EXTERNALLY-MANAGED")) else 1)' 2>/dev/null; then
        record MANUAL "This Python ($PY) refuses global pip installs (it is marked 'externally managed', typical of Homebrew's Python)" \
            "Use the python.org Python instead (rerun with --full), or ask the instructor. Missing:$MISSING"
    else
        say "Installing Python packages (a few minutes):$MISSING"
        # shellcheck disable=SC2086
        if run "$PY" -m pip install --disable-pip-version-check $MISSING; then record DONE "Python packages installed:$MISSING" ""
        else record FAIL "pip install failed for:$MISSING" "Read the error above. Fix is usually: $PY -m pip install$MISSING"; fi
    fi
fi

# ---------------------------------------------------------------------------
head_ "6. R (optional: only if you will use the R exercises)"
if ! have Rscript && [ "$FULL" -eq 1 ]; then
    if ensure_brew && run brew install --cask r; then record DONE "R installed" ""; else record FAIL "R did not install" "Download it from https://cran.r-project.org"; fi
fi
if have Rscript; then
    if [ "$DRY" -eq 1 ]; then say "[dry-run] Rscript -e install.packages(c($R_PACKAGES))"; record DONE "R packages (missing ones)" ""
    elif Rscript -e "dir.create(Sys.getenv('R_LIBS_USER'), recursive=TRUE, showWarnings=FALSE); .libPaths(Sys.getenv('R_LIBS_USER')); need <- setdiff(c($R_PACKAGES), rownames(installed.packages())); if (length(need)) install.packages(need, lib=Sys.getenv('R_LIBS_USER'), repos='https://cloud.r-project.org')"; then
        record OK "R and its packages (readr, dplyr, tidyr, ggplot2, MASS)" ""
    else record FAIL "R packages did not install" "Open R and run: install.packages(c($R_PACKAGES))"; fi
else
    record SKIPPED "R not installed" "Only needed for R exercises. https://cran.r-project.org, or rerun with --full."
fi
record MANUAL "Stata users only: install two packages inside Stata" "ssc install estout   and   ssc install outreg2   (needs your own Stata licence)"

# ---------------------------------------------------------------------------
head_ "7. LaTeX (needed for Session 3)"
if have pdflatex; then record OK "pdflatex found" ""
elif [ "$FULL" -eq 1 ]; then
    say "Installing BasicTeX (about 100 MB) and the packages the course uses. Asks for your Mac password."
    if ensure_brew && run brew install --cask basictex; then
        export PATH="/Library/TeX/texbin:$PATH"
        # shellcheck disable=SC2086
        if run sudo tlmgr update --self && run sudo tlmgr install $TLMGR_PACKAGES; then record DONE "BasicTeX and course LaTeX packages" "Close and reopen Terminal so pdflatex is on your PATH everywhere."
        else record FAIL "BasicTeX installed but tlmgr failed" "Run: sudo tlmgr update --self && sudo tlmgr install $TLMGR_PACKAGES"; fi
    else record FAIL "BasicTeX did not install" "Download MacTeX or BasicTeX from https://www.tug.org/mactex/"; fi
else
    record MANUAL "No LaTeX installed (largest download: BasicTeX about 100 MB, MacTeX about 4 GB)" "Install from https://www.tug.org/mactex/ the day before, or rerun this command with --full."
fi
if have latexmk && [ -f "$WORKSPACE/session_1/setup_check.tex" ] && [ "$DRY" -eq 0 ]; then
    if (cd "$WORKSPACE/session_1" && latexmk -pdf -interaction=nonstopmode -halt-on-error setup_check.tex >/dev/null 2>&1); then
        record OK "setup_check.tex compiled to a PDF (LaTeX works)" ""
    else record FAIL "setup_check.tex did not compile" "See the LaTeX entries in tools/TROUBLESHOOTING.md (usually a missing package: sudo tlmgr install makecell)."; fi
fi

# ---------------------------------------------------------------------------
head_ "8. Zotero (needed for Session 4)"
if [ -d "/Applications/Zotero.app" ]; then record OK "Zotero app found" ""
elif [ "$FULL" -eq 1 ]; then
    if ensure_brew && run brew install --cask zotero; then record DONE "Zotero app installed" ""; else record FAIL "Zotero did not install" "Download it from https://www.zotero.org/download/"; fi
else
    record MANUAL "Zotero app not installed" "Download it from https://www.zotero.org/download/ (or rerun with --full)."
fi
record MANUAL "Zotero: sign in, then Settings > Advanced > tick 'Allow other applications on this computer to communicate with Zotero'" ""
record MANUAL "Zotero: File > Import the practice library" "Choose $HOME/claude-code-workshop/session_4/docs/claude_code_zotero/claude_code_zotero.rdf (keep the files/ folder next to it; tick 'Copy files to the Zotero storage folder')."

# ---------------------------------------------------------------------------
head_ "9. GitHub and Zotero MCPs (Session 4)"
if ! have claude; then
    record MANUAL "MCPs skipped: Claude Code is not installed yet" "Rerun this command once it is."
else
    # GitHub
    if claude mcp get github >/dev/null 2>&1; then record OK "GitHub MCP already configured" ""
    else
        say "GitHub token: create one at https://github.com/settings/tokens?type=beta (name claude-code-workshop, 90 days,"
        say "  Repository permissions: Read and write on Contents, Issues, Pull requests). Treat it like a password."
        if ask_secret "Paste the token here (nothing is shown; press Enter to skip):" && [ -n "$REPLY" ]; then
            GH_TOKEN_VALUE="$REPLY"
            if run claude mcp add --scope user --transport http github https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer $GH_TOKEN_VALUE" >/dev/null 2>&1; then record DONE "GitHub MCP added (user scope)" ""
            else record FAIL "claude mcp add github failed" "Run it by hand using the command in Step 8b of the setup guide."; fi
            GH_TOKEN_VALUE=""
        else record MANUAL "GitHub MCP not set up (no token entered)" "Needed for Session 4. Step 8 of the setup guide, or rerun this command with a token ready."; fi
    fi
    # Zotero
    if claude mcp get zotero >/dev/null 2>&1; then record OK "Zotero MCP already configured" ""
    else
        say "Zotero keys: your Library ID and a key from https://www.zotero.org/settings/keys (name claude-code-workshop, allow library access)."
        if ask "Zotero Library ID (a number; press Enter to skip):" && [ -n "$REPLY" ]; then
            ZLIB="$REPLY"
            if ask_secret "Zotero API key (nothing is shown):" && [ -n "$REPLY" ]; then
                ZKEY="$REPLY"
                if run claude mcp add --scope user zotero -e ZOTERO_LOCAL=true -e "ZOTERO_LIBRARY_ID=$ZLIB" -e "ZOTERO_API_KEY=$ZKEY" -e ZOTERO_LIBRARY_TYPE=user -- zotero-mcp serve >/dev/null 2>&1; then record DONE "Zotero MCP added (user scope)" ""
                else record FAIL "claude mcp add zotero failed" "Run it by hand using the command in Step 9e of the setup guide."; fi
                ZKEY=""
            else record MANUAL "Zotero MCP not set up (no key entered)" "Needed for Session 4. Step 9 of the setup guide."; fi
        else record MANUAL "Zotero MCP not set up (no Library ID entered)" "Needed for Session 4. Step 9 of the setup guide."; fi
    fi
fi
record MANUAL "Email the instructor your GitHub username (not your email address)" "So you can be added to the Session 4 class repository."

# ---------------------------------------------------------------------------
head_ "10. Checker"
DOCTOR=""
for cand in "$BASE/claude-code-workshop" "$BASE/Documents/claude-code-workshop" "$BASE/Desktop/claude-code-workshop"; do
    [ -f "$cand/tools/doctor.sh" ] && { DOCTOR="$cand/tools/doctor.sh"; break; }
done
if [ -n "$DOCTOR" ] && [ "$DRY" -eq 0 ]; then bash "$DOCTOR" --quick || true
elif [ "$DRY" -eq 1 ]; then say "[dry-run] would run doctor.sh from the course repo"
else record FAIL "doctor.sh not found: the course materials were not downloaded" "Rerun this command; if it fails again, email the screen to the instructor."; fi

# ---------------------------------------------------------------------------
echo ""
printf "\033[1m================ SETUP SUMMARY ================\033[0m\n"
printf "%s" "$RESULTS" | while IFS='|' read -r status label detail; do
    [ -z "$status" ] && continue
    case "$status" in
        OK|DONE) c="32" ;; FAIL) c="31" ;; WOULD) c="36" ;; *) c="33" ;;
    esac
    printf "  \033[%sm%-8s\033[0m %s\n" "$c" "$status" "$label"
done
echo ""
if [ "$N_FAIL" -gt 0 ]; then
    echo "  $N_FAIL step(s) FAILED. Screenshot this summary and the red lines above, and email them to the instructor."
else
    echo "  No failures. Anything marked MANUAL needs you (details are printed above)."
fi
echo "  Open VS Code on $WORKSPACE and start Claude Code there."
echo "  Run the start-of-session command (github.com/$GITHUB_REPO) at the start of every session."
printf "\033[1m===============================================\033[0m\n"
[ "$N_FAIL" -eq 0 ]
