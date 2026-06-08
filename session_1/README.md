# Session 1: Introduction to Claude Code

## Start-of-session ritual

From now on, work on a **copy** of each session folder, not inside the shared
course repo. The shared repo stays read-only for you: I can push new material
anytime without breaking your work, and you can edit, break, and redo without
worrying about the shared state. No merge conflicts.

Replace `~/my_workspace` with wherever you keep your local course files.

Today is the first time — do this together, live:

### 1. Get the course repo

**Already cloned (returning students)?**

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

### 2. Make your workspace and copy today's folder into it

Mac/Linux:
```bash
mkdir -p ~/my_workspace
cp -r session_1/ ~/my_workspace/session_1/
```
Windows (PowerShell):
```powershell
New-Item -ItemType Directory -Force ~\my_workspace
Copy-Item -Recurse session_1 ~\my_workspace\session_1
```

### 3. Open your copy in VS Code and work there

Mac/Linux:
```bash
cd ~/my_workspace/session_1 && code .
```
Windows (PowerShell):
```powershell
cd ~\my_workspace\session_1; code .
```

---

## Start here

1. Open `slides/session1_slides.pdf`.
2. Demo: the county-year panel build from `docs/demo_prompt.md`, using the
   election and IPUMS data in `data/`.
3. Exercise: `scripts/exercise_build_panel.py`.
