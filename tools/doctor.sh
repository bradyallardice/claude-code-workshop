#!/usr/bin/env bash
# doctor.sh — workshop setup checker (Mac / Linux / Git Bash).
#
# Checks every tool the workshop needs and prints PASS / WARN / FAIL with the
# fix for each problem. Read-only: it installs nothing and changes nothing.
#
# Run from anywhere:
#   bash ~/claude-code-workshop/tools/doctor.sh
#   bash ~/claude-code-workshop/tools/doctor.sh --quick   # skip the slow MCP check
#
# Screenshot the SUMMARY block at the bottom and send it to the instructor.
# Fix codes (e.g. [F07]) refer to sections in tools/TROUBLESHOOTING.md.
#
# Written for bash 3.2 (the macOS default): no associative arrays.

QUICK=0
[ "$1" = "--quick" ] && QUICK=1

N_PASS=0
N_WARN=0
N_FAIL=0
FAIL_CODES=""

pass() { N_PASS=$((N_PASS + 1)); printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
warn() { N_WARN=$((N_WARN + 1)); printf "  \033[33mWARN\033[0m  %s\n        fix: %s\n" "$1" "$2"; }
fail() {
    N_FAIL=$((N_FAIL + 1))
    FAIL_CODES="$FAIL_CODES $3"
    printf "  \033[31mFAIL\033[0m  %s\n        fix: %s  [%s]\n" "$1" "$2" "$3"
}
section() { printf "\n\033[1m%s\033[0m\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="mac" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows-gitbash" ;;
    *) PLATFORM="linux" ;;
esac

echo "Workshop doctor — $(date '+%Y-%m-%d %H:%M')  platform: $PLATFORM"

# ---------------------------------------------------------------------------
section "1. Folders"
# A space in the home path breaks unquoted paths in some tools and hooks.
case "$HOME" in
    *" "*) warn "Your home folder path contains a space: $HOME" "tell the instructor; hooks need quoted paths [F01]" ;;
    *) pass "Home folder path has no spaces" ;;
esac

COURSE_REPO=""
for candidate in "$HOME/claude-code-workshop" "$HOME/Documents/claude-code-workshop" "$HOME/Desktop/claude-code-workshop"; do
    if [ -d "$candidate/.git" ]; then COURSE_REPO="$candidate"; break; fi
done
if [ -z "$COURSE_REPO" ]; then
    fail "Course repo not found in ~, ~/Documents or ~/Desktop" "run the start-of-session command from github.com/bradyallardice/claude-code-workshop" "F02"
else
    BRANCH="$(git -C "$COURSE_REPO" branch --show-current 2>/dev/null)"
    if [ "$BRANCH" != "student" ]; then
        warn "Course repo is on branch '$BRANCH', expected 'student'" "cd $COURSE_REPO && git checkout student [F02]"
    elif [ -n "$(git -C "$COURSE_REPO" status --porcelain 2>/dev/null)" ]; then
        warn "Course repo has local edits (git pull may refuse)" "work in ~/my_workspace, not the course repo; recovery in [F03]"
    else
        pass "Course repo at $COURSE_REPO (branch student, clean)"
    fi
fi

case "$COURSE_REPO" in
    *OneDrive*|*Dropbox*|*iCloud*|*"Mobile Documents"*)
        warn "Course repo is inside a cloud-synced folder" "sync clients can lock or duplicate files during git operations; move it to ~ [F01]" ;;
esac

# ---------------------------------------------------------------------------
section "2. Git and GitHub"
if have git; then
    pass "git $(git --version | awk '{print $3}')"
    if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
        fail "git user.name / user.email not set (first commit will fail)" "git config --global user.name \"Your Name\"; git config --global user.email \"you@example.com\"" "F04"
    else
        pass "git identity: $(git config --global user.name) <$(git config --global user.email)>"
    fi
    HELPER="$(git config --get credential.helper)"
    if have gh && gh auth status >/dev/null 2>&1; then
        pass "GitHub CLI logged in (git push over HTTPS will work)"
    elif [ -n "$HELPER" ] && [ "$PLATFORM" = "windows-gitbash" ]; then
        pass "git credential helper: $HELPER (Windows browser login)"
    elif [ "$PLATFORM" = "mac" ] && printf "protocol=https\nhost=github.com\n\n" | git credential-osxkeychain get 2>/dev/null | grep -q "^password="; then
        # Only tests that a saved GitHub credential exists; never prints it.
        pass "GitHub credential saved in macOS Keychain"
    else
        warn "No GitHub login for git push (Session 4 and 5 need it)" "install GitHub CLI, then: gh auth login --web --git-protocol https [F05]"
    fi
else
    fail "git not installed" "Mac: run 'git --version' and accept the Xcode tools prompt; Windows: install from git-scm.com" "F04"
fi

# ---------------------------------------------------------------------------
section "3. Claude Code"
if have claude; then
    CLAUDE_VERSION="$(claude --version 2>/dev/null | head -1)"
    pass "claude $CLAUDE_VERSION"
else
    fail "claude command not found" "curl -fsSL https://claude.ai/install.sh | bash   then close and reopen the terminal" "F06"
fi

# ---------------------------------------------------------------------------
section "4. Python"
# Several Pythons on one machine is common, and the first one found is not
# necessarily the one with the packages. Check every interpreter on PATH.
# On Windows, 'python3' can be a Microsoft Store placeholder that does not run.
PROBE='
import sys, importlib
missing = []
for name in ["pandas", "numpy", "statsmodels", "scipy", "linearmodels", "matplotlib", "seaborn", "sklearn", "openpyxl"]:
    try:
        importlib.import_module(name)
    except Exception:
        missing.append("scikit-learn" if name == "sklearn" else name)
print("%d.%d|%s|%s" % (sys.version_info[0], sys.version_info[1], sys.executable, " ".join(missing)))
'
PY_ROWS=""; SEEN=""
for candidate in python3 python py python3.11 python3.12 python3.13 python3.14; do
    have "$candidate" || continue
    ROW="$("$candidate" -c "$PROBE" 2>/dev/null)" || continue
    EXE="$(echo "$ROW" | cut -d'|' -f2)"
    case "$SEEN" in *"|$EXE|"*) continue ;; esac
    SEEN="$SEEN|$EXE|"
    PY_ROWS="$PY_ROWS$candidate|$ROW"$'\n'
done

version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n | head -1)" = "$2" ]; }
PY_VERSION=""; PYTHON=""
if [ -z "$PY_ROWS" ]; then
    fail "No working Python found (tried python3, python, py)" "install Python 3.12 from python.org (Windows: tick 'Add Python to PATH')" "F07"
else
    BEST=""
    while IFS='|' read -r cmd ver exe missing; do
        [ -z "$cmd" ] && continue
        if [ -z "$missing" ] && version_ge "$ver" "3.9"; then BEST="$cmd|$ver|$exe|"; break; fi
    done <<< "$PY_ROWS"
    if [ -n "$BEST" ]; then
        IFS='|' read -r PYTHON PY_VERSION PY_PATH _ <<< "$BEST"
        pass "Python $PY_VERSION has all packages: use '$PYTHON' ($PY_PATH)"
        version_ge "$PY_VERSION" "3.15" && warn "Python $PY_VERSION is very new" "it works now; if a later 'pip install' fails, install Python 3.12 [F07]"
        while IFS='|' read -r cmd ver exe missing; do
            [ -z "$cmd" ] || [ "$exe" = "$PY_PATH" ] && continue
            if [ -n "$missing" ]; then WHY="missing: $missing"; else WHY="too old for the course"; fi
            warn "Another Python on PATH: '$cmd' = $ver ($WHY)" "always use '$PYTHON -m pip install ...'; in VS Code select $PY_PATH [F08]"
        done <<< "$PY_ROWS"
    else
        IFS='|' read -r PYTHON PY_VERSION PY_PATH MISSING_PKGS <<< "$(echo "$PY_ROWS" | head -1)"
        if ! version_ge "$PY_VERSION" "3.9"; then
            fail "Python $PY_VERSION ($PY_PATH) is too old" "install Python 3.12 from python.org" "F07"
        else
            fail "Missing packages for $PY_PATH: $MISSING_PKGS" "$PYTHON -m pip install $MISSING_PKGS" "F08"
            version_ge "$PY_VERSION" "3.15" && warn "Python $PY_VERSION is very new; some packages may not install yet" "if pip fails, install Python 3.12 from python.org [F07]"
        fi
    fi
fi
[ -z "$PYTHON" ] && PYTHON="python3"

# ---------------------------------------------------------------------------
section "5. VS Code"
if have code; then
    pass "'code' command available"
else
    fail "'code' command not on PATH ('code .' will fail)" "in VS Code: Cmd+Shift+P -> 'Shell Command: Install code command in PATH'" "F09"
fi

# ---------------------------------------------------------------------------
section "6. LaTeX"
if have pdflatex; then
    pass "pdflatex found"
    if have latexmk; then
        if latexmk -v >/dev/null 2>&1; then
            pass "latexmk works"
        else
            warn "latexmk is installed but does not run (usually missing Perl on Windows/MiKTeX)" "install Strawberry Perl, or use the pdflatex recipe in LaTeX Workshop [F10]"
        fi
    else
        warn "latexmk not found (LaTeX Workshop's default recipe uses it)" "Mac BasicTeX: sudo tlmgr install latexmk; or use the pdflatex recipe [F10]"
    fi
    if have kpsewhich; then
        MISSING_STY=""
        for sty in booktabs setspace natbib makecell microtype caption geometry hyperref amsmath graphicx; do
            [ -z "$(kpsewhich "$sty.sty" 2>/dev/null)" ] && MISSING_STY="$MISSING_STY $sty"
        done
        if [ -z "$MISSING_STY" ]; then
            pass "LaTeX packages used by the course papers are installed"
        else
            warn "Missing LaTeX packages:$MISSING_STY" "Mac/TeX Live: sudo tlmgr install$MISSING_STY ; MiKTeX installs on first compile [F11]"
        fi
    fi
else
    fail "pdflatex not found" "install MacTeX/BasicTeX (Mac) or TeX Live/MiKTeX (Windows), then log out and back in" "F10"
fi

# ---------------------------------------------------------------------------
section "7. R and Stata (optional)"
if have Rscript; then pass "R $(Rscript -e 'cat(paste(R.version$major, R.version$minor, sep="."))' 2>/dev/null)"; else echo "  ----  R not found (fine unless you use R)"; fi

# ---------------------------------------------------------------------------
section "8. Zotero and MCP servers (Session 4)"
if have zotero-mcp; then
    pass "zotero-mcp command found"
else
    warn "zotero-mcp not on PATH" "$PYTHON -m pip install zotero-mcp-server, then see [F12] if still not found"
fi

if have curl; then
    if curl -s -m 2 http://127.0.0.1:23119/connector/ping 2>/dev/null | grep -q "Zotero is running"; then
        CODE="$(curl -s -m 2 -o /dev/null -w '%{http_code}' 'http://127.0.0.1:23119/api/users/0/items?limit=1')"
        if [ "$CODE" = "200" ]; then
            pass "Zotero desktop running, local API enabled"
        else
            warn "Zotero running but local API is off (HTTP $CODE)" "Zotero Settings -> Advanced -> tick 'Allow other applications on this computer to communicate with Zotero' [F13]"
        fi
    else
        warn "Zotero desktop app is not running" "open Zotero before using the Zotero MCP [F13]"
    fi
fi

if [ "$QUICK" -eq 0 ] && have claude; then
    echo "  ....  checking MCP servers (takes up to ~20 s; use --quick to skip)"
    MCP_OUT="$(cd "$HOME" && claude mcp list 2>&1)"
    for server in github zotero; do
        LINE="$(echo "$MCP_OUT" | grep -i "^$server")"
        if [ -z "$LINE" ]; then
            warn "MCP server '$server' not registered for your user" "re-run the 'claude mcp add --scope user ...' command from the setup guide [F14]"
        elif echo "$LINE" | grep -qi "connected" && ! echo "$LINE" | grep -qi "failed"; then
            pass "MCP server '$server' connected"
        else
            warn "MCP server '$server' registered but not connected: $LINE" "see [F14]"
        fi
    done
fi

# ---------------------------------------------------------------------------
section "9. Node.js (optional; needed only for the claude-ignore demo)"
if have npm; then pass "npm $(npm --version 2>/dev/null)"; else echo "  ----  npm not found (install Node.js LTS if you want to try the claude-ignore demo)"; fi

# ---------------------------------------------------------------------------
printf "\n\033[1m==================== SUMMARY ====================\033[0m\n"
printf "  platform: %s   claude: %s   python: %s\n" "$PLATFORM" "${CLAUDE_VERSION:-none}" "${PY_VERSION:-none}"
printf "  PASS %d   WARN %d   FAIL %d\n" "$N_PASS" "$N_WARN" "$N_FAIL"
if [ "$N_FAIL" -eq 0 ]; then
    printf "  \033[32mREADY\033[0m — screenshot this block and send it to the instructor.\n"
else
    printf "  \033[31mNOT READY\033[0m — fix codes:%s (see tools/TROUBLESHOOTING.md)\n" "$FAIL_CODES"
fi
printf "\033[1m=================================================\033[0m\n"
