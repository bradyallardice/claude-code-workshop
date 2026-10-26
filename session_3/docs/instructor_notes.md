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
| 0:05 | 23 | Verification extras: a bridge from Session 2's `expectations.md` to the matrix, how to build the matrix (sources, weak vs strong, format, example), how to read an audit report (questions, format, filled-in example), two more safeguards, delegate / verify / keep | 10 | 10 |
| 0:15 | 24 | **Exercise Part 2:** reopen frame, extend expectations into a matrix, specify and estimate, debrief | 4 | 25 |
| 0:40 | 25, 27 | Robustness workflow, LaTeX in VS Code (bridge + setup + shortcuts), **live demo: building a paper (block 27, moved here)**, Problems pane and why it matters, **Exercise Part 3**, what to watch for, debrief | 12 | 41 |
| 1:21 | 26 | Git as the undo button (12 frames), Overleaf bridge (2) | 14 | 14 |
| 1:35 | 28 | "Demo: The Full Loop" diagram, **exercise: results → paper**, cross-check, debrief | 4 | 25 |
| 2:00 | 29 | When it goes wrong: overview, one slide per pattern (looping, confidently wrong, scope creep, coherence loss), correct / restart / do it yourself | 6 | 8 |
| 2:08 | — | Next Session | 1 | 1 |

**Total: 129 minutes on paper**, 7 over the plan. Block 23 now teaches how to build the matrix and read the audit report instead of just showing them (+5). If you need the time back, the cheapest cuts are the check-in, then the "Two More Safeguards" frame. The main flow is 56 frames (the footer counts only these). The back matter is 33 frames and is not counted.
By the queue rule, anything that does not fit moves to the start of Session 4.

---

## Notes by Block

### Opening (5 min)
- Ritual: copy `session_3/`. **Everyone must also reopen their `session_2` copy** (new VS Code window). Part 2 continues in it.
- The check-in is one frame. Keep it short; it is the first thing to cut.

### 23. Verification extras (10 min)
- **Don't re-teach Session 2.** Session 2 already covered the two layers of tests, independent tests, expectations first, tracing samples, the test-first cycle, testing the tests, and "passing is not the goal". Block 23 builds on it with two new tools: the **matrix** (the merge `expectations.md`, extended to every step and made accountable) and the **audit report** (the matrix after the work, with the gaps showing).
- Frame order: the bridge (expectations → matrix → audit); where requirements come from; weak vs strong row (points back to Session 2's independence rule; the new content is the three ways a row goes weak); the five-column format; the filled-in matrix; what to ask of each audit section; the audit format; a filled-in excerpt of the real report (`session_2/tests/audit_report.md`); two more safeguards; delegate / verify / keep.
- "Two More Safeguards": a fresh session as reviewer was introduced in Session 2's parallel-session benefits, so treat the critic prompt as an application of it. Cut this frame first if time is short.

### 24. Exercise Part 2: matrix, tests, estimation (25 min)
- Participants work in their **Session 2 folder**. Check that people are not working in `session_3`.
- Anyone whose merge did not finish gets five minutes to finish it. If many people are in that state, Session 2's Part 1 overran: skip the optional interaction step.
- **Structure: audit their own `expectations.md` (3) → extend it into a matrix (3) → tests for the new rows (3) → estimate (16).** The matrix is the point, and the audit is what makes Session 3 different from Session 2: the same expectations, now held against the three weak patterns. Expect most participants' `expectations.md` to have vague rows ("the merge looks right") and rows whose independent source is the pipeline. Anyone without an `expectations.md` from Session 2 starts the matrix from the codebook. Participants write their own requirements; Claude Code only reviews them for the three weak patterns from the weak/strong frame. If someone has Claude write the rows, ask them what a violation of each row would look like.
- **Tests must fail before the model exists.** A test that passes with no model is testing nothing. Circulate and look for tests that read the pipeline's own output as the expected value.
- Common weak rows to catch: "the model is correct" (too vague); expected N copied from the model output (reuses the code); "coefficients look reasonable" (a judgment, not a number).
- Expected values and the debrief table are in `session_2/docs/instructor_answer_key.md` ("The Missing Data Trap"). Exact figures: 2,036 → 2,035 → 2,035; income alone 1,473 (562 missing); left-right alone 1,499 (536 missing); both 1,151 (884 dropped, 43%).
- Watch for: the base model run unweighted (the intercept check catches it: logistic of the intercept should be 0.4455, not 0.4477); `income_quintile == 0` treated as missing; no sample accounting.

**Reference matrix (what a good one looks like for this project; do not hand out).**

| Requirement | Source | Test | Independent truth | Passing condition |
|---|---|---|---|---|
| Control is the reference arm | Design | Coefficient names; intercept meaning | Raw CSV, `cntrl` rows | No `cntrl` coefficient; intercept $=$ control arm |
| Survey weights are used | Design | Intercept vs control share | Weighted control share from raw CSV (478 respondents) | logistic(intercept) $=0.4455$ within 1e-5 (unweighted would be 0.4477) |
| Outcome built as defined | Codebook | Recode check | Raw `govt_intervention` | 1 for `some`/`big`; `DK` (230) coded 0; 8 missing stay missing |
| Base model N | Codebook | N check | Rows with non-missing outcome | N $=2{,}036$ |
| N explained for every model | Accounting | Rows in $-$ dropped by reason | Raw missingness counts | 2,035 (FX); 1,473 (income); 1,499 (left-right); 1,151 (both) |
| Income 0 is valid | Codebook | Count of `income_quintile == 0` after cleaning | Raw demographics | 8 respondents kept, not missing |
| Treatment arms intact | Design | Arm counts | Raw CSV | 480 / 549 / 520 / 495 |
| (Part 3) Unweighted differs from weighted | Design | Compare info coefficients | Hand-computed unweighted fit | 0.290 vs 0.302; not equal |
| (Part 3) Every specification is in the table with its N | Output | Manifest test | Model objects | All six columns present, N matches |

### 25. Robustness workflow, LaTeX in VS Code, and Part 3 (33 min)
- **Step 10 closes the loop on `CLAUDE.md`.** Participants revise their own rules from a gap the audit report exposed, then compare with the reference protocol (`docs/verification_protocol.md`; back-matter block F). This is where the protocol is introduced: not as something to install, but as a comparison with rules they already wrote. If someone arrives without rules from Session 2, have them write two from the gaps in their audit report first.
- **Part 3 builds on the matrix.** Each robustness variant gets a matrix row (what must change, what must stay). The audit report is built from the matrix: each row, its test, its result; rows with no test go under *Not tested*. A matrix that was never updated is the first thing to check if the report looks thin.
- The "New to LaTeX?" button on the setup frame jumps to the back-matter basics and back. Use it only if someone asks.
- **Order change from the plan.** Part 3 asks for a compiled LaTeX table, so the seven LaTeX frames (bridge, Overleaf problem, solution, setup, shortcuts, Problems pane, why it matters) now come right after the robustness-workflow frame and before the exercise. They take about 7 minutes out of block 26, which keeps their combined length unchanged: block 25 runs 0:40–1:21 (including the demo) and block 26 runs 1:21–1:35.
- Also in the Session 2 folder. The point of the exercise is N tracking across specifications. The reference table is in the answer key ("Robustness Table Reference").
- Step 11 (commit) comes before the git frames, so participants who have not yet seen `git init` leave it for later. Say so.
- The "What to Watch For" and "Debrief" frames close the Swiss franc exercise.

### 26. Git as the undo button, Overleaf bridge (14 min)
- 14 frames in 14 minutes. Fast frames: the `git add` and `git commit` frames. Slow down on "Your Undo Button" and "The Cycle".
- The Overleaf bridge uses Overleaf's own git remote. No GitHub is involved, so don't mention accounts or tokens.
- GitHub is in the back matter (block B). Don't open it unless asked.

### 27. Live demo: building a paper (8 min), taught inside block 25
- **Position:** after the LaTeX Workshop shortcuts frame and before "LaTeX Errors and the Problems Pane" (slide 26). Participants watch Claude Code read the Problems pane before the pane is explained. Git has not been taught yet, so don't commit in the demo; the "Demo: The Full Loop" diagram (with the commit step) opens block 28 instead.
- **Where the demo files are:** `session_3/paper/`. It holds `tables/` (`summary_stats.tex`, `regression_earnings.tex`), `figures/` (`enrollment.png`, `satisfaction.png`, `attrition.png`, `earnings_effect.png`, plus PNG renders of the two tables), and the **finished** `course_paper.tex` and `.pdf`. The data are `session_3/data/` and the code that made everything is `session_3/code/generate_course_analysis.py` (teacher-only). `session_3/output/` is older Swiss franc material, not the demo.
- **Start from a clean folder so the finished paper doesn't give it away.** Before class: `mkdir session_3/demo_run && cp -r session_3/paper/tables session_3/paper/figures session_3/demo_run/`, then open `demo_run` in VS Code and have Claude Code create `course_paper.tex` from nothing. Show the finished `paper/course_paper.pdf` only as the fallback. Delete `demo_run` afterward (it is not covered by `sync_student.sh`).
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
- **No `git diff` in this exercise.** In VS Code, Claude Code shows the diff before applying a change and participants accept or reject it. The commit before each instruction is the safety net for anything they accept and regret (`git checkout -- .`). Participants should reject at least one change. If no one does, ask someone to request a deliberately worse paragraph and reject it.
- The cross-check needs a fresh conversation, otherwise it re-reads its own reasoning. This is the fresh-session-as-independent-checker idea from Session 2's parallel-session frames.

### 29. When it goes wrong (8 min)
- Six frames: an overview table, one slide for each of the four patterns, then correct / restart / do it yourself. About a minute each.
- Every pattern slide has the same four parts: what it looks like, why it happens, what to do, and an example with a prompt to copy. Run them as recognition practice: read "what it looks like" and ask the room whether they have seen it, before showing the response.
- **Tie each pattern to something they have just done:**
  - *Looping:* a LaTeX compile error from Part 3. The fix is new information (the log), not another try.
  - *Confidently wrong:* the weights example is real. In this course's own Session 2 scripts, a weighted logit silently ignored its weights (statsmodels' formula `logit()` accepts a `weights` argument and discards it). The independent check on the intercept would have caught it.
  - *Scope creep:* the accept/reject diff in VS Code. Count the files and lines.
  - *Coherence loss:* Session 2's context strategies (one conversation per task, decisions in files) and the row-count test in their matrix.
- The last frame closes on "a recent commit makes every option cheap". Connect it to the commit before every instruction in the results-to-paper exercise.

### Close
- Next Session frame: no prework item any more. Node.js was only needed for the `claude-ignore` hook, which Session 4 no longer teaches.

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
| F. A reference verification protocol (the file `docs/verification_protocol.md`) | 2 | 3 |

Block C holds the old Session 3 git exercise (choose a project, initialize and commit, the cycle three times, debrief). It is no longer in the main flow because the results-to-paper exercise already practices commit, diff, revert.
