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
| 1:22 | 20 | Rules in CLAUDE.md come from failures (one frame) | 1 |
| 1:23 | 21 | The Swiss franc shock: data and research question | 3 |
| 1:26 | 22 | **Exercise Part 1:** learn the data and write expectations, merge in plan mode, verify, debrief, write your own CLAUDE.md rules | 35 |
| 2:01 | — | Next Session | 1 |

**Total: 122 minutes on paper.** The plan already runs Session 2 one minute over.
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
Every demo prompt is on its slide. **The demos use the exchange-rate file (`data/PLN_CHF_EUR_FXdata.csv`), not the Swiss franc survey, on purpose**: the survey is Part 1's data, and demos on it would reveal the numbers participants verify in Part 1 (group sizes, the overall support share, the FX-exposure counts). The exchange-rate file is not used in any exercise. It has 269 daily rows (weekdays only, 2014-11-03 to 2015-11-30) and 5 columns, with no documentation.

**1. Two Tabs at Once** (follow along; slide 11). Everyone opens a second tab (`Cmd/Ctrl+Shift+Esc`) in their `session_2` copy and pastes one prompt per tab.
- *What it does:* two independent read-only tasks run at the same time.
- *Right answers:*
  - Tab A describes the 5 columns: `Jul.Day` (Julian day number), `YYYY/MM/DD` (the date), `Wdy` (weekday), `CHF/EUR` (about 1.20 in Nov 2014; CHF per EUR), `CHF/PLN` (about 0.28; CHF per PLN). **There is no codebook, so the quote direction is inferred from the values.** Claude should say so, or you can ask.
  - Tab B reports the first date **2014-11-03**, the last **2015-11-30**, and **269 rows**. Watch for an off-by-one: the file has a header plus 269 data rows, and its last line has no trailing newline, so `wc -l` prints 269 even though there are 270 lines.
- *Look for:* both tabs finish without disturbing each other, and no file changed (the prompts say not to modify any). Anyone whose tab asked for a permission or edited something. The point is the clean, separate context.

**2. The Collision Round** (watch only; slide 12). Same two tabs, which still hold the previous answers ("the column descriptions you just made").
- *Setup:* delete `output/data_notes.md` beforehand so you start from no file. Send both prompts at the same moment.
- *What it does:* both tabs write `output/data_notes.md`: Tab A the column descriptions, Tab B the dates and row count.
- *Possible outcomes:* (a) one tab's content simply overwrites the other (last writer wins); (b) a tab notices the file changed since it last looked and merges or appends; (c) a tab errors or refuses and re-reads. All three are fine to show. There is no single right answer: the outcome depends on timing.
- *Rehearsal (two parallel subagents, one run, with an earlier pair of prompts on the survey data; the mechanism is the same, but the new prompts were not re-run):* outcome (a). Both tabs checked that the file did not exist, then wrote it with the Write tool. One write said "created"; the other said "updated" and replaced it. **Only the second writer's content survived.** Only the losing tab noticed, and only because it re-read the file (and a hook message said the file had changed after its edit). The winning tab saw nothing unusual beyond the word "updated". Subagents are not the same as two VS Code tabs, and this is one run, so yours may go differently.
- *Look for:* whose content is in the file at the end; whether either tab said anything about the other's write; and that a plain overwrite is silent for the tab that wins. **Rehearse it, and keep a screenshot of a clean overwrite as fallback.**

**3. What Claude Code Looks Like in Practice** (watch only; slide 15). Your own project (AI Adoption Prediction); nothing to follow along with.
- *What it does:* Claude reads files in a real project folder and proposes an edit.
- *Look for (the slide's four points):* where Claude Code sits in the VS Code window; how it reads files; how it proposes edits as a diff; how you approve, reject, or redirect each change. Prepare a small, safe edit in advance, and **reject or redirect one proposal on purpose** so they see that option.

**4. Summarizing a Session** (watch only; slide 18). Summarize a conversation with real content: one that changed files, made decisions, and left work to do. The demo tabs have nothing to summarize: participants' tabs only read two files, and yours only wrote `data_notes.md`. A prepared session from your own project works.
- *What it does:* use the Strategy 3 prompt from the slide before, save the summary to a file, paste it into a fresh conversation.
- *Look for:* the summary names files changed, decisions made, and what remains; and the fresh conversation picks up from it without re-explaining.

**5. A Good Prompt** (watch only; slide 21). The same small task twice, each in a fresh conversation in the `session_2` copy.
- *Vague prompt:* `Clean up the exchange-rate data and get it ready for analysis.`
- *Specific prompt:* `Read data/PLN_CHF_EUR_FXdata.csv. Add a column post_peg: 1 if the date is on or after 2015-01-15 (the day the Swiss National Bank removed the peg), 0 before. Keep all 269 rows. Save the result to output/demo_fx_flagged.csv and do not modify the raw file.`
- *Right answer (specific):* 269 rows; `post_peg` = 1 for **220** rows and 0 for **49**; the raw file unchanged. The data confirm the date: `CHF/EUR` goes from 1.20102 on 2015-01-14 to 1.03773 on 2015-01-15.
- *Rehearsal, specific (one subagent run):* exactly that. 269 rows, `post_peg` appended as the last column (220 / 49), raw file's checksum unchanged. Only cosmetic differences: it kept the original date strings, and the output file drops the quotes the raw file puts around some fields.
- *Rehearsal, vague (one subagent run):* it decided a lot without asking. It profiled the file (no missing values, no duplicates, no weekend rows), then **dropped two columns** (`Jul.Day` and `Wdy`, as redundant), **renamed the rest** to snake_case, **converted the dates** to ISO format, wrote a **script** (`scripts/clean_fx.py`) and a CSV (`output/fx_clean.csv`, 269 × 3), and did not flag the 2015-01-15 break. It listed what it would have asked: what "ready for analysis" means, how to treat 12 missing weekdays, whether to flag the break, and whether the quote direction is as expected. It was told not to ask questions; a real session might stop and ask. That is also a good outcome to show.
- *Look for:* in the specific version, the slide's three questions each have an answer on the page. Files: the exchange-rate CSV. Goal: one sentence. Constraints: keep all rows, save to a named path, raw file untouched. In the vague version, count what Claude decided that you did not ask for (dropped columns, renames, a script). Its output varies each time, so **run the vague version beforehand** and keep a screenshot.

### 15. Core workflow, then execution modes (7 min)
- Introduce the loop first, so the modes and the demo have something to hang on: describe, review plan, generate and validate, save or re-instruct. Then Step 1 (describe): write the instruction down first, with inputs, goal, and constraints.
- Then the modes. Plan mode is the recommended default for research. The "checkpoint" framing (catch the inner join before it happens) is key.
- Default mode: the risk is that its judgment about "significant" differs from yours. Auto-accept: fine for docs and formatting, not for data work.
- Key insight frame: "directing vs. reviewing" is concrete and memorable.

### 16. Live demo: plan mode vs. auto-accept, then Steps 2–4 (9 min)
The prompt is on the slide. It uses the exchange-rate file, not the survey (see the demo run sheet above).

- *Task (the same prompt in both modes, each in a fresh conversation):* `Compare the average CHF/PLN rate before and after the peg was removed in data/PLN_CHF_EUR_FXdata.csv.` It is under-specified on purpose.
- *What it does:* run it in **plan mode** first, then the same prompt in **auto-accept** (switch with the mode indicator by the prompt box). Plan mode shows the approach before anything runs; auto-accept just does it.
- *Decisions hidden in the task* (the plan lists them; auto-accept makes them):
  - **What "the peg" is, and its date.** The file never says. Claude uses outside knowledge: the Swiss National Bank dropped its 1.20 EUR/CHF floor on 2015-01-15, and the data show the break that day.
  - **Which side of the break 15 January falls on.** The file has a row for it.
  - **Which series.** `CHF/PLN` (asked for) or `CHF/EUR`.
  - **Window length.** The full sample gives 49 days before and 220 after.
  - **What the quote means.** `CHF/PLN` is CHF per 1 PLN (inferred from the values), so a *fall* means the franc strengthened and the zloty weakened. Misreading the direction reverses the story.
  - **Averaging, and the 12 weekdays absent from the file** (for example 25–26 December and 1 January).
  - **Whether to test.** Daily rates are strongly autocorrelated, so a naive test overstates the evidence.
- *Right answers* (simple means of the daily rate; 15 January counted as "after"):

  | | Dates | N | Mean `CHF/PLN` |
  |---|---|---|---|
  | Before | 2014-11-03 to 2015-01-14 | 49 | 0.28434 |
  | After | 2015-01-15 to 2015-11-30 | 220 | 0.25451 |

  The difference is −0.02983, or **−10.49%**. Sensitivity, to show the choices matter: with 15 January counted as "before", 0.28346 and 0.25457 (−10.19%); the first 49 days after the break only, 0.25140 (−11.58%); the same comparison in `CHF/EUR`, 1.20222 to 1.06094 (−11.75%); and the single-day move on 15 January, −14.66%.
- *Rehearsal (one subagent run each; subagents cannot switch modes, so the plan run was told to read but not write, and to end with a plan):*
  - **Plan:** read-only checks, then a plan listing ten unspecified decisions: the series, what "the peg" is, the split date, the unequal windows, the quote direction, the averaging, the missing weekdays, whether to test, and the limits of a before/after comparison. **It said it would not run a significance test** because daily levels are autocorrelated, and that it would print to the console and save nothing.
  - **Auto-accept:** produced the table above (0.28434, 0.25451, −10.49%) with the break visible in the raw rows. It also **ran a Welch t-test** (t = −49.8; it caveated that the p-value overstates the evidence) and added standard deviation, minimum and maximum. It **wrote a script and a CSV into `output/` that were not requested.** It did flag that the quote direction was inferred and that the windows have unequal length. It did not state the rule for which side of the break 15 January falls on.
  - So the contrast is not that auto-accept hides everything. It was fairly candid, though it was also *asked* to list its choices afterwards. The reliable difference: in plan mode you can say "no test, no files" **before** anything runs; in auto-accept you get the test and the files, and hear about them afterwards.
- *Look for:*
  - **Plan mode:** does the plan mention the break date, the direction of the quote, and the window lengths? Redirect it live (for example "equal 49-day windows, and no test"), then approve.
  - **Auto-accept:** which choices did it make, which did it mention, and what did it create that you didn't ask for?
  - The felt contrast: plan is slower but you see every decision first; auto-accept is faster and you see the result and the extras.
- *After the demo*, Steps 2–4 explain what you just did: Step 2 (review the plan: anything in it you didn't ask for?), Step 3 (generate and validate: read the code, not just the output), Step 4 (save or re-instruct).
- **Time risk:** if it's taking long, narrate what would happen rather than waiting for execution. Rehearse both runs in real Claude Code (the subagent rehearsals above approximate them but are not the same) and keep screenshots of the two plans.

### 17. Exercise: county panel in plan mode (25 min)
- In the **`my_workspace/session_1`** copy, opened in a **new VS Code window** (File → New Window, then Open Folder). The data and codebooks are there from Session 1; the frame names the folder but not the new window.
- Pairs, both at one computer. Steps: short CLAUDE.md (~3 min; template in `references/CLAUDE_template.md` of the course repo), plan mode, prompt, read codebooks and evaluate the plan (~7 min), approve/revise and run (~7 min), check output.
- The slide says where things are, all under `session_1/data/`: `election/countypres_sample.csv` with its codebook `election/County Presidential Returns 2000-2024.md`, and `ipums/census_YYYY_sample.csv.gz` (2012, 2016, 2020, 2024) with the XML codebooks in `ipums/Codebooks/census_YYYY_raw.xml`. The XML codebooks are long: tell pairs to have Claude pull the codes they need (`EDUC`, `RACE`, `HISPAN`) rather than read them top to bottom.
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

### 20. Rules in CLAUDE.md come from failures (1 min)
- One frame (1 min). The point: a rule is the record of a failure. Do **not** show or hand out a ready-made protocol. Participants write their own in Part 1 step 4, and Session 3 compares theirs with a reference (`session_3/docs/verification_protocol.md`, kept out of the Session 2 folder on purpose). "CLAUDE.md is an instruction, not enforcement."

### 21. Swiss franc data (3 min)
- Background, files, research question. Point out that the demographics file has more rows than the survey: the join type is theirs to decide.

### 22. Exercise Part 1: learn the data, merge, verify (35 min)
- The core idea: **participants learn the data themselves.** Step 1 is done without Claude Code: the codebook, a look at the CSVs, then expectations written by hand in `session_2/expectations.md`, a nearly empty file that says only "Write down your expectations here." Enforce this. It is the part that never gets automated.
- Everything step 1 asks can be answered from the codebook. A complete `expectations.md` is sketched in the answer key ("Step 1").
- Step 2 has Claude Code write its tests from their file, so the expectations reach it through a file, not the chat.
- Test the tests: the duplicated row must belong to a **survey respondent** (answer key, "Fault injection").
- Something no earlier demo reveals, worth knowing for Part 1 and Session 3's estimation: `supports_intervention` codes all **230** "DK" (don't know) answers as 0, so "don't know" counts as *not supporting*, and the codebook doesn't say so. DK rates differ by arm: 8.9% in `info`, 13.0% in `cntrl`, 12.9% in `history`, 10.6% in `Hungary`. Counting DK as non-support therefore inflates `info`'s lead: support is 52.0% vs. 44.8% (7.2 points) as coded, and 57.1% vs. 51.4% (5.7 points) with DK dropped from the denominator.
- **Step 4 (last 4 min): participants write their own `CLAUDE.md` rules.** There is no pasted protocol on purpose. They have just watched Claude Code work without rules, so each rule should come from something they saw: a test copying the script's output, a design choice made for them, a test edited to pass, an "all passed" with no caveats. Good rules are specific and name how a violation would show. Weak ones are generic ("be careful", "verify everything"). Don't hand out `session_3/docs/verification_protocol.md`; Session 3 compares their rules with it.
- Debrief (~4 min): start with "which of your expectations were wrong?", then "what did the data teach you that the codebook didn't?" Then reveal the expected numbers (the second debrief frame has a `\pause`).
- The automated version, with Claude checking against independent expectations, is shown in Session 4 (block 32). The earlier two-tab checker frames are in `slides/pending_session4_frames.tex`.

### Close
- Next Session frame: **keep `my_workspace/session_2` as it is**, because Session 3's Part 2 continues in it. Check that `setup_check.tex` compiles before Session 3.

---

## Time Buffers

- **If running behind:** compress strategies 2–5 in block 14, or run only the specific version of the good-prompt demo; in block 17, stop pairs after the plan review.
- **Boundary rule (plan principle 5):** don't start Part 1 (35 min) unless it can finish. If you reach block 22 with less than that, pull Session 3's first lecture block (verification extras, block 23) forward instead, and open Session 3 with Part 1. Its frames are in the Session 3 deck.
- **If running ahead:** let county-panel pairs run and verify their script.
