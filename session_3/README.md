# Session 3: Verification Through to the Paper

## Start-of-session ritual

Same as sessions 1 and 2: work on a **copy** of the session folder, not inside
the shared course repo. The shared repo stays read-only for you, so I can push
new material without breaking your work and you can edit, break, and redo freely.

Replace `~/my_workspace` with wherever you keep your local course files.

### 1. Update the course repo

**Already cloned?**

Mac/Linux:
```bash
cd ~/claude-code-workshop && git pull
```
Windows (PowerShell):
```powershell
cd ~\claude-code-workshop; git pull
```

**First time?**
```bash
git clone https://github.com/bradyallardice/claude-code-workshop.git
```

### 2. Copy today's session folder into your workspace

Keep your `session_2` copy as it is: Parts 2 and 3 of the Swiss franc exercise
continue in it.

Mac/Linux:
```bash
cp -r session_3/ ~/my_workspace/session_3/
```
Windows (PowerShell):
```powershell
Copy-Item -Recurse session_3 ~\my_workspace\session_3
```

### 3. Open your copy in VS Code and work there

Mac/Linux:
```bash
cd ~/my_workspace/session_3 && code .
```
Windows (PowerShell):
```powershell
cd ~\my_workspace\session_3; code .
```

### If `git pull` fights back

If you committed work inside the course repo, `git pull` will complain. Run this
recovery in the course repo, then continue with steps 2–3:

```bash
git stash -u                      # save uncommitted edits
git branch backup-prework         # save any local commits
git fetch origin
git reset --hard origin/student   # match the server
git stash pop                     # skip if stash was empty
```

Your old commits live on `backup-prework`. If that name already exists, add a
suffix: `backup-prework-2`.

---

## Start here

1. Open `slides/session3_slides.pdf`.
2. Exercise instructions are in `docs/exercise_prompt.md`:
   - **Part 2 (specify and estimate)** and **Part 3 (robustness and a LaTeX
     table)** run in your `my_workspace/session_2` folder.
   - **Results → paper** runs in `results_to_paper/` in this folder. It holds a
     paper skeleton (`paper.tex`), a results file, and a script that renders the
     results as a LaTeX table.
3. `docs/verification_protocol.md` (in this `session_3` folder, not your `session_2` folder) is a reference verification protocol. Open it at the end of Part 3, to compare with the `CLAUDE.md` rules you wrote yourself.
4. `paper/` is the finished course-analysis paper from the live demo, for
   reference. `option_b/` is older practice material that the course no longer
   uses.
