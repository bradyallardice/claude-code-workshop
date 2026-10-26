# Session 2 — Instructor Notes & Timing

**Context strategies, parallel sessions, plan mode, verification begins. Target: 2:00, no break.**
Deck: `slides/session2_slides.tex`. Structure and clock come from
`admin/course_plan_4_sessions.md` (blocks 14–22); the comment banners in the deck
carry the same block numbers and clock times. Expected values for the exercise are
in `docs/instructor_answer_key.md`.

---

## Timing Overview

| Clock | # | Block | Min |
|-------|---|-------|-----|
| 0:00 | — | Where we are, start-of-session ritual | 3 |
| 0:03 | 14 | Context strategies, incl. the two-tab demo, collision round, and benefits/risks frame | 25 |
| 0:28 | 15 | Core workflow (overview, Step 1), then execution modes: plan / default / auto-accept | 7 |
| 0:35 | 16 | Live demo: plan mode vs. auto-accept, then workflow Steps 2–4 | 9 |
| 0:44 | 17 | **Exercise:** build the county panel in plan mode, evaluate the plan, debrief | 25 |
| 1:09 | 18 | Code can run and still be wrong, read the code | 3 |
| 1:12 | 19 | Verification: two layers of tests through "passing is not the goal" | 10 |
| 1:22 | 20 | Make it a rule in CLAUDE.md (1/2, 2/2) | 2 |
| 1:24 | 21 | The Swiss franc shock: data and research question | 3 |
| 1:27 | 22 | **Exercise Part 1:** learn the data and write expectations, merge in plan mode, verify, debrief | 35 |
| 2:02 | — | Next Session | 1 |

**Total: 123 minutes on paper.** The plan already runs Session 2 two minutes over.
By the queue rule, whatever doesn't fit moves to the start of Session 3.

---

## Notes by Block

### Opening (3 min)
- Ritual: copy `session_2/`. Remind them to **keep their `session_1` copy**: block 17 runs in it.
- If someone's `git pull` fails, use the "git pull fails?" button on the ritual frame. It jumps to the recovery frame in the back matter and back again.

### 14. Context strategies and parallel sessions (25 min)
- Eighteen frames, demos included, in 25 minutes, so keep moving. The frames on auto-compact, "what counts as one task" and "one conversation per task" are the core. Strategies 2–5 can go faster.
- Benefits/risks frame: land "no shared memory except files" and "a tab already open won't see later CLAUDE.md edits". Session 4's automated checking builds on both.

#### Demo run sheet (block 14, in slide order)
Prompts for the first two demos are on the slides. **The "good prompt" demo has no prompt on its slide**, so the one below is a suggestion, not something already in the deck.

**1. Two Tabs at Once** (follow along; slide 11). Everyone opens a second tab (`Cmd/Ctrl+Shift+Esc`) in their `session_2` copy and pastes one prompt per tab.
- *What it does:* two independent read-only tasks run at the same time.
- *Right answers:*
  - Tab A lists the 11 survey variables, with a one-line description from the codebook: `respondent_id`, `interview_date`, `treatment`, `govt_intervention`, `supports_intervention`, `fx_status`, `age`, `female`, `ed_level`, `urban_rural`, `survey_weight`.
  - Tab B reports treatment-group sizes: `cntrl` 480, `info` 549, `history` 520, `Hungary` 495 (total 2,044).
- *Look for:* both tabs finish without disturbing each other, and no file changed (the prompts say not to modify any). Anyone whose tab asked for a permission or edited something. The point is the clean, separate context.

**2. The Collision Round** (watch only; slide 12). Same two tabs, which still hold the previous answers ("the variable list you just made").
- *Setup:* delete `output/data_notes.md` beforehand so you start from no file. Send both prompts at the same moment.
- *What it does:* both tabs write `output/data_notes.md`: Tab A the variable list, Tab B the group counts.
- *Possible outcomes:* (a) one tab's content simply overwrites the other (last writer wins); (b) a tab notices the file changed since it last looked and merges or appends; (c) a tab errors or refuses and re-reads. All three are fine to show. There is no single right answer: the outcome depends on timing.
- *Look for:* whose content is in the file at the end; whether either tab said anything about the other's write; and that a plain overwrite is silent, with no warning. **Rehearse it, and keep a screenshot of a clean overwrite as fallback.**

**3. What Claude Code Looks Like in Practice** (watch only; slide 15). Your own project (AI Adoption Prediction); nothing to follow along with.
- *What it does:* Claude reads files in a real project folder and proposes an edit.
- *Look for (the slide's four points):* where Claude Code sits in the VS Code window; how it reads files; how it proposes edits as a diff; how you approve, reject, or redirect each change. Prepare a small, safe edit in advance, and **reject or redirect one proposal on purpose** so they see that option.

**4. Summarizing a Session** (watch only; slide 18). Summarize a conversation with real content: one that changed files, made decisions, and left work to do. The demo tabs have nothing to summarize: participants' tabs only read two files, and yours only wrote `data_notes.md`. A prepared session from your own project works.
- *What it does:* use the Strategy 3 prompt from the slide before, save the summary to a file, paste it into a fresh conversation.
- *Look for:* the summary names files changed, decisions made, and what remains; and the fresh conversation picks up from it without re-explaining.

**5. A Good Prompt** (slide 21; the slide says follow along but gives no prompt). Suggested: the same small task twice, each in a fresh conversation in the `session_2` copy.
- *Vague prompt:* `Clean up the survey data and get it ready for analysis.`
- *Specific prompt:* `Read data/swiss_franc_survey.csv and docs/codebook.md. Add a column fx_borrower: 1 if fx_status is "current" or "past", 0 if "none", and missing if fx_status is missing. Keep all 2,044 rows. Save the result to output/demo_fx_borrower.csv and do not modify the raw file.`
- *Right answer (specific):* 2,044 rows; `fx_borrower` = 1 for **124** (69 current + 55 past), 0 for **1,918**, missing for **2**; the raw file unchanged. A count of 1,920 zeros means the 2 missing were recoded to 0.
- *Look for:* in the specific version, the slide's three questions each have an answer on the page. Files: `swiss_franc_survey.csv` and `codebook.md`. Goal: one sentence. Constraints: keep all rows, missing stays missing, raw file untouched. In the vague version, count what Claude decided that you did not ask for: dropping rows, recoding, renaming, or writing new files. Its output varies, so **run the vague version beforehand** and keep a screenshot. It may also ask a clarifying question; that is fine to show.

### 15. Core workflow, then execution modes (7 min)
- Introduce the loop first, so the modes and the demo have something to hang on: describe, review plan, generate and validate, save or re-instruct. Then Step 1 (describe): write the instruction down first, with inputs, goal, and constraints.
- Then the modes. Plan mode is the recommended default for research. The "checkpoint" framing (catch the inner join before it happens) is key.
- Default mode: the risk is that its judgment about "significant" differs from yours. Auto-accept: fine for docs and formatting, not for data work.
- Key insight frame: "directing vs. reviewing" is concrete and memorable.

### 16. Live demo: plan mode vs. auto-accept, then Steps 2–4 (9 min)
**The slide has no task, so the one below is a suggestion.** It uses the Swiss franc survey in your `session_2` copy.

- *Task (the same prompt in both modes):* `Show me support for government intervention by treatment group in data/swiss_franc_survey.csv.` It is under-specified on purpose.
- *What it does:* run it in **plan mode** first, then the same prompt in a **new conversation in auto-accept** (switch with the mode indicator by the prompt box). Plan mode shows the approach before anything runs; auto-accept just does it.
- *Decisions hidden in the task* (the plan shows them, auto-accept silently makes them):
  - Which variable? `supports_intervention` (binary) vs. recoding `govt_intervention`.
  - **"Don't know."** `supports_intervention` codes all 230 DK answers as 0, so DK counts as *not supporting*.
  - **Missing outcome:** 8 respondents. Dropped, or counted as 0?
  - **Survey weights:** used or ignored.
- *Right answers:*

  | Treatment | N (outcome non-missing) | Unweighted | Weighted |
  |-----------|-------------------------|------------|----------|
  | `cntrl` | 478 | 0.448 | 0.446 |
  | `info` | 548 | 0.520 | 0.521 |
  | `history` | 518 | 0.459 | 0.476 |
  | `Hungary` | 492 | 0.484 | 0.494 |
  | Overall | 2,036 | 0.479 | 0.486 |

  Counting the 8 missing as 0 changes the unweighted shares only slightly (0.446 / 0.519 / 0.458 / 0.481), which is itself a point: a silent choice can look harmless and still be unreported.
- *Look for:*
  - **Plan mode:** does the plan mention weights, DK, and the 8 missing? In the plan, redirect it live (for example "use survey_weight and report both"), then approve.
  - **Auto-accept:** which of the four choices did it make, and does its output say so? The shares will be close to the table either way, so the difference to show is *visibility*, not a wrong number.
  - The felt contrast: plan is slower but you see every decision; auto-accept is faster and you see only the result.
- *After the demo*, Steps 2–4 explain what you just did: Step 2 (review the plan: anything in it you didn't ask for?), Step 3 (generate and validate: read the code, not just the output), Step 4 (save or re-instruct).
- **Time risk:** if it's taking long, narrate what would happen rather than waiting for execution. Rehearse both runs and keep screenshots of the two plans.

### 17. Exercise: county panel in plan mode (25 min)
- In the **`my_workspace/session_1`** copy, opened in a **new VS Code window** (File → New Window, then Open Folder). The data and codebooks are there from Session 1; the frame names the folder but not the new window.
- Pairs, both at one computer. Steps: short CLAUDE.md (~3 min; template in `references/CLAUDE_template.md` of the course repo), plan mode, prompt, read codebooks and evaluate the plan (~7 min), approve/revise and run (~7 min), check output.
- Keep "Evaluating the Plan" on screen as a checklist.
- If time is short, have pairs stop after the plan review. The learning is in the plan review, not the execution.
- Circulate and look for: not reading codebooks, accepting default variable definitions, not checking the join type.
- **Reference answers** are in your `session_1/docs/decisions.md` (13 decisions, each with its alternative) and `session_1/output/county_panel.csv`: 309 counties × 4 years (2012, 2016, 2020, 2024) = **1,236 rows**. Participants' panels will differ where they chose differently; that is not an error, so ask whether they chose it deliberately. The decisions that matter for "Evaluating the Plan":
  - keep only `mode == "TOTAL"` election rows (otherwise 2020 double-counts);
  - drop `COUNTYFIP == 0` (county not identified);
  - `HISPAN == 9` (not reported) leaves the numerator and denominator of the Hispanic share; it does not count as non-Hispanic;
  - college is `EDUC >= 10` (bachelor's or higher), where `EDUC >= 7` is a real alternative;
  - inner join on county × year, and balance the panel to counties present in all four years.
- Debrief (~5 min): 2–3 pairs on variable coding decisions and what they rejected in the plan. Three lessons: CLAUDE.md forces explicitness, plan review forces pre-commitment, domain knowledge is non-delegable.

### 18. Code can run and still be wrong; read the code (3 min)
- The workflow was introduced before the modes and its steps were covered around the demo. This block starts the verification thread with what can go wrong silently: a merge that duplicates rows, a regression that drops rows with missing controls, wrong clustering, an alphabetical reference category.
- "Read the code" is the most basic verification. Tests come next because reading doesn't scale.

### 19. Verification (10 min)
- Two layers: software tests (does it run) vs. research tests (are the numbers right). The examples use today's data, so they preview Part 1.
- Spend the most time on "Independent Tests" and "Test the Tests". In Part 1, the participant's own `expectations.md` is the independent source.

### 20. Make it a rule (2 min)
- The protocol is in `docs/verification_protocol.md`; Part 1 step 0 installs it. "CLAUDE.md is an instruction, not enforcement."

### 21. Swiss franc data (3 min)
- Background, files, research question. Point out that the demographics file has more rows than the survey: the join type is theirs to decide.

### 22. Exercise Part 1: learn the data, merge, verify (35 min)
- The core idea: **participants learn the data themselves.** Step 1 is done without Claude Code: the codebook, a look at the CSVs, then `expectations.md` written by hand. Enforce this. It is the part that never gets automated.
- Everything step 1 asks can be answered from the codebook. A complete `expectations.md` is sketched in the answer key ("Step 1").
- Step 2 has Claude Code write its tests from their file, so the expectations reach it through a file, not the chat.
- Test the tests: the duplicated row must belong to a **survey respondent** (answer key, "Fault injection").
- Debrief (~6 min): start with "which of your expectations were wrong?", then "what did the data teach you that the codebook didn't?" Then reveal the expected numbers (the second debrief frame has a `\pause`).
- The automated version, with Claude checking against independent expectations, is shown in Session 4 (block 32). The earlier two-tab checker frames are in `slides/pending_session4_frames.tex`.

### Close
- Next Session frame: **keep `my_workspace/session_2` as it is**, because Session 3's Part 2 continues in it. Check that `setup_check.tex` compiles before Session 3.

---

## Time Buffers

- **If running behind:** compress strategies 2–5 in block 14, or run only the specific version of the good-prompt demo; in block 17, stop pairs after the plan review.
- **Boundary rule (plan principle 5):** don't start Part 1 (35 min) unless it can finish. If you reach block 22 with less than that, pull Session 3's first lecture block (verification extras, block 23) forward instead, and open Session 3 with Part 1. Its frames are in the Session 3 deck.
- **If running ahead:** let county-panel pairs run and verify their script.
