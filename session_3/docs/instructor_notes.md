# Session 3 — Instructor Notes & Timing

**Verification through to the paper. Target: 2:00, no break.**
Deck: `slides/session3_slides.tex`. Structure and clock come from
`admin/course_plan_4_sessions.md` (blocks 23–29); the comment banners in the deck
carry the same block numbers and clock times. Student exercise text is in
`docs/exercise_prompt.md`. The generator for the exercise results is
`code/make_exercise_results.py` (teacher-only).

---

## Timing Overview

| Clock | # | Block | Frames | Min |
|-------|---|-------|--------|-----|
| 0:00 | — | Where we are, ritual (copy `session_3`, reopen `session_2`), check-in | 3 | 5 |
| 0:05 | 23 | Verification extras: requirements-to-tests matrix, audit report, two more safeguards, delegate / verify / keep | 4 | 5 |
| 0:10 | 24 | **Exercise Part 2:** reopen frame, specify and estimate, debrief | 3 | 25 |
| 0:35 | 25 | Robustness workflow, **LaTeX in VS Code (bridge + 6 frames, moved here from block 26)**, **Exercise Part 3**, what to watch for, debrief | 11 | 33 |
| 1:08 | 26 | Git as the undo button (12 frames), Overleaf bridge (2) | 14 | 14 |
| 1:22 | 27 | Live demo: building a paper, the full loop | 2 | 8 |
| 1:30 | 28 | **Exercise: results → paper**, cross-check, debrief | 3 | 25 |
| 1:55 | 29 | When it goes wrong: four failure patterns; correct / restart / do it yourself | 2 | 6 |
| 2:01 | — | Next Session | 1 | 1 |

**Total: 122 minutes on paper.** The main flow is 45 frames (the footer counts only these). The back matter is 31 frames and is not counted.
By the queue rule, anything that does not fit moves to the start of Session 4.

---

## Notes by Block

### Opening (5 min)
- Ritual: copy `session_3/`. **Everyone must also reopen their `session_2` copy** (new VS Code window). Part 2 continues in it.
- The check-in is one frame. Keep it short; it is the first thing to cut.

### 23. Verification extras (5 min)
- Four frames in five minutes. The matrix and the audit report are the substance. "Two More Safeguards" now points back to the Session 2 checker tab: the critic reads the code, the checker never did.

### 24. Exercise Part 2 (25 min)
- Participants work in their **Session 2 folder**. Check that people are not working in `session_3`.
- Anyone whose merge did not finish gets five minutes to finish it. If many people are in that state, Session 2's Part 1 overran: cut Part 2 to steps 4–6.
- Expected values and the debrief table are in `session_2/docs/instructor_answer_key.md` ("The Missing Data Trap"). Exact figures: 2,036 → 2,035 → 2,035; income alone 1,473 (562 missing); left-right alone 1,499 (536 missing); both 1,151 (884 dropped, 43%).
- Watch for: the base model run unweighted (the intercept check catches it: logistic of the intercept should be 0.4455, not 0.4477); `income_quintile == 0` treated as missing; no sample accounting.

### 25. Robustness workflow, LaTeX in VS Code, and Part 3 (33 min)
- The "New to LaTeX?" button on the setup frame jumps to the back-matter basics and back. Use it only if someone asks.
- **Order change from the plan.** Part 3 asks for a compiled LaTeX table, so the seven LaTeX frames (bridge, Overleaf problem, solution, setup, shortcuts, Problems pane, why it matters) now come right after the robustness-workflow frame and before the exercise. They take about 7 minutes out of block 26, which keeps the session total unchanged: block 25 runs 0:35–1:08 and block 26 runs 1:08–1:22.
- Also in the Session 2 folder. The point of the exercise is N tracking across specifications. The reference table is in the answer key ("Robustness Table Reference").
- Step 11 (commit) comes before the git frames, so participants who have not yet seen `git init` leave it for later. Say so.
- The "What to Watch For" and "Debrief" frames close the Swiss franc exercise.

### 26. Git as the undo button, Overleaf bridge (14 min)
- 14 frames in 14 minutes. Fast frames: the `git add` and `git commit` frames. Slow down on "Your Undo Button" and "The Cycle".
- The Overleaf bridge uses Overleaf's own git remote. No GitHub is involved, so don't mention accounts or tokens.
- GitHub is in the back matter (block B). Don't open it unless asked.

### 27. Live demo: building a paper (8 min)
- Pre-generated outputs for the fake course analysis are in `session_3/output/`; the finished paper is `session_3/paper/course_paper.tex`. The code that made the outputs is `session_3/code/generate_course_analysis.py`.
- Start from an empty `course_paper.tex`, in a **new folder** so the finished paper isn't overwritten. Show Claude Code reading the Problems pane, not you pasting errors.
- If compile problems eat the time, narrate and show the finished PDF.

### 28. Exercise: results → paper (25 min)
Participants work in `session_3/results_to_paper/`. Everyone has the same table, so numbers can be compared across the room.

**The table** (`results/regression_results.csv` → `tables/regression_table.tex`), logit coefficients, weighted except column 2:

| Col | Spec | N | Info coef (SE) | Info p |
|-----|------|---|----------------|--------|
| (1) Base | treatment arms | 2,036 | 0.302 (0.126) | 0.016 |
| (2) Unwtd. | same, unweighted | 2,036 | 0.290 (0.126) | 0.021 |
| (3) Basic | + FX, age, female, education, settlement | 2,035 | 0.324 (0.127) | 0.011 |
| (4) Full | + income, left-right | 1,151 | 0.267 (0.170) | 0.118 |
| (5) Any | pooled "any information" | 2,035 | 0.218 (0.107) | 0.042 |
| (6) Urban | small or big urban only | 1,208 | 0.326 (0.167) | 0.051 |

History and Hungary coefficients are not significant in any column. Pseudo R² runs from 0.002 to 0.026. All six columns reproduce the Session 2 answer key's reference table (ed_level, urban_rural and income_quintile enter linearly, as the key's numbers require).

**Where Claude Code's paragraph typically over-reads the table** (these are the debrief material):
- "Robust across specifications": columns 4 and 6 are not significant at 5%, and column 4 loses 43% of the sample. The point estimate barely moves (0.302 → 0.267); the standard error grows (0.126 → 0.170). The loss of significance comes mostly from the sample, not from the controls.
- "Significant at the 1% level" for column 3: p = 0.011. The table shows only a `*`.
- Column 6 at p = 0.051 described as significant.
- Log-odds coefficients read as probability changes.
- "Reduces" or "increases support" worded as established causal fact. The arms are randomized in the full sample (columns 1–3, 5); columns 4 and 6 restrict the sample, which the randomization does not cover.
- The `+` and `*` markers are the only significance information in the table, so claims about exact p-values are unsupported by the table alone.

**What the cross-check can and cannot do.** It reliably catches transcription errors (a number that is in neither the table nor the CSV). It cannot tell you that the table is the right one to report, and it will often let an over-read claim through if it matches a stars marker. That is the debrief point.

**Mechanics to watch:**
- `git init` must run inside `results_to_paper/`. Check people are not committing in `my_workspace` (which would sweep both sessions' files into one repo).
- The render script writes a fragment (`\input`-able). `paper.tex` already loads `makecell` and `booktabs`. If compilation fails, it is nearly always a missing package or a wrong working directory for the script (it expects to run from `results_to_paper/`).
- The Session 2 copy of `render_regression_table.py` differs: it writes a standalone document and prints the outcome label on the first row only. Don't use it for this exercise.
- Participants must revert at least once. If no one does, ask someone to ask Claude Code for a deliberately worse paragraph and revert it.
- The cross-check needs a fresh conversation, otherwise it re-reads its own reasoning. This is the Session 2 checker idea again.

### 29. When it goes wrong (6 min)
- Two frames. The first is a reference table, so read the four patterns aloud rather than every cell. The second leads to "recent commit makes every option cheap".
- Tie "confidently wrong" back to the cross-check just done.

### Close
- Next Session frame: Node.js LTS is needed in Session 4 for `claude-ignore`. Say it out loud: it is the one prework item.

---

## Time Buffers

- **If running behind:** cut the check-in; compress the "Command N" git frames and the LaTeX shortcut frames; in block 28, have participants stop after step 3 and run the cross-check as a demo.
- **Boundary rule (plan principle 5):** don't start an exercise that cannot finish. If Part 3 (25 min) would not fit, teach the git frames first and run Part 3 afterward; the LaTeX frames must still precede it.
- **If running ahead:** the back-matter blocks. LaTeX basics (A) first, then GitHub vocabulary (B) if anyone coauthors through GitHub.

## Back-matter index

| Block | Frames | Min |
|-------|--------|-----|
| A. LaTeX basics for newcomers | 1 | 5 |
| B. GitHub: vocabulary, branches, PRs, merge conflicts | 14 | 15–20 |
| C. Git extras and the standalone git practice exercise | 8 | 10–20 |
| D. *Reference only:* GitHub collaboration exercise ("Your Chapter") | 6 | — |
| E. If `git pull` fights back | 1 | 2 |

Block C holds the old Session 3 git exercise (choose a project, initialize and commit, the cycle three times, debrief). It is no longer in the main flow because the results-to-paper exercise already practices commit, diff, revert.
