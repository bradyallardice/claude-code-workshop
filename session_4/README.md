# Session 4

Start here:

1. Make sure you copied the Session 4 slides into your local course workspace.

Replace `[my_workspace]` with wherever you keep your local course files.

Choose exactly one slide-copy option:

Option A: if you already have `[my_workspace]/slides/`, copy just today's PDF:

```bash
cp slides/session4_slides.pdf [my_workspace]/slides/
```

Option B: if you do not have a slides folder yet, copy the whole folder:

```bash
cp -r slides/ [my_workspace]/slides/
```

Do not run both Option A and Option B.

2. Open `../slides/session4_slides.pdf` from your local Session 4 folder. If you are in the course repo root, open `slides/session4_slides.pdf`.
3. From inside your copy of `session_4`, open `docs/exercise_prompt.md`. It has all four exercises (Zotero literature review, build a skill, literature scan, fan-out coding).

## What is in this folder

| Path | Used for |
|---|---|
| `docs/exercise_prompt.md` | Exercise instructions |
| `data/climate_speeches/` | Corpus and coding scheme for the fan-out exercise |
| `scripts/compare_to_reference.py` | Checks agreement between your agents' codes and the reference codes |
| `agents/referee.md`, `agents/merge-checker.md` | Example subagent definitions shown in the session. Copy one to `.claude/agents/` to use it |
| `capstone-template/` | Self-guided capstone (back matter I of the slides). Not part of the session |
| `option_b/`, `github_collaboration_practice/` | Optional extra material |
