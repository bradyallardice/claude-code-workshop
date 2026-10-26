# Instructor Notes: Subagents, Hooks, and the Capstone (Session 5 deck)

Deck: `slides/session5_slides.tex` ("Agents, Hooks, and a Paper"). This file was empty (0 bytes) and had been empty since before the `session_5/` to `session_4/` move; nothing earlier in git history existed to restore. It is written from what the slides actually require. It was not rehearsed.

**Relationship to the Session 4 deck.** Much of this material now also lives in `slides/session4_slides.tex` (subagents and swarms, block 32; hooks, block 38; hook audit log, back matter B; capstone, back matter I) and is timed in `docs/instructor_notes.md`. Whether the Session 5 deck is still taught as its own session is your call; these notes cover it as it stands.

`sync_student.sh` removes this file from the student tree.

---

## What the deck contains

| Part | Frames | Student action | Needs |
|---|---|---|---|
| Ritual (2 frames) | 61-104 | Pull course repo, copy `session_4/` and slides | Course repo cloned |
| Subagents (generic, named, patterns) | 134-408 | Mostly watch; two worked examples | Claude Code; a regression script |
| Hooks (concept, audit-log example, `claude-ignore`) | 414-491 | Watch; optionally install `claude-ignore` | `jq`, Node.js and `npm` |
| Capstone (Steps 0-9) | 515-815 | Self-guided, 2-3 hours | `session_4/capstone-template/`, Zotero + MCP |
| Beyond the terminal, scraping, API | 826-end | Watch | Nothing runs |

No timings were ever written for this deck. The only clock is the Session 4 plan (block 32 subagents 14 min, block 38 hooks 5 min). Frame counts above are the only guide.

---

## Before the session

### 1. Subagent demos

- **Generic subagent frame ("Using a Generic Subagent in Practice").** The prompt reads the four session slide decks in `slides/`. Students only receive the PDFs (the student branch strips `.tex` sources), so the frame says PDFs. On the teacher branch both exist; use the PDFs so what you show matches what students would get. Rehearse once: it reads four large decks and costs tokens.
- **spec-critic frame ("Building a Specialized Agent").** Build it live from the four fields on the slide, or have a finished copy ready. A finished copy exists in `session_4/capstone-template/.claude/agents/spec-critic.md`: read-only (`Read, Grep, Glob`), model `haiku`. Copy it to `~/.claude/agents/spec-critic.md` as the fallback. Remove the user-level copy afterward if you do not want it active in every project.
- **Target script.** The slides now say `<your regression script>`. The old target, `solution_estimate.py`, is stripped from the student tree on purpose (it is an answer file), so students cannot follow a slide that names it. For your own demo it still exists on the teacher branch at `session_2/scripts/solution_estimate.py`. Students without a Session 2 script can point `spec-critic` at `session_4/capstone-template/starter/extend_TEMPLATE.py`; that is an unfilled template, so the audit will be thin.
- **Pipeline frame.** Three stages (audit, patch, re-audit) means at least three subagent runs. Rehearse it on the script you will show and keep a screenshot of the result as a fallback.

### 2. Hook demo (audit log)

- **Needs `jq`.** Check `command -v jq` on the machine you demo from; install it first if missing. Students who want to try it need it too.
- The slide's hook reads the tool call as JSON on standard input (`jq -r '.tool_input.command'`). That is the same form the Session 4 back-matter example uses. The scripts in `session_4/capstone-template/.claude/scripts/` also read a JSON document from standard input, which is consistent. The previous version of this slide used a `$CLAUDE_TOOL_INPUT` variable; I could not find that variable in anything in the repo and replaced it.
- **Not tested as an installed hook.** The Session 4 notes record the same caveat: it was only run as a shell pipeline. Install it once in a throwaway project's `.claude/settings.json` and confirm that a line appears in `~/research_log.txt` after a Bash call before presenting it. Remove it afterward, since it logs every command in that project.

### 3. `claude-ignore` demo

- **Node.js and `npm` are required.** The Session 4 plan flags that the README told students to install Node before Session 5, but the Session 4 deck now touches `claude-ignore` earlier. Ask for Node in the prework if you want anyone to follow along. If `npm` is not on the path, install Node first.
- **Package check (2026-10-26):** `npm view claudeignore` returns package `claudeignore`, version 0.0.9, repository `github.com/li-zhixin/claude-ignore`, described as a PreToolUse hook that blocks reads of files matching `.claudeignore` patterns. That agrees with the slide's install command and source line.
- **Not verified:** what `claude-ignore init` writes into `.claude/settings.json`, and the slide's claims about merging `.claudeignore` files up the directory tree and blocking with exit code 2. Run `npm install -g claudeignore` and `claude-ignore init` once in a throwaway folder, look at the diff it makes, and test one ignored file before class. A global `npm install` can fail on permissions on some machines (an `nvm`-managed Node avoids that).
- Do this in a throwaway folder, not in the capstone folder: the template already has its own `.claudeignore` and a hand-written guard script (`claude_ignore_guard.sh`), and mixing the two would confuse the demo.

### 4. Capstone

Use `session_4/capstone-template/INSTRUCTOR.md` (teacher-only). It now covers the local git flow, the Zotero RDF (which carries the synthesis notes), extension assignments, and the dry run.

The template's slides and README now use the same step numbers (0 to 9) and the local git flow. Two things have to be true before class:

- Zotero is installed, the Zotero MCP works, and students can import `zotero/capstone_library/capstone_library.rdf` with `files/` beside it.
- Each extension (A, B, C) is assigned to teams in advance; the assignment is not on any slide.

### 5. "Beyond the terminal", scraping, and API frames

Nothing in them runs. The example files they name (`data/votes_raw.csv`, `data/survey_responses.csv`, `data/survey_coded.csv`) are invented illustrations and are not in the repo. Claims about the cloud, remote control, `/loop`, `/schedule`, and the API were carried over from the older deck. The Session 4 notes say they were not re-checked and may be out of date; the same applies here. Re-read the current documentation before presenting any of them as fact.

---

## Open items

- Decide whether this deck is still a separate session or has been absorbed by Session 4.
- Rehearse the pipeline demo and the installed audit-log hook (neither has been run as shown).
- Verify `claude-ignore init` behaviour (see above).
- The Session 4 deck's capstone "flow" frame (`slides/session4_slides.tex`, "Capstone Flow") still numbers the steps Team repo = 1, Zotero = 2, Orient = 3, while its detail frames number them Orient = 1, repo = 2, Zotero = 3. This deck's flow frame was corrected to the detail-frame numbering; the Session 4 one was not touched here.
