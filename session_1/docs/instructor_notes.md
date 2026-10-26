# Session 1 — Instructor Notes & Timing

**What it is and how it works. Target: 2:00, no break.**
Deck: `slides/session1_slides.tex`. Structure and clock come from
`admin/course_plan_4_sessions.md` (blocks 1–13); the comment banners in the deck
carry the same block numbers and clock times.

---

## Timing Overview

| Clock | # | Block | Min |
|-------|---|-------|-----|
| 0:00 | 1 | Title, About Me, introductions, roadmap, core framework | 15 |
| 0:15 | 2 | Your workspace, start-of-session ritual, setup check (incl. test `.tex` compile) | 6 |
| 0:21 | 3 | Live demo: the task, the data, same task two ways, what just happened | 8 |
| 0:29 | 4 | Paradigm spectrum (4 frames), why agentic is different, Code vs. Cowork | 6 |
| 0:35 | 5 | Where Claude Code lives, terminal, front doors, VS Code, Python, `.py` vs. `.ipynb`, scripts, virtual envs, Stata port | 14 |
| 0:49 | 6 | Capabilities, RA analogy, a tool built for software engineers, do you own it, why verification matters, control principle | 7 |
| 0:56 | 7 | **Exercise:** your first commands, then debrief | 15 |
| 1:11 | 8 | How Claude Code works, opening it in the project, permissions, risk levels, restricting to the project, protecting sensitive files, drag-and-drop | 8 |
| 1:19 | 9 | AI skill gap | 3 |
| 1:22 | 10 | Choosing a model, when to use each, research perspective, effort, cost management, usage limits | 9 |
| 1:31 | 11 | What is context, context window, where Claude looks, the hierarchy, everything Claude reads before you type | 9 |
| 1:40 | 12 | CLAUDE.md: lab notebook, what belongs, example, where it acts in the loop | 5 |
| 1:45 | 13 | **Exercise:** build a CLAUDE.md for your own project | 12 |
| 1:57 | — | Session 1 summary | 3 |

**Total: 120 minutes.** The intros budget assumes 8–10 participants; a larger
group shifts everything later.

---

## Notes by Block

### 1. Welcome, introductions, roadmap, framework (15 min)
- Keep your own intro to ~3 min. The slides have plenty of detail; don't read them.
- Participant intros: enforce a strict ~1 min per person. With 8–10 people this is 8–10 min. If the group is larger than 10, ask only name + department + one sentence on AI use, or do a show of hands instead.
- **Time risk:** this is the biggest flex point. If intros run long, everything after shifts.
- **Unresolved:** the Pre-Course Survey frame says "fill this out now (about 10 minutes)". Those 10 minutes are not in this block's 15. Either the survey goes out before Session 1 and the frame becomes a reminder, or block 1 runs ~10 min over.
- Roadmap + framework: quick orientation. Hit the PI/RA analogy once here; it comes back in block 6.

### 2. Workspace, ritual, setup check (6 min)
- Do the ritual live, together. Then `claude --version`, launch `claude`, and compile `setup_check.tex` (it loads every package the Session 3 paper uses).
- **There is no break to troubleshoot in.** Pair anyone stuck with a set-up neighbor and keep going; fix problems while circulating during the first exercise (block 7).
- Write down the names of anyone whose `setup_check.tex` fails. Session 3's LaTeX block has 22 minutes and cannot absorb install problems, so these must be fixed before then.
- The two failures to expect: BasicTeX missing a package (`makecell.sty not found`, fixed with `sudo tlmgr install makecell`) and MiKTeX on Windows without Perl, so VS Code's latexmk build fails. Both are in the pre-work guide's Troubleshooting section.

### 3. Live demo (8 min)
- Run sheet: `admin/session1_demo_instructions.md`. The demo prompt is in `session_1/docs/demo_prompt.md`; have it ready to paste.
- Goal: wow factor. Show Claude Code reading two datasets, writing a merge script, and running it. Don't narrate every step; let them watch.
- If the demo runs long (network lag, errors), narrate what's happening and move on. You can show the finished output.
- What Just Happened: the key moment is that Claude Code made an analytical decision on its own (the "alert" slide). This sets up the course theme.

### 4. Paradigm spectrum, why agentic, Code vs. Cowork (6 min)
- Move through the first three paradigms quickly (~1 min each). They're reference points.
- Spend the remaining time on agentic coding and "Why Agentic Coding Is Different": the tool acts on your project directly. That is the punchline.

### 5. Orientation: terminal, VS Code, Python, scripts, environments (14 min)
- **Calibrate to the room.** If most participants are comfortable with the terminal, move faster and bank the time. If many are new to it, slow down.
- Terminal: show `pwd`, `ls`, `cd` live if possible.
- Why Python: acknowledge the room may prefer R/Stata. Be brief and non-defensive. The Stata port example is the bridge for Stata users.
- `.py` vs. `.ipynb` and "why scripts": this framing matters for the rest of the course.
- Virtual environments: keep it conceptual. Setup was in pre-work. Don't live-code `python3 -m venv` unless someone needs it.

### 6. Capabilities through the control principle (7 min)
- Capabilities: scan, don't read every bullet. They'll see it in practice.
- The RA analogy should land with this audience. Spend an extra beat here.
- A tool built for software engineers: "works = runs correctly" vs. "works = ???" reframes expectations.
- Do You Own It?: the 30-second test is concrete and memorable. Ask the room.
- Why Verification Matters: three concrete failure modes. Read them and let them sink in.
- Control Principle: one slide, one sentence. Don't over-explain.

### 7. Exercise: your first commands (15 min)
- Python, R, or Stata starter scripts in `session_1/scripts/exercise_build_panel.*`.
- Task 1 (explain the script) is the priority for everyone. Task 2 adds checks and documentation. Task 3 changes a variable definition (two-party to total vote share).
- Roughly 11 min of work and 4 min of debrief ("What did it get right? Anything wrong or confusing?").
- This is your troubleshooting window for anyone stuck at the setup check.
- "What's Ahead" (1 frame) follows the debrief. It is the first thing to cut if behind.

### 8. How Claude Code works, permissions, sensitive files (8 min)
- Walk through the risk-level table. It's a useful reference; tell them they can come back to it.
- Protecting sensitive files: the rule for now is "keep restricted/IRB data out of the folder you run Claude in." If anyone has IRB data, this matters.
- Don't introduce ignore rules here. The slide forward-references Session 4, where `claude-ignore` is the enforcing mechanism (block 38).

### 9. AI skill gap (3 min)
- Two frames. The point is in the takeaway box: training raised quality inside the frontier and lowered accuracy outside it. Note the footnote: only the BCG study is experimental.

### 10. Models, effort, cost, usage limits (9 min)
- Model table: keep it on screen and give the rule of thumb from the slides (Sonnet as the everyday workhorse, upgrade for judgment calls, drop for mechanical tasks).
- Effort: raise it for judgment calls or after a wrong answer; keep it low for mechanical work.
- Cost: the "$20/month in 30–45 minutes" line gets attention. Hit the five principles quickly.
- Usage limits: mention the 5-hour rolling window now. The two-tab exercise in Session 2 and fan-out coding in Session 4 are where $20-plan users are most likely to hit it.

### 11. Context (9 min)
- Keep it conceptual: "it forgets things when the conversation gets long." The consistency-problem slide is the main point.
- Management strategies are Session 2's opening block (block 14); the slide says so.
- The hierarchy frames set up CLAUDE.md: it is loaded before the first message.

### 12. CLAUDE.md (5 min)
- Walk through the example. Point out the constraints section: "never drop observations without logging" is the kind of instruction that prevents real errors.
- Connect to block 11: CLAUDE.md is always loaded, so it's always "visible" to the model.

### 13. Exercise: build a CLAUDE.md (12 min)
- In a **new** VS Code window on one of their own projects, so the project folder is the working directory.
- Route A (by hand) or Route B (`/init` or a plain-words request). Route B users must read and edit the draft.
- Check: restart Claude Code, then `/memory`, or ask "What do you know about this project?"

### Close (3 min)
- Session 1 Summary frame. Tell them to **keep `my_workspace/session_1`**: Session 2's county-panel exercise (block 17) runs in it.

---

## Time Buffers

The course is one continuous queue (plan principles 2–5): Session 1 content is not
cut, and whatever doesn't fit moves to the start of Session 2.

- **If running behind:** cut "What's Ahead"; shorten orientation (block 5) if the room is technical.
- **Boundary rule (plan principle 5):** don't start the CLAUDE.md exercise (12 min) unless it can finish. If you reach block 13 with less time than that, pull the next lecture block forward instead: Session 2's context strategies (block 14), which is in the Session 2 deck. Session 2 then opens with the CLAUDE.md exercise.
- **If running ahead:** extend the first-commands exercise.

Notes for the material that moved to Session 2 (execution modes, plan-mode demo,
county-panel exercise) are still in `session_2/docs/instructor_notes.md`.
