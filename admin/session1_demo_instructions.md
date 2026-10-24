# Session 1 live demo: switching to the clean workspace and back

The teacher checkout contains the answers (finished scripts, `output/`, `decisions.md`,
the "correct" prompt). Claude Code can find them if it is launched from there. For the
live demo (slides 10 to 13), run it from the clean demo workspace instead.

| | Teacher (normal work) | Demo workspace |
|---|---|---|
| Folder | `~/Dropbox/Allardice/AIAgentsCourse` | `~/claude_demo` |
| Branch | `teacher` | `demo` (no shared history with teacher) |
| Contains | Everything | `session_1/data/`, the demo prompt, a demo `CLAUDE.md`, `.claude/settings.json` |

Your teacher checkout never changes branch. The demo workspace is a separate folder
(a git worktree), so there is nothing to switch back on the teacher side.

## Before class: build and test the demo workspace

1. In a terminal, from the teacher repo root:
   ```bash
   cd ~/Dropbox/Allardice/AIAgentsCourse
   ./start_demo.sh
   ```
   This rebuilds `~/claude_demo` from your current teacher files and opens it in VS Code.
   (`./start_demo.sh terminal` launches `claude` in the terminal there instead.)
2. Rebuild any time you change the data or `session_1/docs/demo_prompt.md` on teacher.
   Each rebuild wipes `~/claude_demo`, including output from a previous run.
3. Run the demo once as a rehearsal, then rebuild again so class starts from a clean folder.

## At the start of the demo: check you are in the right place

- VS Code window title shows `claude_demo`, not `AIAgentsCourse`.
- The file explorer shows only `CLAUDE.md`, `.claude/`, and `session_1/` (with `data/` and `docs/`).
- Start a **new** Claude Code session in that window. Do not resume an old one: earlier
  conversations from the teacher folder contain the answers.
- Paste the prompt from `~/claude_demo/session_1/docs/demo_prompt.md`.
- Expect permission prompts. The demo settings do not allow-all, and `git` commands are denied.

## Part 1 (web chat)

Upload from `session_1/demo_chat_upload/` in the teacher repo (data copies only).
The 2020 uncompressed CSV is about 32 MB, which may exceed the chat tool's per-file limit;
use the `.gz` for that year if so. This folder is untracked in git.

## After the demo: go back to teacher

1. Close the `claude_demo` VS Code window (or `File > Open Folder` to the teacher repo).
2. Open `~/Dropbox/Allardice/AIAgentsCourse` in VS Code and start sessions there as usual.
3. Optional cleanup of the demo workspace and branch:
   ```bash
   cd ~/Dropbox/Allardice/AIAgentsCourse
   git worktree remove --force ~/claude_demo
   git branch -D demo
   ```
   Do not push the `demo` branch.

## Known limits

- Claude launched in the demo workspace shares the repo's git store. `git` is denied in the
  demo settings and the demo `CLAUDE.md` says not to look, but neither is a hard barrier.
- Your global `~/.claude/CLAUDE.md` still loads in the demo and tells Claude to state
  assumptions and flag consequential choices. That can make Claude surface its decisions more
  than slide 13 expects. Check this in the rehearsal.
- If you launch from the teacher folder by mistake, nothing stops Claude from seeing the answers.

## Student sync

Run `./sync_student.sh` from the teacher branch with changes committed. It removes the demo
answers and refuses to commit if any known teacher-only path remains. If you add new
teacher-only files, add them to both the `git rm` list and `FORBIDDEN_PATHS` in that script.
Answer files remain reachable in student's git history; the script cannot fix that.
