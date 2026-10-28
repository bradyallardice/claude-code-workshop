# Session 3: Verification Through to the Paper

## Start-of-session ritual

Same one command as every session. It brings the course materials up to date,
updates today's folders in `~/my_workspace` (`session_3`, and your `session_2`, which
today's Parts 2 and 3 continue in), and opens `~/my_workspace` in VS Code.

**Work only in `~/my_workspace`.** The course repo (`~/claude-code-workshop`) is a
read-only mirror that the command resets every time. If you edit inside it, your
edits are saved aside (`git stash list`, and a `backup-<date>` branch), but they do
not belong there.

Copy the line for your computer, change the last number to today's session
(`3` today), and run it.

**Mac** (Terminal):
```bash
curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 3
```

**Windows** (PowerShell, not as Administrator). It asks which session:
```powershell
irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
```

If I fixed something since you last ran it, the command updates your copies without
touching your work. This includes your `session_2` folder, where your merge script,
`expectations.md` and `CLAUDE.md` are:

- a file you have **not** edited is replaced by my newer version;
- a file you **have** edited is never changed: my newer version is saved next to it
  as `<name>.new` and listed in the READY box (ask Claude Code to compare the two);
- files you created, and files you deleted, are left alone.

Check that the **Materials version** in the READY box matches the one on the screen.
If anything fails, see `tools/TROUBLESHOOTING.md`.

### If the command does not work

```bash
cd ~/claude-code-workshop && git fetch origin && git reset --hard origin/student
mkdir -p ~/my_workspace && cp -r session_3/ ~/my_workspace/session_3/    # first time only
cd ~/my_workspace && code .
```
(Windows: `cd ~\claude-code-workshop; git fetch origin; git reset --hard origin/student`, then
`Copy-Item -Recurse session_3 ~\my_workspace\session_3` the first time, then `cd ~\my_workspace; code .`.)
The `reset` discards edits made inside the course repo; your `my_workspace` is not touched.
Do not copy `session_2` again: keep the copy you have.

### Open today's folder

The command opens `my_workspace`. For the `results_to_paper` and Git exercises, open the
`session_3` folder inside it (VS Code: File, Open Folder, `my_workspace/session_3`). Parts 2
and 3 of the Swiss franc exercise continue in your `my_workspace/session_2` folder, in a
new VS Code window.

---

## Start here

1. Open `~/my_workspace/slides/session3_slides.pdf` (copied there by the command above).
2. Exercise instructions are in `docs/exercise_prompt.md`:
   - **Part 2 (specify and estimate)** and **Part 3 (robustness and a LaTeX
     table)** run in your `my_workspace/session_2` folder.
   - **Results → paper** runs in `results_to_paper/` in this folder. It holds a
     paper skeleton (`paper.tex`), a results file, and a script that renders the
     results as a LaTeX table.
3. `docs/verification_protocol.md` (in this `session_3` folder, not your `session_2` folder) is a reference verification protocol. Open it at the end of Part 3, to compare with the `CLAUDE.md` rules you wrote yourself.
4. `paper/` is the finished course-analysis paper from the live demo, for
   reference. The `option_b/` folder is older practice material that the course
   no longer uses; it is unrelated to the "Option 2: practice sandbox" on the git
   slides, which is a copy of your own `session_2` folder.
