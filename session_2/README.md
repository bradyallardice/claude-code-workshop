# Session 2: Context, Parallel Sessions, Plan Mode, and Verification

## Start-of-session ritual

Same one command as every session. It brings the course materials up to date,
updates today's folder in `~/my_workspace`, and opens `~/my_workspace` in VS Code.

**Work only in `~/my_workspace`.** The course repo (`~/claude-code-workshop`) is a
read-only mirror that the command resets every time. If you edit inside it, your
edits are saved aside (`git stash list`, and a `backup-<date>` branch), but they do
not belong there.

Copy the line for your computer, change the last number to today's session
(`2` today), and run it.

**Mac** (Terminal):
```bash
curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 2
```

**Windows** (PowerShell, not as Administrator). It asks which session:
```powershell
irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
```

If I fixed something since you last ran it, the command updates your copy of the
folder without touching your work:

- a file you have **not** edited is replaced by my newer version;
- a file you **have** edited is never changed: my newer version is saved next to it
  as `<name>.new` and listed in the READY box (ask Claude Code to compare the two);
- files you created, and files you deleted, are left alone.

Check that the **Materials version** in the READY box matches the one on the screen.
If anything fails, see `tools/TROUBLESHOOTING.md`.

### If the command does not work

```bash
cd ~/claude-code-workshop && git fetch origin && git reset --hard origin/student
mkdir -p ~/my_workspace && cp -r session_2/ ~/my_workspace/session_2/    # first time only
cd ~/my_workspace && code .
```
(Windows: `cd ~\claude-code-workshop; git fetch origin; git reset --hard origin/student`, then
`Copy-Item -Recurse session_2 ~\my_workspace\session_2` the first time, then `cd ~\my_workspace; code .`.)
The `reset` discards edits made inside the course repo; your `my_workspace` is not touched.

### Open today's folder

The command opens `my_workspace`. For today's exercises, open the `session_2` folder
inside it (VS Code: File, Open Folder, `my_workspace/session_2`) and start Claude Code
there. Today's first exercise runs in `session_2/county_panel`, opened in its own window
(see Start here, step 3).

---

## Start here

1. Open `~/my_workspace/slides/session2_slides.pdf` (copied there by the command above).
2. Demo, follow along: two Claude Code tabs at once in this folder (prompts on
   the slides).
3. Exercise 1, the county panel in plan mode: open the **`county_panel`** folder
   inside this one in a new VS Code window. It is at
   `/Users/<your name>/my_workspace/session_2/county_panel` (Mac) or
   `C:\Users\<your name>\my_workspace\session_2\county_panel` (Windows), and it
   already has a `CLAUDE.md`, the data, and the codebooks (step-by-step on the slides).
4. Exercise 2: Part 1 of `docs/exercise_prompt.md`, in two halves. **1a:** read `docs/codebook.md` to learn the Swiss
   franc shock data in `data/`, write your expectations in `expectations.md` (it's in this folder), have Claude Code
   write and run a merge script in `scripts/`, and check the merge yourself against them. **1b**, after the lecture on tests: turn your expectations into a check script.

**Keep this folder after today.** Parts 2 and 3 of the exercise (estimation,
robustness, and a LaTeX table) are in Session 3, and continue here.
