# Instructor Notes — Collaborative Story Exercise

This file is for you, not the students. Delete it (or move it to a private location) before class if you want.

---

## Pre-class setup

### 1. Create the GitHub repo

- Copy the contents of this scaffold folder into a new directory.
- Initialize it as a git repo and push it to GitHub as the class collaboration repo.

```bash
cp -r session_4/github_exercise_scaffold/ ~/class_collab/
cd ~/class_collab
# remove the scaffold's INSTRUCTOR.md from the public repo if you prefer
# rm INSTRUCTOR.md
git init
git add .
git commit -m "Initial scaffold"
gh repo create <org>/class-4-collab --public --source=. --push
```

### 2. Enable branch protection on `main`

In GitHub → Settings → Branches → Add rule:

- Branch name pattern: `main`
- Require a pull request before merging (no reviewer requirement — the exercise is about the workflow, not rigorous review)
- Do **not** require status checks
- Allow force pushes: **no**

This prevents students from accidentally pushing directly to `main`.

### 3. Add students as collaborators

Settings → Collaborators → Add people. Send invites **48+ hours before class** with a reminder to accept in advance. Students who don't accept in time can't push.

For a class of 8–15, this is manageable manually. If you want to scale it later, `gh api` scripts can do bulk invites.

### 4. Fill in [PAIRS.md](PAIRS.md)

Pre-assign pairs and chapter numbers before class. Pair strategically (technical + less technical if you can). Push the filled-in `PAIRS.md` to the repo so students can see their assignment the moment they land on the page.

### 5. Do a dry run

This is the most important prep step.

Create two throwaway GitHub accounts (or use a colleague's) and run the full loop pretending to be each student:

- Clone, branch, edit, commit, push
- Open PR as student A
- Switch accounts, review as student B, merge
- Switch back, pull main, confirm the merge appears

Time yourself. If it takes **you** more than 10 minutes, it will take students longer. Fix the rough edges you hit before students hit them.

---

## During class

### Premise vote (1 min)

Show the three premises on a slide. Let students vote (hands, or a 30-second Slack poll). You choose in the event of a tie.

Announce the winner. Students look up their chapter prompt in `premises/premise_<N>_<name>.md`.

### Writing + PR loop (10–12 min)

Students run the workflow per the student-facing README. You circulate and unblock.

**Common failure modes:**
- **Collaborator invite not accepted.** Have them accept now, it takes 30 seconds.
- **Push rejected (branch out of date).** `git pull --rebase origin main`.
- **PR opened against wrong base.** Fix in UI or close + reopen.
- **Student drafts in `main` accidentally.** Branch protection should block the push; help them create a branch from their work: `git checkout -b chapter-<N>` then `git push -u origin chapter-<N>`.
- **Merge conflict.** If the exercise is running well, this should be rare. Help them resolve or revert.

### Assemble (2 min)

After all PRs are merged, pull and run the assembly script:

```bash
git pull
./assemble.sh
```

This produces `story.md` — the concatenation of all chapters. Read a few lines aloud to the class. The payoff is the reveal: everyone's weird chapters stitched together into one weirder document.

---

## Flexing for headcount

The scaffold ships with **8 chapter files** and each premise has **8 chapter outlines**. Use only as many as you have pairs:

- 8 students → 4 pairs → use chapters 1–4
- 10 students → 5 pairs → use chapters 1–5
- 12 students → 6 pairs → use chapters 1–6
- 14 students → 7 pairs → use chapters 1–7

Chapters are intentionally episodic (each is a standalone scene), so truncating doesn't break anything.

**Odd student out?** Options: make one trio (two drafters, one reviewer, or one drafter with two reviewers), or pair them with you.

---

## After class

If you want to reuse this repo for another cohort: create a fresh repo from the scaffold rather than reusing the old one. PR history and old branches in the same repo will confuse next year's students.
