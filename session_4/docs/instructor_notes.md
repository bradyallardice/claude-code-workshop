# Session 4 — Instructor Notes & Timing

**Power use: search, swarms, connected tools, skills. Target: 2:00, no break.**
Deck: `slides/session4_slides.tex`. Structure and clock come from `admin/course_plan_4_sessions.md` (blocks 30–39); the comment banners in the deck carry the same block numbers and clock times. Student exercise text is in `docs/exercise_prompt.md`. The previous Session 4 and Session 5 decks are kept in `slides/archive/`.

---

## Timing Overview

| Clock | # | Block | Frames | Min |
|-------|---|-------|--------|-----|
| 0:00 | — | Where we are, ritual | 2 | 3 |
| 0:03 | 30 | Web search and research: search vs. fetch, uses, deep research, reading sources vs. summaries, how citations fail, making output checkable. **Prompt injection** (3 frames), **data exposure** (2 frames) | 11 | 16 |
| 0:19 | 31 | **Exercise:** literature scan, spot-check every citation, debrief | 2 | 10 |
| 0:29 | 32 | Subagents and swarms; fan-out; verifier; token cost; **workflows** (2 frames, instructor demo); referee subagent (file, run); automated Part 1 checker | 15 | 14 |
| 0:43 | 33 | LLMs as research coders | 3 | 5 |
| 0:48 | 34 | **Exercise:** fan out the coding, compare, debrief | 3 | 20 |
| 1:08 | 35 | Connecting tools (MCP): what, two-reason rule, Zotero demo, helper not substitute | 6 | 8 |
| 1:16 | 36 | Skills (9 frames) and **sharing with coauthors** (2 frames) | 11 | 13 |
| 1:29 | 37 | **Exercise:** build a skill, deliverable | 2 | 25 |
| 1:54 | 38 | Hooks: `claude-ignore` only | 2 | 4 |
| 1:58 | 39 | Wrap-up, where to go from here | 2 | 2 |

**Total: 120 minutes on paper.** The main flow is 59 frames plus the title (the footer counts only these). Back matter is 44 frames and is not counted. Block 32 has 15 frames for 14 minutes; its cheapest cuts are "How to Trigger a Subagent" and the second "Why Define a Named Subagent" frame.

**Queue rule.** Cumulative drift from Sessions 2 and 3 lands here. If you start late, cut from the end of the queue: the wrap-up's second frame, then the `claude-ignore` install frame, then the tail of the skills exercise. Do not start an exercise you cannot finish.

---

## Before the session (things that are not automatic)

1. **Reference codes.** `data/climate_speeches/gold_codes.csv` is stripped by `sync_student.sh` on purpose, so agents cannot read it. Participants need it at exercise step 3 (minute ~14 of block 34). Decide how you hand it out (a link, a message, a USB stick) and have it ready. Participants save it to `data/climate_speeches/`. The exercise assumes this release.
2. **Install the agents for the demos.** Copy `agents/referee.md` and `agents/merge-checker.md` into `.claude/agents/` in the workspace you will demo from. The referee demo targets `session_3/paper/course_paper.tex`.
3. **Rehearse both demos once** and keep a fallback: `docs/referee_example_run.md` is a real run of the referee instructions on the Session 3 paper. For the checker demo, `session_2/docs/instructor_answer_key.md` ("Automated checker") has the expected values.
4. **Workflow demo (block 32, two frames).** The frames explain what a workflow is and why it costs more. The plan leaves the **demo script and its token cost undecided**, and asks to confirm the Workflow tool exists on the setup participants will use. Nothing in `session_4/` runs a workflow yet. Decide before the session, or present the two frames as concept only.
5. **Zotero demo (block 35).** Needs Zotero running with the Zotero MCP and the practice collection `claude_code_zotero` (`docs/claude_code_zotero/`). Participants do not need it installed.
6. **Node.js** must already be installed (Session 3 "Next Session" frame asks for it). Ask at the start; `claude-ignore` needs `npm`.

---

## Notes by Block

### 30. Web search and research (16 min)
- The three-layer frame (snippet, fetched page, you reading it) and the citation-failure table carry the block. The dangerous row is "real paper, wrong claim": an existence check passes and the sentence is still wrong. Say this explicitly before the exercise.
- Prompt injection: the example frame is illustrative, not a demonstration that works against current models. Present it as a class of problem. The three-capability point (read sensitive data, act, send out) is what to leave them with.
- Data exposure: the stakes for this audience are IRB protocols and data-use agreements, not generic privacy.

### 31. Exercise: literature scan (10 min)
- The scan is 3 minutes and the check 6. Expect people to stop checking after the first clean-looking paper. Circulate and ask "which column did you check for paper 4?"
- Participants check by hand, outside Claude Code. If someone asks Claude Code to verify its own list, name the reason (same process, same error) rather than forbidding it.
- Record the tally across the room; the debrief uses it. I have not run this exercise, so the failure rate is unknown. Do not promise participants that they will find fabrications; some runs will find none.

### 32. Subagents and swarms (14 min)
- Reused frames come from the old Session 5 deck. "Fan-Out" is new and is the template for exercise 34. "Token Cost" explains why block 34 starts with two batches.
- **Referee demo.** The definition is `agents/referee.md`. The example run in `docs/referee_example_run.md` was produced by a general-purpose agent given the file's body, not by a registered `referee` agent, so the live output will differ. The report's strongest points are the design/estimator mismatch (abstract says pre–post, only a post-period regression is run) and the 150 vs. 94 attendance question. **I have not verified either against `course_paper.tex` line by line.** Check them before presenting them as correct.
- **Checker demo** is the automated version of Session 2 Part 1. The frame is adapted from `slides/pending_session4_frames.tex` (now incorporated; kept for reference). Your own more automated version may supersede it.
- "Same model, different context": say this when presenting the verifier. A fresh agent removes the builder's context, not the model's blind spots.

### 33–34. LLMs as research coders (5 + 20 min)
- **The reference codes are Claude-generated** (Opus 5.5; see `data/climate_speeches/README.md`). Agreement will look better than it is. This is a debrief point, and the slides say so.
- **Expected shape of results.** Reference distribution is 38 supports, 18 opposes, 5 no stance, 2 not climate; 7 passages are flagged "Hard case" in `gold_codes.csv` notes. Disagreements should concentrate there. I have not run the fan-out, so I do not know the actual agreement. Run it once beforehand to know what to expect.
- **Party shortcut.** In this sample every code 1 is a Democrat and every code 2 a Republican or unattributed Senate leader. Participants who give agents the full row can score well without reading. The exercise tells them to pass only `passage_id` and `passage_text`; look for people who did not.
- **Usage limits.** 63 passages over about six agents is small, but fan-out is where $20-plan participants are likeliest to hit the limit. The two-batch test is there so they see the cost first.
- `scripts/compare_to_reference.py` computes agreement, kappa, the confusion matrix and per-category agreement, and was tested on constructed inputs (self-comparison gives 1.0; six altered codes give 57/63). It is a check on Claude Code's numbers, not a replacement.
- **Open item:** `coding_scheme.md` still said "DRAFT, to be finalized before the gold set is hand-coded". The gold set was Claude-coded, so the status line has been corrected. The scheme's content has not been revised.

### 35. MCP (8 min)
- Zotero is demo-only. The GitHub MCP demo moved to back matter F.
- "Helper, not substitute" carries the block-30 connection: every MCP is also an access grant.

### 36. Skills and sharing (13 min)
- Skill frames are the old Session 4 frames. Dropped from the main flow and moved to back matter G: the crowdsourced-skill demo, the heuristic frame, "Finding Good Use Cases Is Hard", the `tex-reference-audit` worked example, and skills + MCPs. The "strong recommendation" (build one, then another) is folded into "How to Build One That Works".
- The **sharing** frames are new. They state, from my knowledge of Claude Code, that project-level `.claude/` (skills, agents, `settings.json`) and `CLAUDE.md` travel with the folder, that `settings.local.json` is personal, and that plugins bundle skills, agents, hooks and connections. I did not verify the current plugin mechanics in this session; check them before teaching the plugin frame.

### 37. Exercise: build a skill (25 min)
- Unchanged from the old deck. Participants write `SKILL.md` themselves; a skill built by asking Claude Code to "make me a skill" skips the point (the convention is theirs).

### 38–39. Hooks, wrap-up (6 min)
- `claude-ignore` is the enforcing mechanism behind Session 1's "protect sensitive files". The general hook material (audit log, hook vs. skill vs. agent) is back matter C.

---

## Back matter

| Block | Source | Notes |
|---|---|---|
| A. Replication package | new | Written from general knowledge of data-editor README templates. Not tested against a real submission. |
| B. Zotero mini literature review | old S4 | Needs Zotero installed. |
| C. Hooks worked example | old S5 | |
| D. Beyond the terminal | old S5 | Unedited. Claims about cloud, remote control and the API were not re-checked and may be out of date. |
| E. Failure diagnosis | syllabus | **Needs transcripts.** `admin/failure_examples/` is empty. Frames work with participants' own failed sessions in the meantime. |
| F. GitHub MCP | old S4 | Instructor demo; builds on the Session 3 back matter. Needs a GitHub token. |
| G. Skill extras | old S4 | Added to the plan's list so no frame is deleted. |
| H. Capstone | old S5 | Slides rewritten for a local git repo (steps 2, 2b). **`capstone-template/README.md`, `INSTRUCTOR.md` and `ROLES.md` still describe GitHub repos and pull requests**, so the slides and the README disagree until those are rewritten. |

---

## Risks

- **Usage limits** during the fan-out exercise (see block 34).
- **Late start.** Sessions 2 and 3 are over by 1–2 minutes each, and their overflow arrives here. The exercises (31, 34, 37) take 55 of the 120 minutes and are the least compressible.
- **Citation exercise has no known failure rate.** See block 31.
