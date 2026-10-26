# Session 4 — Instructor Notes & Timing

**Power use: search, swarms, connected tools, skills. Target: 2:00, no break.**
Deck: `slides/session4_slides.tex`. Structure and clock come from `admin/course_plan_4_sessions.md` (blocks 30–39); the comment banners in the deck carry the same block numbers and clock times. Student exercise text is in `docs/exercise_prompt.md`. The previous Session 4 and Session 5 decks are kept in `slides/archive/`.

---

## Timing Overview

| Clock | # | Block | Frames | Min |
|-------|---|-------|--------|-----|
| 0:00 | — | Where we are, ritual | 2 | 3 |
| 0:03 | 35 | Connecting tools (MCP): what, where to find them, two-reason rule, Zotero demo, **exercise: mini literature review** (2 frames), helper not substitute | 9 | 20 |
| 0:23 | 36 | Skills (9 frames) and **sharing with coauthors** (2 frames) | 11 | 13 |
| 0:36 | 37 | **Exercise:** build a skill, deliverable | 2 | 15 |
| 0:51 | 30 | Web search and research: search vs. fetch, uses, deep research, reading sources vs. summaries, how citations fail, making output checkable. **Data exposure** (2 frames) and **keeping data private** in plain language (5 frames: how data reaches Claude, don't give it the real data, ways to limit access, what happens to what Claude reads, decoy test and disclaimer). The technical version is back matter H. Prompt injection moved to back matter G | 13 | 18 |
| 1:09 | 31 | **Exercise:** literature scan, spot-check every citation, debrief | 2 | 10 |
| 1:19 | 32 | Subagents and swarms; fan-out; verifier; token cost; **workflows** (2 frames, instructor demo); referee subagent (file, run); automated Part 1 checker | 15 | 14 |
| 1:33 | 33 | LLMs as research coders | 3 | 5 |
| 1:38 | 34 | **Exercise:** fan out the coding, compare, debrief | 3 | 15 |
| 1:53 | 38 | **Hooks:** what a hook is, when one can fire, what researchers use them for, what one looks like and how to handle with care | 4 | 5 |
| 1:58 | 39 | Wrap-up, where to go from here | 2 | 2 |

**Order differs from the plan.** Blocks 35–37 (MCP, skills, skill exercise) now come before block 30 (web search), so MCP follows directly from the Session 3 paper and its citations. Block numbers are the plan's. `admin/course_plan_4_sessions.md` still shows the old order. The queue's tail, which gets cut first if you run late, is now the fan-out exercise and hooks rather than the skill exercise.

**Total: 120 minutes on paper.** The main flow is 66 frames plus the title (the footer counts only these). Back matter is 53 frames and is not counted. Block 32 has 15 frames for 14 minutes; its cheapest cuts are "How to Trigger a Subagent" and the second "Why Define a Named Subagent" frame.

**Queue rule.** Cumulative drift from Sessions 2 and 3 lands here. If you start late, cut from the end of the queue: the wrap-up's second frame, then the last hooks frame ("What a Hook Looks Like"), then the length of the fan-out exercise (run two batches and compare only those). Do not start an exercise you cannot finish.

---

## Before the session (things that are not automatic)

1. **Reference codes.** `data/climate_speeches/gold_codes.csv` is stripped by `sync_student.sh` on purpose, so agents cannot read it. Participants need it at exercise step 3 (minute ~10 of block 34: steps 0-2 take 2 + 4 + 4 minutes). Decide how you hand it out (a link, a message, a USB stick) and have it ready. Participants save it to `data/climate_speeches/`. The exercise assumes this release.
2. **Install the agents for the demos, each in the right workspace.** The two demos read different files, so they run from different folders (the slides say the same). `mkdir -p .claude/agents` first, since a fresh copy has no such folder.
   - **Referee:** run from the Session 3 workspace (`~/my_workspace/session_3`, or the repo root `session_3/` if you demo from the clone), where the paper is `paper/course_paper.tex` (from the repo root: `session_3/paper/course_paper.tex`). `cp ../session_4/agents/referee.md .claude/agents/`.
   - **Merge-checker:** run from the **Session 2** workspace. The agent reads `data/swiss_franc_survey.csv`, `data/respondent_demographics.csv`, `docs/codebook.md` and the merged file `output/merged_survey.csv`, none of which exist in `session_4/`. `output/merged_survey.csv` is removed on the student branch, so it exists only where the Session 2 merge was built (your teacher copy has it). `cp ../session_4/agents/merge-checker.md .claude/agents/`. Participants only see this demo; they do not need to run it.
3. **Rehearse both demos once** and keep a fallback: `docs/referee_example_run.md` is a real run of the referee instructions on the Session 3 paper. For the checker demo, `session_2/docs/instructor_answer_key.md` ("Automated checker") has the expected values.
4. **Workflow demo (block 32, two frames).** The frames explain what a workflow is and why it costs more. The plan leaves the **demo script and its token cost undecided**, and asks to confirm the Workflow tool exists on the setup participants will use. Nothing in `session_4/` runs a workflow yet. Decide before the session, or present the two frames as concept only.
5. **Zotero demo (block 35).** Needs Zotero running with the Zotero MCP and the practice collection `claude_code_zotero` (`docs/claude_code_zotero/`). Participants do not need it installed.

---

## Notes by Block

### 30. Web search and research (16 min)
- The three-layer frame (snippet, fetched page, you reading it) and the citation-failure table carry the block. The dangerous row is "real paper, wrong claim": an existence check passes and the sentence is still wrong. Say this explicitly before the exercise.
- **Prompt injection is back matter G**, not main flow. It is a real, unsolved risk, but mostly demonstrated by researchers rather than documented in the wild, and a literature search in a folder with no credentials has little exposed. Block 30 is 18 minutes, 2 more than the plan. The fan-out exercise gave up 5 minutes (20 to 15) to pay for the privacy and hooks frames. If you need time back, cut "What Researchers Use It For" first.
- Data exposure: the stakes for this audience are IRB protocols and data-use agreements, not generic privacy.

- **Privacy frames: written for a non-technical audience.** The main flow explains the ideas (three ways data reaches Claude, the safest option, ways to limit access, retention, a decoy test). All settings names, JSON and commands moved to back matter H, which is structured around the four routes a file can take into the model. If your room is more technical, teach H instead of the main-flow frames. Verified against the docs on 2026-10-26: `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`, `CLAUDE_CODE_SKIP_PROMPT_HISTORY`, `DISABLE_FEEDBACK_COMMAND`, `CLAUDE_CODE_MCP_ALLOWLIST_ENV`, `claude purge`, `--setting-sources`, `--bare`, `--restricted` (documented for evaluation harnesses, not general use), `disableBypassPermissionsMode`, `strictAllowlist`, `failIfUnavailable`, user-level `allowUnsandboxedCommands: false` overriding projects (v2.1.285+), mods overriding deny rules, Read/Edit deny rules merged into the sandbox. **Left off the slides because I could not find them in the docs:** domain fronting, the 30,000-character bash-output cap, and the date auto mode became default. The three GitHub issues in your write-up were not checked. pay off Session 1's "Coming in Session 4: ignore rules and permission denies". Written from the Claude Code docs (`code.claude.com/docs/en/security`, `/data-usage`, `/permissions`) read on 2026-10-26: `Read` deny rules cover Claude's file tools and recognized shell commands such as `cat`, not a script that opens the file itself; a bare `.claudeignore` has no effect in Claude Code; consumer plans train on data when the privacy setting is on (5-year retention, else 30 days); commercial plans do not train by default (30 days; zero data retention for qualified Enterprise); local transcripts sit in plain text in `~/.claude/projects/` for 30 days by default; `/feedback` uploads the conversation. **Re-read those pages before class: plan terms and settings change.** Further details from `code.claude.com/docs/en/sandboxing` and `settings-reference`: the sandbox is off by default; it limits writes but not reads (reads of `~/.ssh`, `~/.aws` stay open unless you set `sandbox.filesystem.denyRead`); it covers shell commands and their child processes, **not** the built-in Read tool, so deny rules and the sandbox are complements; native Windows is unsupported (WSL2 works); a failed sandboxed command can be retried unsandboxed unless `allowUnsandboxedCommands` is false. **Unverified:** the JSON value type for `permissions.blockReadsOutsideWorkingDirectories` (I show `true`; the docs index only describes it as making file tools refuse reads outside the working directories) and the exact `denyRead` path semantics. Run both snippets on a test folder before class. I did not test the deny-rule snippet on a live session. **Folder is not a boundary:** the docs say Claude's file tools prompt before reading outside the working folder, but built-in read-only shell commands (`cat`, `grep`, `find`, ...) run without a prompt in every mode unless `permissions.blockReadsOutsideWorkingDirectories` is set. I have not tested whether `cat ~/elsewhere/file` runs unprompted on your setup; try it before class. Session 1's "Protecting Sensitive Files" frame says keeping data outside the folder is "the reliable rule", which this contradicts.

### 31. Exercise: literature scan (10 min)
- The scan is 3 minutes and the check 6. Expect people to stop checking after the first clean-looking paper. Circulate and ask "which column did you check for paper 4?"
- Participants check by hand, outside Claude Code. If someone asks Claude Code to verify its own list, name the reason (same process, same error) rather than forbidding it.
- Record the tally across the room; the debrief uses it. I have not run this exercise, so the failure rate is unknown. Do not promise participants that they will find fabrications; some runs will find none.

### 32. Subagents and swarms (14 min)
- Reused frames come from the old Session 5 deck. "Fan-Out" is new and is the template for exercise 34. "Token Cost" explains why block 34 starts with two batches.
- **Referee demo.** The definition is `agents/referee.md`. The example run in `docs/referee_example_run.md` was produced by a general-purpose agent given the file's body, not by a registered `referee` agent, so the live output will differ. The report's strongest points are the design/estimator mismatch (abstract says pre–post, only a post-period regression is run) and the 150 vs. 94 attendance question. **I have not verified either against `course_paper.tex` line by line.** Check them before presenting them as correct.
- **Checker demo** is the automated version of Session 2 Part 1. The frame is adapted from `slides/pending_session4_frames.tex` (now incorporated; kept for reference). Your own more automated version may supersede it.
- "Same model, different context": say this when presenting the verifier. A fresh agent removes the builder's context, not the model's blind spots.

### 33–34. LLMs as research coders (5 + 15 min)
- **The reference codes are Claude-generated** (Opus 5.5; see `data/climate_speeches/README.md`). Agreement will look better than it is; the slide "What Agreement Does and Does Not Show" says so, and the final debrief question (would you report these codes?) picks it up.
- **Reference-code facts (moved here from `data/climate_speeches/README.md`, which is student-facing and must not state them).** `gold_codes.csv` was coded by Claude (Opus 5.5) from `coding_scheme.md`, passage by passage. This was a deliberate choice: the exercise demonstrates the validation *workflow*, not a validated measure. Participants' agents are also Claude, so part of their agreement is the same model agreeing with itself; in a real project the reference set must come from human coders, ideally two.
- **Expected shape of results.** Reference distribution is 38 supports, 18 opposes, 5 no stance, 2 not climate; 7 passages are flagged "Hard case" in `gold_codes.csv` notes. Disagreements should concentrate there. I have not run the fan-out, so I do not know the actual agreement. Run it once beforehand to know what to expect.
- **Party shortcut.** Checked against `gold_codes.csv` and `passages.csv`: all 38 code-1 passages are Democrat; of the 18 code-2 passages, 14 are Republican and 4 have no party (`attribution` = `unattributed`, Senate leader remarks). Participants who give agents the full row can score well without reading. The exercise tells them to pass only `passage_id` and `passage_text`; look for people who did not.
- **Usage limits.** 63 passages over about six agents is small, but fan-out is where $20-plan participants are likeliest to hit the limit. The two-batch test is there so they see the cost first.
- `scripts/compare_to_reference.py` computes agreement, kappa, the confusion matrix and per-category agreement, and was tested on constructed inputs (self-comparison gives 1.0; six altered codes give 57/63). It is a check on Claude Code's numbers, not a replacement.
- **Open item:** `coding_scheme.md` still said "DRAFT, to be finalized before the gold set is hand-coded". The status line has been corrected and now says only that the scheme is a draft used as written; it no longer states who coded the reference set (that is in these notes and on the slides). The scheme's content has not been revised. Its "Hard cases to watch for" list is visible to students before the exercise.

### 35. MCP (8 min)
- **The Zotero exercise is back in the main flow** (12 min, after the demo), overriding the plan's "Zotero is demo-only". **Every participant now needs Zotero, the Zotero MCP, and the practice collection** (`docs/claude_code_zotero/`) installed beforehand. `admin/session4_prework.tex` has been rewritten for the current deck: Zotero and workspace setup only, with the GitHub token, username and collaborator steps removed (the GitHub MCP is an instructor demo in back matter E). Its PDF was recompiled. The RDF import steps are also in `session_4/README.md` ("Before Exercise 1"). Anyone without it can watch a neighbor or skip to the next block. The GitHub MCP demo is back matter E.
- "Where to Find MCPs" (second frame) lists `modelcontextprotocol.io`, the `modelcontextprotocol/servers` repository, the Claude apps' connector directory, GitHub search, and `claude mcp add` / `/mcp`. Written from memory; open each before class to confirm the names and URLs are current.
- "Helper, not substitute" carries the block-30 connection: every MCP is also an access grant.

### 36. Skills and sharing (13 min)
- Skill frames are the old Session 4 frames. Dropped from the main flow and moved to back matter F: the crowdsourced-skill demo, the heuristic frame, "Finding Good Use Cases Is Hard", the `tex-reference-audit` worked example, and skills + MCPs. The "strong recommendation" (build one, then another) is folded into "How to Build One That Works".
- The **sharing** frames are new. They state, from my knowledge of Claude Code, that project-level `.claude/` (skills, agents, `settings.json`) and `CLAUDE.md` travel with the folder, that `settings.local.json` is personal, and that plugins bundle skills, agents, hooks and connections. I did not verify the current plugin mechanics in this session; check them before teaching the plugin frame.

### 37. Exercise: build a skill (15 min)
- Shortened from 25 to make room for the Zotero exercise: pick 2, route 1, write 6, install 1, try 5. Otherwise unchanged from the old deck. Expect most people to finish one pass but not to iterate on the description; the deliverable frame asks for what they would change. Participants write `SKILL.md` themselves; a skill built by asking Claude Code to "make me a skill" skips the point (the convention is theirs).

### 38–39. Hooks, wrap-up (7 min)
- **`claude-ignore` was dropped** from the deck (the privacy frames cover that ground with first-party deny rules; the old frames are in `slides/archive/`). Block 38 now explains hooks for a non-technical audience: the idea, the moments they fire, research uses, and a looks-like example. The docs' examples are the notification hook and a protected-files hook; the audit-log example in back matter B was **rewritten**, because the old version read the command from `$CLAUDE_TOOL_INPUT`, whereas the docs say hooks receive event data as JSON on stdin. I ran the new log command's shell pipeline on a sample input; I did not run it as an installed hook. It needs `jq`. The notification example is macOS-only.

---

## Back matter

| Block | Source | Notes |
|---|---|---|
| A. Replication package | new | Written from general knowledge of data-editor README templates. Not tested against a real submission. |
| B. Research audit log hook; hook vs. skill vs. agent | old S5, example rewritten | Needs `jq`. |
| C. Beyond the terminal | old S5 | Unedited. Claims about cloud, remote control and the API were not re-checked and may be out of date. |
| D. Failure diagnosis | syllabus | **Needs transcripts.** `admin/failure_examples/` is empty. Frames work with participants' own failed sessions in the meantime. Until transcripts exist, the exercise is only usable if participants bring a failed session of their own; do not teach it as a transcript exercise. |
| E. GitHub MCP | old S4 | Instructor demo; builds on the Session 3 back matter. Needs a GitHub token. |
| F. Skill extras | old S4 | Added to the plan's list so no frame is deleted. |
| G. Prompt injection | new | Moved out of block 30. Its example frame is illustrative, not a working attack. |
| H. Data privacy, technical | new | The settings-level version of block 30's privacy frames: the four routes, deny rules, sandbox config, canary commands, env-var scrub, hooks, untrusted repositories (9 frames). Linked from the "Ways to Limit What Claude Can See" frame. |

---

## Material in `session_4/` that no slide uses

- **Debugging exercise.** `scripts/buggy_script.py` and `scripts/base_regression.py` are removed on the student branch and no slide or student-facing file refers to them. Only `demo_prompt.txt` (which tells the reader to extend `scripts/base_regression.py`) and `docs/instructor_notes_debugging.md` mention them. The deck has no debugging exercise.
- **`demo_prompt.txt` and `demo_output/`** (finished regression tables) come from an earlier demo. They are not referenced by any slide or README and are not on the sync removal list, so students receive them.
- **`docs/referee_example_run.md`** is the fallback for the referee demo and is on the student branch. It shows what the demo finds on the Session 3 paper.
- **`option_b/`** has no instructions anywhere in the Session 4 materials.
- **`github_collaboration_practice/`** is not on any slide. Its scaffold has 16 chapter files but the premises have prompts for chapters 1-8 only (see its `INSTRUCTOR.md`). Pre-assign chapters in `CHAPTERS.md` (there is no `PAIRS.md`).

---

## Risks

- **Usage limits** during the fan-out exercise (see block 34).
- **Late start.** Sessions 2 and 3 are over by 1–2 minutes each, and their overflow arrives here. The exercises (31, 34, 37) take 55 of the 120 minutes and are the least compressible.
- **Citation exercise has no known failure rate.** See block 31.
