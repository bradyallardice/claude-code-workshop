# Session 1: Introduction to Claude Code

## Start-of-session ritual

From now on, work on a **copy** of each session folder, not inside the shared
course repo. The shared repo stays read-only for you: I can push new material
anytime without breaking your work, and you can edit, break, and redo without
worrying about the shared state. No merge conflicts.

Replace `~/my_workspace` with wherever you keep your local course files.

Today is the first time — do this together, live:

### 1. Get the course repo (first time: clone it)

```bash
git clone https://github.com/bradyallardice/claude-code-workshop.git
cd claude-code-workshop
```

Already have the repo from pre-work? Run `git pull` inside it instead of cloning.

### 2. Make your workspace and copy today's folder into it

```bash
mkdir -p ~/my_workspace
cp -r session_1/ ~/my_workspace/session_1/
```

### 3. Open your copy in VS Code and work there

```bash
cd ~/my_workspace/session_1 && code .
```

---

## Start here

1. Open `slides/session1_slides.pdf`.
2. Demo: the county-year panel build from `docs/demo_prompt.md`, using the
   election and IPUMS data in `data/`.
3. Exercise: `scripts/exercise_build_panel.py`.
