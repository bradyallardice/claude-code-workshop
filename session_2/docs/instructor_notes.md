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
| 0:28 | 15 | Execution modes: plan / default / auto-accept | 5 |
| 0:33 | 16 | Live demo: plan mode vs. auto-accept | 6 |
| 0:39 | 17 | **Exercise:** build the county panel in plan mode, evaluate the plan, debrief | 25 |
| 1:04 | 18 | The core workflow, code can run and still be wrong, read the code | 8 |
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
- **Two-tab demo (round 1, follow along):** two read-only prompts in two tabs, sent at once. The point is that each tab has its own clean context and they don't interfere.
- **Collision round (watch only):** both tabs write `output/data_notes.md`. Participants don't run this one, which saves their tokens and their files.
  - Claude Code may notice that the file changed since it read it (its edit tools usually refuse to write a file that changed since they last read it) and merge instead of overwrite. That is fine to show as it happens: it is still the only shared memory, and the outcome depended on timing.
  - **Rehearse it beforehand, and keep a screenshot of a clean overwrite as fallback** (plan, "New material to build").
- Benefits/risks frame: land "no shared memory except files" and "a tab already open won't see later CLAUDE.md edits". Session 4's automated checking builds on both.
- **Summarizing demo (watch only):** summarize a conversation with real content, one that changed files, made decisions, and left work to do. The demo tabs have nothing to summarize: participants' tabs only read two files, and yours only wrote `data_notes.md`. A session from your own project (the one in the earlier live demo) works, prepared in advance. Use the Strategy 3 prompt on the slide before, save the summary to a file, then paste it into a fresh conversation and show that it picks up where the last one stopped.

### 15. Execution modes (5 min)
- Plan mode is the recommended default for research. The "checkpoint" framing (catch the inner join before it happens) is key.
- Default mode: the risk is that its judgment about "significant" differs from yours. Auto-accept: fine for docs and formatting, not for data work.
- Key insight frame: "directing vs. reviewing" is concrete and memorable.

### 16. Live demo: plan mode vs. auto-accept (6 min)
- Same task, two modes. Prepare a simple task in advance (e.g., "add a new variable to the panel").
- Show what a plan looks like, then the same task flying through in auto-accept. Plan mode is slower, but you see every decision.
- **Time risk:** if it's taking long, narrate what would happen rather than waiting for execution.

### 17. Exercise: county panel in plan mode (25 min)
- In the **`my_workspace/session_1`** copy, opened in a **new VS Code window** (File → New Window, then Open Folder). The data and codebooks are there from Session 1; the frame names the folder but not the new window.
- Pairs, both at one computer. Steps: short CLAUDE.md (~3 min; template in `references/CLAUDE_template.md` of the course repo), plan mode, prompt, read codebooks and evaluate the plan (~7 min), approve/revise and run (~7 min), check output.
- Keep "Evaluating the Plan" on screen as a checklist.
- If time is short, have pairs stop after the plan review. The learning is in the plan review, not the execution.
- Circulate and look for: not reading codebooks, accepting default variable definitions, not checking the join type.
- Debrief (~5 min): 2–3 pairs on variable coding decisions and what they rejected in the plan. Three lessons: CLAUDE.md forces explicitness, plan review forces pre-commitment, domain knowledge is non-delegable.

### 18. Core workflow (8 min)
- Coming right after the exercise, this frames what they just did: describe, review plan, generate and validate, save or re-instruct.
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

- **If running behind:** compress strategies 2–5 in block 14; in block 17, stop pairs after the plan review.
- **Boundary rule (plan principle 5):** don't start Part 1 (35 min) unless it can finish. If you reach block 22 with less than that, pull Session 3's first lecture block (verification extras, block 23) forward instead, and open Session 3 with Part 1. Its frames are in the Session 3 deck.
- **If running ahead:** let county-panel pairs run and verify their script.
