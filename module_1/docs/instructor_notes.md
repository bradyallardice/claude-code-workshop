# Module 1 — Instructor Notes & Timing

**Session 1, first half. Target: 55 minutes (0:00 – 0:55)**
Break at 0:55, then Module 2 starts at 1:05.

---

## Timing Overview

| Clock   | Block                                        | Minutes |
|---------|----------------------------------------------|---------|
| 0:00    | Welcome, About Me, Participant Introductions | 12      |
| 0:12    | Course Roadmap + Core Framework              | 3       |
| 0:15    | Live Demo                                    | 5       |
| 0:20    | What Just Happened + RA Analogy              | 6       |
| 0:26    | Coding Paradigm Spectrum (4 slides)          | 5       |
| 0:31    | Capabilities + SWE vs Academic + Ownership   | 5       |
| 0:36    | Verification + Control Principle             | 3       |
| 0:39    | Why Python                                   | 2       |
| 0:41    | Orientation: Terminal, VS Code, File Types, Virtual Envs | 7 |
| 0:48    | Setup Check                                  | 3       |
| 0:51    | Exercise: First Commands + Debrief           | 4       |
| 0:55    | **BREAK (10 min)**                           | —       |

**Total: 55 minutes**

---

## Notes by Block

### Welcome + Introductions (12 min)
- Keep your own intro to ~3 min. The slides have plenty of detail; don't read them.
- Participant intros: enforce a strict ~1 min per person. With 8–10 people this is 8–10 min. If the group is larger than 10, consider asking only name + department + one sentence on AI use, or do a quick show-of-hands survey instead.
- **Time risk:** This is the biggest flex point. If intros run long, you lose exercise time later.

### Course Roadmap + Core Framework (3 min)
- Quick orientation. Hit the PI/RA analogy once here; it comes back after the demo.

### Live Demo (5 min)
- The demo prompt is in `module_1/docs/demo_prompt.md`. Have it ready to paste.
- Goal: wow factor. Show Claude Code reading two datasets, writing a merge script, and running it. Don't narrate every step — let them watch.
- If the demo takes longer than 5 min (network lag, errors), narrate what's happening and move on. You can show the finished output.

### What Just Happened + RA Analogy (6 min)
- Key moment: surface the fact that Claude Code made an analytical decision autonomously (the "alert" slide). This sets up the entire course theme.
- The RA analogy should land with this audience. Spend an extra beat here.

### Coding Paradigm Spectrum (5 min)
- Move through the first three paradigms quickly (~1 min each). They're reference points.
- Spend 2 min on agentic coding + the comparison table. The key insight slide ("first paradigm where the tool interacts with your project directly") is the punchline.

### Capabilities + SWE vs Academic + Ownership (5 min)
- Capabilities slide: scan quickly, don't read every bullet. They'll see it again in practice.
- SWE vs Academic: this reframes their expectations. Emphasize "works = runs correctly" vs "works = ???".
- Ownership ("Do You Own It?"): the 30-second test is concrete and memorable. Ask the room.

### Verification + Control Principle (3 min)
- Three concrete failure modes. Read them, let them sink in.
- Control Principle: one slide, one sentence. Don't over-explain.

### Why Python (2 min)
- Acknowledge the room may prefer R/Stata. Be brief and non-defensive.

### Orientation: Terminal, VS Code, Files, Virtual Envs (7 min)
- **Calibrate to the room.** If most participants are comfortable with the terminal, move through in 4 min. If many are new to it, slow down and budget the extra time from elsewhere.
- Terminal commands: show `pwd`, `ls`, `cd` live if possible.
- .py vs .ipynb: the "why scripts" framing is important for later modules.
- Virtual environments: keep it conceptual. The setup was in pre-work. Don't live-code `python3 -m venv` unless someone needs it.

### Setup Check (3 min)
- Have everyone run `claude --version`. Pair anyone stuck with a neighbor.
- If several people are not set up, troubleshoot at break, not now.

### Exercise: First Commands + Debrief (4 min)
- This is intentionally short — just enough to confirm everyone can talk to Claude Code.
- Task 1 (explain a script) is the priority. Task 2 (add assertion) is stretch.
- Debrief: 1–2 min. "What did it get right? Anything surprising?" Don't let this become a long discussion — that energy goes into Module 2's exercise.

---

## Time Buffers
- If running ahead: extend the exercise or the SWE vs Academic discussion.
- If running behind: cut the "What's Ahead" preview (they'll see it in Module 2 anyway) and shorten orientation if the room is technical.
