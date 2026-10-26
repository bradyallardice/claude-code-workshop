# Troubleshooting

**First, run the checker.** It tells you what is broken and which fix code below applies.

| Mac / Git Bash | Windows PowerShell |
|---|---|
| `bash ~/claude-code-workshop/tools/doctor.sh` | `powershell -ExecutionPolicy Bypass -File $HOME\claude-code-workshop\tools\doctor.ps1` |

**Start of every session:** run the one command at the top of https://github.com/bradyallardice/claude-code-workshop. It fixes most of the problems below on its own (missing or out-of-date course repo, local edits blocking `git pull`, wrong folder opened).

**The 90-second rule.** If a fix here does not work within 90 seconds, put your red sticky note up and keep working with your partner on their laptop. Do not debug alone in silence.

**Universal first move after installing anything:** quit VS Code completely (Mac: Cmd+Q; Windows: close every window) and close every terminal, then reopen. VS Code and terminals only see newly installed programs after a full restart.

---

## Setup problems (codes printed by the checker)

### F01 — Space in your folder path, or repo inside OneDrive / Dropbox / iCloud
Some tools split paths at spaces, and sync clients lock files while git is writing them. Clone the course repo straight into your home folder (`~/claude-code-workshop`), not into Desktop or Documents when those are synced by OneDrive. If your Windows username itself has a space, tell the instructor; the Session 5 hooks have been patched for this, but it is worth knowing.

### F02 — Course repo not found / wrong branch / out of date
Run the start-of-session command from the top of https://github.com/bradyallardice/claude-code-workshop. It downloads the course repo if it is missing and moves it to today's published version whatever branch it is on.

### F03 — `git pull` refuses ("Your local changes would be overwritten")
You edited files inside the course repo. Do not use `git pull`; run the start-of-session command instead. It saves your edits first (`git stash list` and a `backup-<date>` branch inside the course repo), then updates. From now on, work in `~/my_workspace`.

### F04 — git missing, or "Please tell me who you are" on commit
- Mac: run `git --version` and accept the Xcode tools prompt.
- Windows: install from https://git-scm.com/downloads/win with default options.
- Then, once:
```bash
git config --global user.name "Your Name"
git config --global user.email "the-email-you-use-on-github@example.com"
```

### F05 — `git push` asks for a password, or says "Password authentication is not supported"
GitHub no longer accepts your account password for git. Pick one:
- **Fastest in class:** create a token at https://github.com/settings/tokens/new (type: classic, scope: tick `repo`, expiry 30 days). When git asks for your password, paste the token. Mac saves it in the Keychain, so you only do this once.
- **Better long-term:** install the GitHub CLI (Mac: `brew install gh`, or the installer from https://cli.github.com; Windows: `winget install GitHub.cli`), then run `gh auth login --web --git-protocol https` and follow the browser prompt.
- On Windows, Git Credential Manager usually opens a browser login on the first push; just complete it.

### F06 — `claude` not found, or Windows says it cannot find Git Bash
- Mac: `curl -fsSL https://claude.ai/install.sh | bash`, then close and reopen the terminal.
- Windows: in a normal (not Administrator) PowerShell: `irm https://claude.ai/install.ps1 | iex`, then reopen.
- Windows, "Git Bash not found": find `bash.exe` inside your Git install folder, then run (with your actual path) `setx CLAUDE_CODE_GIT_BASH_PATH "C:\Program Files\Git\bin\bash.exe"` and reopen PowerShell and VS Code.

### F07 — No working Python, wrong version, or the Microsoft Store opens
- Install Python 3.12 from https://www.python.org/downloads/. On Windows tick **Add Python to PATH**.
- **Windows: typing `python` opens the Microsoft Store.** Settings → Apps → Advanced app settings → App execution aliases → switch **off** `python.exe` and `python3.exe`. Use `py` in commands.
- **Mac: `pip install` says `externally-managed-environment`.** Your `python3` is Homebrew's, which refuses global installs. Either install Python 3.12 from python.org and use `python3.12 -m pip install ...`, or make a virtual environment:
  ```bash
  python3 -m venv ~/.venvs/workshop
  source ~/.venvs/workshop/bin/activate
  pip install pandas numpy statsmodels scipy linearmodels matplotlib seaborn scikit-learn openpyxl
  ```
  Then in VS Code: Cmd+Shift+P → "Python: Select Interpreter" → pick `~/.venvs/workshop`.

### F08 — "No module named pandas" even though you installed it
You have several Pythons and installed into a different one. Always install through the interpreter you will use:
```bash
python3 -m pip install pandas numpy statsmodels scipy linearmodels matplotlib seaborn scikit-learn openpyxl   # Mac
py -m pip install pandas numpy statsmodels scipy linearmodels matplotlib seaborn scikit-learn openpyxl        # Windows
```
In VS Code, check the interpreter shown in the bottom-right status bar matches the path the checker printed.

### F09 — `code .` says "command not found"
- Mac: open VS Code, press Cmd+Shift+P, run **Shell Command: Install 'code' command in PATH**, reopen the terminal.
- Windows: reinstall VS Code with **Add to PATH** ticked.
- Workaround right now: open VS Code and use File → Open Folder.

### F10 — LaTeX does not compile in VS Code
- `pdflatex` not found after installing: Mac, log out and back in; Windows, restart. Then fully quit and reopen VS Code.
- **Windows + MiKTeX: "latexmk" fails or asks for Perl.** Either install Strawberry Perl (https://strawberryperl.com), or in VS Code open the TeX sidebar → Build LaTeX project → choose the recipe that starts with **pdflatex**.
- Mac BasicTeX: `sudo tlmgr update --self && sudo tlmgr install latexmk`.
- Last resort in class: run `pdflatex -interaction=nonstopmode paper.tex` in the terminal, or compile on Overleaf.

### F11 — "File `makecell.sty` not found" (or another `.sty`)
- Mac / TeX Live: `sudo tlmgr install makecell` (use the package name from the error; the checker lists all missing ones).
- MiKTeX: MiKTeX Console → Settings → "Always install missing packages on-the-fly", then compile again.

### F12 — `zotero-mcp: command not found` after installing
pip put the program in a folder that is not on your PATH. Find it:
```bash
python3 -c "import sysconfig; print(sysconfig.get_path('scripts'))"; python3 -m site --user-base   # Mac (look in <user-base>/bin)
py -c "import sysconfig; print(sysconfig.get_path('scripts'))"                                     # Windows
```
One of those folders contains `zotero-mcp` (`zotero-mcp.exe` on Windows). Re-register the server using the full path:
```bash
claude mcp remove zotero -s user
claude mcp add --scope user zotero -e ZOTERO_LOCAL=true -e ZOTERO_LIBRARY_ID=YOUR_ID -e ZOTERO_API_KEY=YOUR_KEY -e ZOTERO_LIBRARY_TYPE=user -- /full/path/to/zotero-mcp serve
```

### F13 — Zotero MCP returns nothing or errors
1. The Zotero desktop app must be **open**.
2. Zotero → Settings → Advanced → tick **Allow other applications on this computer to communicate with Zotero**.
3. Check the `claude_code_zotero` collection has 9 papers with PDFs. No PDFs means the `.rdf` was imported without its `files/` folder next to it; delete the collection and import again.

### F14 — GitHub MCP: not listed, not connected, or 401 / 403 / "Resource not accessible"
- Not listed in a folder: it was added without `--scope user`. Remove and re-add with `--scope user`.
- **403 when opening a PR on the class repo or your partner's repo:** the fine-grained token from the setup guide cannot write to repos you were *invited* to (a GitHub limitation). Create a **classic** token at https://github.com/settings/tokens/new with the `repo` scope (30-day expiry), then:
  ```bash
  claude mcp remove github -s user
  claude mcp add --scope user --transport http github https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer ghp_YOUR_CLASSIC_TOKEN"
  ```
- Never paste a token into the Claude chat. If you do, revoke it at https://github.com/settings/tokens.

---

## Problems during the sessions

### F15 — `FileNotFoundError: session_1/data/...` (or `session_2/...`, `session_3/...`)
The scripts' paths start from `my_workspace` itself (`session_1/data/...`), so VS Code must have **`my_workspace`** open, not `my_workspace/session_1`. The start-of-session command opens the right folder. If you opened a folder by hand: File → Open Folder → `my_workspace`, then start a new Claude Code session there.

### F16 — Claude says "Credit balance is too low", or asks you to upgrade
"Credit balance" means you logged in with an API (Console) account instead of your Claude subscription. In Claude Code type `/logout`, then `/login`, and choose the Claude account that has Pro or Max. In the VS Code panel, sign out and back in the same way. The free Claude plan does not include Claude Code; work on your partner's laptop today.

### F17 — "Usage limit reached"
Pro plans have a rolling 5-hour limit. Switch to your partner's laptop and keep going. To make your allowance last: `/model sonnet` (not Opus), `/clear` between unrelated tasks, and give one well-specified instruction rather than many small follow-ups.

### F18 — Session 5 capstone: hook errors on Windows
Symptoms: `No such file or directory` mentioning only the first part of your folder path, or `python3: command not found` in hook output.
- Folder path with a space (e.g. OneDrive): make sure your repo has the patched `.claude/settings.json`, where the hook commands quote `"$CLAUDE_PROJECT_DIR/..."`.
- Python: make sure `py --version` or `python --version` works (see F07). The patched hooks find either.
- If you used the repo from WSL or copied scripts to a Mac and see `set: pipefail: invalid option name`: the scripts have Windows line endings. Fix with `sed -i 's/\r$//' .claude/scripts/*.sh`.

### F19 — Capstone README says `rsync` but you are on Windows
From inside your empty team repo:
```bash
cp -R /path/to/claude-code-workshop/session_5/capstone-template/. .                                   # Git Bash or Mac
```
```powershell
Copy-Item -Path "$HOME\claude-code-workshop\session_5\capstone-template\*" -Destination . -Recurse -Force   # PowerShell
```
Check with `ls -a` (or `Get-ChildItem -Force`) that `.claude` and `.claudeignore` arrived.

### F20 — `error: src refspec main does not match any`
Your new repo's branch is called `master`. Rename it, then push: `git branch -M main` and `git push -u origin main`.

### F21 — Push rejected ("fetch first" / "non-fast-forward")
Someone merged before you. `git pull --rebase origin main`, then push again. If it reports a conflict, raise your sticky note.

### F22 — `npm install -g claudeignore` fails with EACCES (Mac)
Skip the global install and run it through npx instead, from your project folder:
`npx --package=claudeignore claude-ignore init`
