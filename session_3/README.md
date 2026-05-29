# Session 3: Data Cleaning & Merging Pipelines

## Start-of-session ritual

Same as sessions 1 and 2: work on a **copy** of the session folder, not inside
the shared course repo. The shared repo stays read-only for you, so I can push
new material without breaking your work and you can edit, break, and redo freely.

Replace `~/my_workspace` with wherever you keep your local course files.

### 1. Update the course repo

```bash
cd ~/claude-code-workshop && git pull
```

Don't have the course repo yet?

```bash
git clone https://github.com/bradyallardice/claude-code-workshop.git
```

### 2. Copy today's session folder into your workspace

```bash
cp -r session_3/ ~/my_workspace/session_3/
```

### 3. Open your copy in VS Code and work there

```bash
cd ~/my_workspace/session_3 && code .
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
2. Read `docs/codebook.md` to understand the Swiss franc shock data in `data/`.
3. Exercise: `docs/exercise_prompt.md` (clean and merge the survey and
   demographics data, then run the analysis).
