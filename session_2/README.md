# Session 2: CLAUDE.md & Plan Mode

## Start-of-session ritual

From now on, work on a **copy** of each session folder, not inside the shared
course repo. The shared repo stays read-only for you: I can push new material
anytime without breaking your work, and you can edit, break, and redo without
worrying about the shared state. No merge conflicts.

Replace `[my_workspace]` with wherever you keep your local course files.

Do this at the start of every session.

### 1. Get or update the course repo

If you don't have the course repo yet, clone it:

```bash
git clone https://github.com/bradyallardice/claude-code-workshop.git
```

If you already have it, pull the latest:

```bash
cd ~/claude-code-workshop && git pull
```

### 2. Copy today's session folder into your workspace

```bash
cp -r session_2/ [my_workspace]/session_2/
```

### 3. Copy the slides (choose exactly one)

Option A — you already have `[my_workspace]/slides/`, copy just today's PDF:

```bash
cp slides/session2_slides.pdf [my_workspace]/slides/
```

Option B — you do not have a `slides/` folder yet, copy the whole folder:

```bash
cp -r slides/ [my_workspace]/slides/
```

Do not run both Option A and Option B.

### 4. Open your copy in VS Code and work there

```bash
cd [my_workspace]/session_2 && code .
```

### If `git pull` fights back

If you committed work inside the course repo, `git pull` will complain. Run this
recovery in the course repo, then continue with steps 2–4:

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
2. Follow along with the CLAUDE.md and plan-mode demos.
