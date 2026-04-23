# Collaborative Story — GitHub Workflow Exercise

A short, timed exercise where you'll practice the full GitHub collaboration loop: branch → commit → push → open PR → merge.

Each of you writes **one chapter** of an episodic story. You run the whole loop yourself — draft it, push it, open a PR, approve and merge it. At the end, all chapters are concatenated into one document.

The writing is short on purpose. The point is the Git workflow, not the prose.

---

## Before you start

1. Find your name in [CHAPTERS.md](CHAPTERS.md). The chapter number next to it is yours.
2. Read the story premise and cast of named characters (pushed to `main` before the exercise).
3. Your chapter should feature at least one of the named characters.

---

## The workflow

Total time: ~15 minutes.

| Step | Time |
|------|------|
| Look up your chapter number | — |
| Clone, branch, draft | 5–7 min |
| Commit, push, open + merge PR | 3–4 min |
| Instructor assembles | 2 min |

---

## Reference card

Replace `<N>` with your two-digit chapter number (zero-padded: `01`, `02`, … `16`).

```bash
# 1. Clone the repo (first time only)
git clone <repo-url>
cd <repo-name>
code .                            # open in VS Code

# 2. Create your chapter branch
git checkout -b chapter-<N>

# 3. Edit chapters/chapter_<N>.md in your editor
#    (replace the placeholder comment with your chapter)

# 4. Commit and push
git add chapters/chapter_<N>.md
git commit -m "Chapter <N>"
git push -u origin chapter-<N>
```

Then open and merge the PR on GitHub:

1. Click the **Compare & pull request** banner that appears after you push.
2. Title it `Chapter <N>`. Base = `main`. **Create pull request**.
3. **Merge pull request** → **Confirm merge**.

---

## A note on the writing

- **Length doesn't matter.** A paragraph is fine. Three sentences is fine.
- **Feature at least one named character.** Beyond that, go wherever it takes you.
- **Don't try to match other chapters.** You can't — everyone is writing simultaneously.
- **Don't polish.** Five minutes. Write, push, merge, move on.

---

## If something breaks

- **Push rejected?** Run `git pull --rebase origin main` and try again.
- **Opened PR against the wrong base?** Edit it in the GitHub UI (change base branch) or close it and open a new one.
- **Merge conflict?** Flag the instructor.
- **Stuck for more than 90 seconds?** Flag the instructor. Don't silently spin.
