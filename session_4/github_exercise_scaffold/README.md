# Collaborative Story — GitHub Workflow Exercise

A short, timed exercise where you'll practice the full GitHub collaboration loop: branch → commit → push → open PR → review → merge.

Each pair writes **one chapter** of a weird, episodic story. One partner drafts; the other reviews and merges. At the end, all chapters are concatenated into one document.

The writing is short on purpose. The point is the Git workflow, not the prose.

---

## Before you start

1. Find your pair and chapter number in [PAIRS.md](PAIRS.md).
2. Check which premise the class voted on. The three candidates are in [premises/](premises/).
3. Look up your chapter's prompt in the winning premise file.

---

## The workflow

Total time: ~15 minutes.

| Step | Who | Time |
|------|-----|------|
| Premise vote | class | 1 min |
| Draft chapter | drafter | 5 min |
| Commit, push, open PR | drafter | 2 min |
| Review and merge | reviewer | 2 min |
| Instructor assembles | instructor | 2 min |

---

## Reference card (drafter)

Replace `<repo-url>`, `<N>`, and `<name>` with your values.

```bash
# 1. Clone the repo (first time only)
git clone <repo-url>
cd <repo-name>

# 2. Make sure main is up to date
git checkout main
git pull

# 3. Create your chapter branch
git checkout -b chapter-<N>

# 4. Edit chapters/chapter_<N>.md in your editor
#    (replace the placeholder text with your chapter)

# 5. Commit and push
git add chapters/chapter_<N>.md
git commit -m "Draft chapter <N>"
git push -u origin chapter-<N>
```

Then open the PR. Either:

- **In GitHub:** click the "Compare & pull request" banner that appears after you push, set base to `main`, title it "Chapter \<N\>", assign your partner as reviewer, submit.
- **With Claude Code + GitHub MCP:**
  ```
  Open a PR from chapter-<N> to main. Title: "Chapter <N>".
  Assign <partner-github-username> as reviewer.
  ```

---

## Reference card (reviewer)

1. You'll get a notification (or link) when your partner opens the PR.
2. Open the PR on GitHub. Click the **Files changed** tab.
3. Skim the chapter. If it reads like a chapter, you're done reviewing.
4. Click **Review changes** → **Approve** → submit.
5. Click **Merge pull request** → **Confirm merge**.

You are not grading. Approve and merge.

---

## A note on the writing

- **Length doesn't matter.** A paragraph is fine. Three sentences is fine.
- **Don't try to match other chapters.** You can't — everyone is writing at the same time. Weird is the point.
- **Don't try to resolve a plot.** Each chapter is a scene, not a story. Leave threads dangling.
- **Don't polish.** Five minutes. Write, push, move on.

---

## If something breaks

- **Push rejected?** Run `git pull --rebase origin main` and try again.
- **Opened PR against the wrong branch?** Edit it in the GitHub UI (change base branch) or close it and open a new one.
- **Merge conflict?** Flag the instructor. Conflicts are not part of this exercise.
- **Stuck for more than 90 seconds?** Flag the instructor. Don't silently spin.
