# Session 1: Introduction to Claude Code

## Start-of-session ritual

From now on, work in **`~/my_workspace`**, on your own copy of each session folder,
and never inside the course repo (`~/claude-code-workshop`). The course repo is a
read-only mirror that the command below resets every time. That is what lets me
push new material or fix a mistake at any time without breaking your work, and lets
you edit, break, and redo freely. No merge conflicts.

Today is the first time. Do this together, live.

### One command

Copy the line for your computer, change the last number to today's session
(`1` today), and run it.

**Mac** (Terminal):
```bash
curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 1
```

**Windows** (PowerShell, not as Administrator). It asks which session:
```powershell
irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
```

It updates the course materials, copies today's folder into `~/my_workspace/session_1`,
copies today's slides into `~/my_workspace/slides/`, and opens `~/my_workspace`
in VS Code. Check that the **Materials version** in the READY box matches the
one on the screen. If anything fails, see `tools/TROUBLESHOOTING.md`.

Run the same command at the start of every session. If I fixed something since you
last ran it, it updates your copy without touching your work:

- a file you have **not** edited is replaced by my newer version;
- a file you **have** edited is never changed: my newer version is saved next to it
  as `<name>.new` and listed in the READY box (ask Claude Code to compare the two);
- files you created, and files you deleted, are left alone.

### If the command does not work

Mac/Linux:
```bash
# First time only:
git clone https://github.com/bradyallardice/claude-code-workshop.git
# Every time:
cd ~/claude-code-workshop && git fetch origin && git reset --hard origin/student
mkdir -p ~/my_workspace
cp -r session_1/ ~/my_workspace/session_1/    # first time only
cd ~/my_workspace && code .
```
Windows (PowerShell):
```powershell
# First time only:
git clone https://github.com/bradyallardice/claude-code-workshop.git
# Every time:
cd ~\claude-code-workshop; git fetch origin; git reset --hard origin/student
New-Item -ItemType Directory -Force ~\my_workspace
Copy-Item -Recurse session_1 ~\my_workspace\session_1    # first time only
cd ~\my_workspace; code .
```
The `reset` discards edits made inside the course repo; your `my_workspace` is not touched.

### Where to run things

Open **`my_workspace`** (the folder that *contains* `session_1/`) in VS Code and
start Claude Code there. The exercise scripts use paths such as
`session_1/data/...` and `session_1/output/`, which only resolve from
`my_workspace`. Do not open or run them from inside `session_1/`.

---

## Start here

1. Open the Session 1 slides: `~/my_workspace/slides/session1_slides.pdf`
   (copied there by the one-command start), or `slides/session1_slides.pdf` in
   the course repo.
2. Setup check: run `claude --version`, then compile `session_1/setup_check.tex`
   (open it in VS Code and click the green Build arrow, or run
   `cd session_1 && latexmk -pdf setup_check.tex`). A PDF with a small table
   should appear.
3. Demo: the county-year panel build from `session_1/docs/demo_prompt.md`, using
   the election and IPUMS data in `session_1/data/`.
4. Exercise 1, your first commands: `session_1/scripts/exercise_build_panel.py`
   (or the `.R` / `.do` version in the same folder). Run it from `my_workspace`.
   The Stata version builds the election panel only (Stata cannot read the
   gzipped IPUMS files); Python and R also merge in the IPUMS demographics.
5. Exercise 2, build a `CLAUDE.md`: done in one of **your own** projects, in a
   new VS Code window, not in this folder.

**Keep your `my_workspace/session_1` copy after today.** Session 2's first
exercise continues in it.
