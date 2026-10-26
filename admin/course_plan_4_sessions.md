# Course Plan — Claude Code for Academic Researchers (4 × 2 hours)

Final plan, agreed 2026-10-26. Supersedes the five-session structure in `README.md`, `admin/syllabus.md`, and the per-session instructor notes, none of which have been updated yet (see "Documents to update").

---

## Principles

1. **Four sessions, two hours each, no breaks.**
2. **Session 1 content is not cut.** If it runs long, the remainder moves into Session 2.
3. **The course is one continuous queue.** Each session starts wherever the previous one stopped. The session tables below give *target* landing points, not hard splits.
4. **If time runs out, the tail gets cut, and that is fine.** The queue order is the priority order. Cumulative drift lands at the end of Session 4.
5. **Boundary rule:** do not start an exercise that cannot be finished in the time left. Pull the next lecture block forward instead.
6. **Pacing:** about 1 minute per lecture frame on average. Exercises keep their full time, because participants set their pace, not the presenter.
7. **GitHub and the capstone leave the main flow.** Local git stays, taught as the undo button for agent edits. LaTeX stays.
8. **Nothing is deleted.** Material outside the main flow moves to a back-matter section at the end of a deck (see "Back-matter mechanics").

---

## Session 1 — What it is and how it works

**Deck:** old `session1_slides.tex` from the title frame through the CLAUDE.md frames, plus the CLAUDE.md exercise, plus a new closing frame. The context-strategy material goes to Session 2.

| # | Block | Min | Clock |
|---|---|---|---|
| 1 | Title, About Me, intros, roadmap, core framework | 15 | 0:15 |
| 2 | Your workspace, start-of-session ritual, setup check (incl. test `.tex` compile) | 6 | 0:21 |
| 3 | Live demo: the task, the data, same task two ways, what just happened | 8 | 0:29 |
| 4 | Paradigm spectrum (4), why agentic is different, Code vs. Cowork | 6 | 0:35 |
| 5 | Where Claude Code lives, terminal, front doors, VS Code, Python, `.py` vs. `.ipynb`, scripts, virtual envs, Stata port | 14 | 0:49 |
| 6 | Capabilities, RA analogy, a tool built for software engineers, do you own it, why verification matters, control principle | 7 | 0:56 |
| 7 | **Exercise:** your first commands, then debrief | 15 | 1:11 |
| 8 | How Claude Code works, opening it in the project, permissions, risk levels, restricting to the project, protecting sensitive files, drag-and-drop | 8 | 1:19 |
| 9 | AI skill gap | 3 | 1:22 |
| 10 | Choosing a model, when to use each, research perspective, effort, cost management, usage limits | 9 | 1:31 |
| 11 | What is context, context window, where Claude looks, the hierarchy, everything Claude reads before you type | 9 | 1:40 |
| 12 | CLAUDE.md: lab notebook, what belongs, example, where it acts in the loop | 5 | 1:45 |
| 13 | **Exercise:** build a CLAUDE.md for your own project | 12 | 1:57 |

The intros block (15 min) assumes 8–10 participants, so a larger group shifts everything later.

**Back matter:** none.

---

## Session 2 — Context strategies, parallel sessions, plan mode, verification begins

**Deck:** context strategies, execution modes, and verification frames from old `session2_slides.tex`, plus the county-panel exercise and plan-evaluation frames from old Session 1 Part B. The parallel-session material is new.

| # | Block | Min | Clock |
|---|---|---|---|
| — | Start-of-session ritual | 3 | 0:03 |
| 14 | **Context strategies:** what happens when the window fills, keep tasks focused, what counts as one task, one conversation per task, multiple tabs, keeping track of conversations, maintaining project docs, starting a new project in VS Code, summarizing between conversations, validating iteratively, token-aware prompting. Demos included. **Parallel-session demo:** two read-only tasks in two tabs at once, then a collision round (both tabs write to the same output file), then a benefits/risks frame. | 25 | 0:28 |
| 15 | Execution modes: plan / default / auto-accept | 5 | 0:33 |
| 16 | Live demo: plan mode vs. auto-accept | 6 | 0:39 |
| 17 | **Exercise:** build the county panel in plan mode, evaluate the plan, debrief | 25 | 1:04 |
| 18 | The core workflow (describe → plan → generate → verify → save/re-instruct), code can run and still be wrong, read the code | 8 | 1:12 |
| 19 | Verification: two layers of tests, independent tests, write expectations first, trace samples, test-first cycle, test the tests, passing is not the goal | 10 | 1:22 |
| 20 | Make it a rule in CLAUDE.md (1/2, 2/2) | 2 | 1:24 |
| 21 | The Swiss franc shock: data and research question | 3 | 1:27 |
| 22 | **Exercise Part 1, two tabs.** *Builder:* step 0 installs the verification protocol, then merge and explore in plan mode. *Checker* (fresh tab, never sees the builder's conversation): writes expectations and checks from the codebook and research question only. Run the checker's checks on the builder's output. Debrief: where did the tabs disagree, which decisions had to be written into files, did anyone lose work to a collision? | 35 | 2:02 |

**What the parallel-session material teaches:**

- **Benefits:** throughput on independent tasks; a clean context per task; a fresh session as a genuinely independent checker.
- **Risks:**
  - Sessions share no memory except files. A tab already open loaded CLAUDE.md when it started, so it won't see later edits unless it re-reads the file.
  - Collisions: when two sessions write the same output, the last writer wins.
  - Your review attention is split between streams of output.
  - A hidden tab can stall on a permission prompt.
  - Token use scales with the number of sessions.
- **The same applies to multiple ChatGPT or claude.ai chats.**

Claude Code may notice the collision in the demo and adapt. That is fine to show as it happens.

**Back matter:** none.

---

## Session 3 — Verification through to the paper

**Deck:** the rest of the old Session 2 verification material and exercises, the LaTeX and git frames from old `session3_slides.tex`, and the Overleaf bridge frames from old `session4_slides.tex` (lines 683–720). The Overleaf bridge uses Overleaf's own git remote, with no GitHub involved.

| # | Block | Min | Clock |
|---|---|---|---|
| — | Ritual and check-in. **Participants reopen their Session 2 folder**, because Part 2 continues that project. | 5 | 0:05 |
| 23 | Verification extras: requirements-to-tests matrix, audit report, two more safeguards, what to delegate / verify / keep | 5 | 0:10 |
| 24 | **Exercise Part 2:** specify and estimate, then "what happened to your sample?" | 25 | 0:35 |
| 25 | Robustness workflow, then **Exercise Part 3:** robustness variants and a LaTeX table | 25 | 1:00 |
| 26 | LaTeX in VS Code (the problem with Overleaf, setup, LaTeX Workshop, Problems pane, why it matters for Claude Code). Git as the undo button (minimum workflow, init/add/commit/diff/log/checkout, the cycle, `.gitignore`, where data goes). Overleaf bridge. | 22 | 1:22 |
| 27 | Live demo: building a paper, the full loop | 8 | 1:30 |
| 28 | **Exercise: results → paper.** Render the table (`session_2/scripts/render_regression_table.py`) into a paper skeleton. Commit, have Claude write the results paragraph, read the diff, revert if needed. Then have Claude cross-check every number in the text against the table. | 25 | 1:55 |
| 29 | When it goes wrong: failure patterns (looping, confidently wrong, scope creep, coherence loss); correct vs. restart vs. do it yourself | 6 | 2:01 |

**Back matter (index frame first):**

| Block | Source | Min |
|---|---|---|
| A. LaTeX basics for newcomers (jump-link from block 26) | old S3 | 5 |
| B. GitHub: what it is, vocabulary, branches, PRs, push vs. PR, troubleshooting, anatomy of a merge conflict, resolving by hand, letting Claude resolve it | old S3/S4 | 15–20 |
| C. *Reference only:* GitHub collaboration exercise ("Your Chapter"). It needs accounts and collaborator access set up in advance. | old S4 | — |

---

## Session 4 — Power use: search, swarms, connected tools, skills

**Deck:** subagent frames from old `session5_slides.tex`, MCP and skills frames from old `session4_slides.tex`, the `claude-ignore` frame from old Session 5. Web search, prompt injection, LLM-as-coder, referee subagent, and sharing-with-coauthors material is new.

| # | Block | Min | Clock |
|---|---|---|---|
| — | Start-of-session ritual | 3 | 0:03 |
| 30 | **Web search and research:** search and fetch, deep research, reading sources vs. trusting summaries, checking that citations exist. **Prompt injection** (web pages, PDFs, and emails can contain instructions to the agent) and **data exposure** (a connector grants access to the whole account). | 16 | 0:19 |
| 31 | **Exercise:** search-backed literature scan, then spot-check every citation | 10 | 0:29 |
| 32 | Subagents and swarms: what a subagent is, where it shines, triggering, fan-out, composition patterns, one agent or many, the subagent as verifier, token cost. Worked example: a **referee subagent** defined in a file and run on the Session 3 paper. | 14 | 0:43 |
| 33 | **LLMs as research coders:** a coding scheme as a measurement instrument, validating against hand codes, agreement | 5 | 0:48 |
| 34 | **Exercise:** fan out agents to code climate mentions in Congressional Record speeches (`session_4/data/climate_speeches/`) in batches, compare with the hand-coded gold set (agreement rate, confusion matrix, failing categories), debrief ("would you report these codes in a paper?") | 20 | 1:08 |
| 35 | Connecting tools: what an MCP is, the two-reason rule, Zotero demo, MCP as helper not substitute | 8 | 1:16 |
| 36 | Skills: what a skill does, how it works, where skills live, the routing rule, verification vs. production, skills I use, how to build one. **Sharing your setup with coauthors and your lab:** project-level `.claude/` and CLAUDE.md in the shared folder, plugins. | 13 | 1:29 |
| 37 | **Exercise:** build a skill | 25 | 1:54 |
| 38 | Hooks: `claude-ignore` only (the enforcing mechanism behind Session 1's "protect sensitive files") | 4 | 1:58 |
| 39 | Wrap-up | 2 | 2:00 |

**Back matter (index frame first):**

| Block | Source | Min |
|---|---|---|
| A. Replication package: build or audit one (README to data-editor standards, run-all script, pinned environment) | new | 20+ |
| B. Zotero mini literature review exercise | old S4 | 15 |
| C. Hooks worked example: research audit log; hook vs. skill vs. agent | old S5 | 8 |
| D. Beyond the terminal: cloud, teleport and remote control, scheduled tasks, customizing your environment, scraping, Claude API, API vs. Claude Code | old S5 | 20+ |
| E. Failure diagnosis exercise (needs transcripts) | syllabus | 12 |
| F. GitHub MCP, instructor demo only | old S4 | 5 |
| G. *Reference only:* capstone, self-guided, steps 2a–2c rewritten for a local git repo | old S5 | 50+ |

---

## Back-matter mechanics

- `\appendix` after each deck's closing frame, with `\usepackage{appendixnumberbeamer}`, so the Madrid footer's "*n* / *total*" counts the main flow only.
- An index frame opens the back matter. It lists each block with its time estimate and a `\hyperlink` to it. Each block ends with a link back to the index. This extends the existing `label=troubleshooting` pattern in old `session4_slides.tex`.
- Blocks are ordered by how likely they are to be used, with reference-only items last.
- `\hyperlink` does not work across separate PDFs, so a jump-link must point into the same deck.

---

## Prework changes

- **Add:** a "compile this test `.tex`" step. Session 3's LaTeX block has only 22 minutes and cannot absorb install problems.
- **Remove:** the GitHub username, personal access token, and GitHub MCP steps from `admin/session4_prework.tex`.
- **Keep:** `git clone` / `git pull` as the copy-paste delivery ritual (not taught as GitHub). "If `git pull` fights back" can go to back matter.
- **Move earlier:** Node.js is needed for `claude-ignore` (installed with `npm`). The README says to install it before Session 5, but it is now needed for Session 4.
- **Zotero is demo-only in the main flow,** so participants don't need it installed. Only back-matter block B requires it.

---

## New material to build

| Session | Item | Notes |
|---|---|---|
| 1 | Closing frame | The deck now ends on the CLAUDE.md exercise |
| 2 | Opening frame (where we are, ritual) | |
| 2 | Parallel-tab version of "Demo: Keeping Tasks Focused", plus collision round | Rehearse it, and keep a screenshot as fallback |
| 2 | Benefits/risks frame for parallel sessions | Includes the ChatGPT/claude.ai point |
| 2 | Two-tab Part 1: builder and checker role cards, debrief frame | |
| 3 | "Reopen your Session 2 folder" instruction | Part 2 continues the S2 project |
| 3 | Results → paper exercise and a paper skeleton `.tex` | |
| 4 | Web search block and literature-scan exercise | |
| 4 | Prompt injection and data exposure frames | |
| 4 | Fan-out / swarm frames | |
| 4 | LLM-as-coder frames, plus **a corpus of ~50–100 short texts with a coding scheme and hand-coded gold labels** | Main prep cost. Nothing like it exists in the repo yet. |
| 4 | Referee subagent definition file and example run | |
| 4 | Sharing-with-coauthors frame | |
| 3, 4 | Back-matter index frames | |
| 4 | Replication-package back-matter block | |
| 4 | Failure transcripts in `admin/failure_examples/` | Currently empty. Only needed for back-matter block E. |

## Existing frames to edit

- `session1_slides.tex:264` (setup check) says "We'll troubleshoot at break." There is no break now.
- The last frame of old `session1_slides.tex` is titled "Module 2 Summary."
- In "Multiple Claude Code Tabs" (old `session2_slides.tex:305`), "I'll show this live" becomes redundant once the demo exists.
- "Demo: Keeping Tasks Focused" (old `session2_slides.tex:282`) changes from sequential to parallel conversations.
- Exercise frames with times in their titles need to match the new times (Part 1 is now 35 min, Part 3 is now 25).
- GitHub frames moved to back matter refer to "the course repo", "the problem we had", and the Session 4 prework.
- Frames from old Session 5 refer to "today" and to the capstone.
- The link at old `session4_slides.tex:581` points to the troubleshooting frames, which move to the Session 3 deck.

## Documents to update

- `README.md`: the sessions table (5 → 4), the line about `session_6/`–`session_9/`, and the Node.js timing.
- `admin/syllabus.md`: still describes 5 sessions, GitHub, and the capstone.
- `session_1/docs/instructor_notes.md` and `session_2/docs/instructor_notes.md`: old module numbering and a 10-minute break built into the clock. Instructor notes for sessions 3–5 have no timing tables.
- `admin/session4_prework.tex`: remove the GitHub sections.

---

## Open decision

**Session folder numbering.** Session 3 now uses the Swiss franc material in `session_2/`, and Session 4 draws on `session_4/` and `session_5/`.

- **Renumbering** keeps the ritual ("copy `session_N/`") consistent with the session number. But hardcoded `session_N/` paths appear in 15 files for `session_1/`, 31 for `session_2/`, 19 for `session_3/`, and 4 each for `session_4/` and `session_5/` (counted across each folder and the slide sources).
- **Keeping the names** avoids that work, but students would copy a folder whose number doesn't match the session.

## Risks

- **Usage limits.** Two-tab Part 1 (Session 2) and fan-out coding (Session 4) each multiply token use. On the $20 plan these are the points where participants are most likely to hit the 5-hour limit. Keep the checker's job and the coding corpus small.
- **No slack.** Sessions 2 and 3 are already 1–2 minutes over on paper. At the old pace (~1.3 min/frame), cumulative drift by the end of the course would be about 70 minutes, which cuts into Session 4's skills exercise and hooks.
- **Session 1 variance.** Intros scale with group size, and the setup check has no break to absorb troubleshooting.
- **Part 2 crosses a session boundary.** Participants must keep their Session 2 workspace intact between sessions.
