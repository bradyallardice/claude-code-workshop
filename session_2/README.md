# Session 2: Context, Parallel Sessions, Plan Mode, and Verification

## Start-of-session ritual

Same as session 1: work on a **copy** of the session folder, not inside the
shared course repo. The shared repo stays read-only for you, so I can push new
material without breaking your work and you can edit, break, and redo freely.

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

Mac/Linux:
```bash
cp -r session_2/ ~/my_workspace/session_2/
```
Windows (PowerShell):
```powershell
Copy-Item -Recurse session_2 ~\my_workspace\session_2
```

### 3. Open your copy in VS Code and work there

Mac/Linux:
```bash
cd ~/my_workspace/session_2 && code .
```
Windows (PowerShell):
```powershell
cd ~\my_workspace\session_2; code .
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

1. Open `slides/session2_slides.pdf`.
2. Demo, follow along: two Claude Code tabs at once in this folder (prompts on
   the slides).
3. Exercise 1, the county panel in plan mode: in your **`my_workspace/session_1`**
   copy from last session, opened in a new VS Code window (instructions on the
   slides).
4. Read `docs/codebook.md` to understand the Swiss franc shock data in `data/`.
5. Exercise 2: Part 1 of `docs/exercise_prompt.md`. Learn the data and write
   your expectations in `expectations.md` (it's in this folder) first, then merge and verify against them.

**Keep this folder after today.** Parts 2 and 3 of the exercise (estimation,
robustness, and a LaTeX table) are in Session 3, and continue here.
