# Module 2 — Instructor Notes & Timing

**Session 1, second half. Target: 55 minutes (1:05 – 2:00)**
Starts after 10-minute break.

---

## Timing Overview

| Clock   | Block                                          | Minutes |
|---------|-------------------------------------------------|---------|
| 1:05    | File-Based Workflows + Context Window           | 6       |
| 1:11    | Permissions + .claudeignore                     | 5       |
| 1:16    | Three Execution Modes (Plan / Default / Auto)   | 7       |
| 1:23    | Live Demo: Plan Mode vs Auto-Accept             | 5       |
| 1:28    | Choosing a Model + Cost Management              | 5       |
| 1:33    | CLAUDE.md: What It Is + What Belongs + Example  | 7       |
| 1:40    | Exercise: Build the County Panel                | 15      |
| 1:55    | Debrief + Module Summary                        | 5       |
| 2:00    | **End of Session 1**                            | —       |

**Total: 55 minutes**

---

## Notes by Block

### File-Based Workflows + Context Window (6 min)
- This is the mental model shift for Stata/R users. Emphasize: no persistent session, no data loaded in memory. Scripts and files are the interface.
- Context window: keep it conceptual. "It forgets things when the conversation gets long." The consistency problem slide is the main point. You'll cover management strategies in Module 3.

### Permissions + .claudeignore (5 min)
- Walk through the risk-level table. It's a useful reference — tell them they can come back to it.
- .claudeignore: emphasize the "do this before your first session" point. If anyone has IRB data, this matters.
- Don't spend long on the setup slide for .claudeignore — it's straightforward.

### Three Execution Modes (7 min)
- This is conceptually the most important block in Module 2. Take your time.
- Plan Mode: 2–3 min. Emphasize it as the recommended default for research. The "checkpoint" framing (catch the inner join before it happens) is key.
- Default Mode: 1 min. The risk is that its judgment about "significant" differs from yours.
- Auto-Accept: 1 min. Good for docs/formatting, not for data work.
- Key Insight slide: 1 min. "Directing vs reviewing" — concrete and memorable.

### Live Demo: Plan Mode vs Auto-Accept (5 min)
- Same task, two modes. Prepare a simple task in advance (e.g., "add a new variable to the panel").
- Show what a plan looks like, then show the same task flying through in auto-accept.
- The contrast should be visceral: plan mode is slower but you see every decision; auto-accept is fast but you lose visibility.
- **Time risk:** Live demos can overrun. If it's taking long, narrate what would happen rather than waiting for execution.

### Choosing a Model + Cost Management (5 min)
- Model tiers: keep the table on screen, give the rule of thumb (default Sonnet, upgrade for reasoning, drop for mechanical tasks).
- Cost management: the "$20/month burns in 30–45 min" stat is attention-getting. Hit the five principles quickly.
- Usage limits: mention the 5-hour rolling window. They'll discover this on their own, but it's less frustrating if they know in advance.

### CLAUDE.md (7 min)
- This is the most actionable takeaway from Module 2. Spend time here.
- Walk through the example line by line. Point out the constraints section — "never drop observations without logging" is the kind of instruction that prevents real errors.
- Connect to the context window: CLAUDE.md is always loaded, so it's always "visible" to the model.
- They'll write their own in the exercise, so this is setup.

### Exercise: Build the County Panel (15 min)
- This is the main hands-on activity. Protect this time.
- They work in pairs. Both partners should be at one computer.
- Steps: (1) write CLAUDE.md (~3 min), (2) switch to plan mode, (3) prompt Claude Code, (4) read codebooks and evaluate the plan (~5 min), (5) approve/revise and run (~5 min), (6) check output (~2 min).
- The "Evaluating the Plan" slide has specific questions. Tell them to have it open as a checklist.
- **15 min is tight for this exercise.** If time is short, tell pairs to focus on steps 1–4 (CLAUDE.md + plan evaluation) and skip running the full script. The learning is in the plan review, not the execution.
- Circulate and look for common mistakes: not reading codebooks, accepting default variable definitions, not checking join type.

### Debrief + Summary (5 min)
- Ask 2–3 pairs to share: what variable coding decisions did you make? Did you reject anything in the plan?
- Hit the three lessons: CLAUDE.md forces explicitness, plan review forces pre-commitment, domain knowledge is non-delegable.
- Summary slide: quick scan. Tease Module 3 (automating research tasks) — "now that you know how it works, next time we'll use it to automate multi-step pipelines."

---

## Time Buffers
- If running ahead: extend the exercise (let pairs actually run the script and verify output) or open the floor for questions.
- If running behind: compress Model Choice + Cost to 3 min (they'll learn by doing). The exercise is the priority — don't cut it below 12 min.
- Nuclear option if very behind: skip the live demo and describe the plan/auto-accept contrast verbally using screenshots. Saves 5 min.
