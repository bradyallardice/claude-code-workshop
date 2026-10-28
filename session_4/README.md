# Session 4

## Start-of-session ritual

Same one command as every session. It brings the course materials up to date, copies
`session_4` and today's slides into `~/my_workspace`, and opens `~/my_workspace` in VS Code.

**Work only in `~/my_workspace`.** The course repo (`~/claude-code-workshop`) is a
read-only mirror that the command resets every time. If you edit inside it, your
edits are saved aside (`git stash list`, and a `backup-<date>` branch), but they do
not belong there.

Copy the line for your computer, change the last number to today's session
(`4` today), and run it.

**Mac** (Terminal):
```bash
curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 4
```

**Windows** (PowerShell, not as Administrator). It asks which session:
```powershell
irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
```

If I fixed something since you last ran it, the command updates your copy of the
folder without touching your work: a file you have **not** edited is replaced by my newer
version; a file you **have** edited is never changed, and my newer version is saved next
to it as `<name>.new`; files you created or deleted are left alone.

Check that the **Materials version** in the READY box matches the one on the screen.
If anything fails, see `tools/TROUBLESHOOTING.md`.

### If the command does not work

```bash
cd ~/claude-code-workshop && git fetch origin && git reset --hard origin/student
mkdir -p ~/my_workspace/slides && cp -r session_4/ ~/my_workspace/session_4/    # first time only
cp slides/session4_slides.pdf ~/my_workspace/slides/
cd ~/my_workspace && code .
```
(Windows: `cd ~\claude-code-workshop; git fetch origin; git reset --hard origin/student`, then copy
`session_4` and `slides\session4_slides.pdf` into `~\my_workspace` by hand, then `cd ~\my_workspace; code .`.)
The `reset` discards edits made inside the course repo; your `my_workspace` is not touched.

### Open today's folder

The command opens `my_workspace`. For today's exercises, open the `session_4` folder inside
it (VS Code: File, Open Folder, `my_workspace/session_4`) and start Claude Code there.

---

Start here:

1. Open the Session 4 slides: `~/my_workspace/slides/session4_slides.pdf` (copied there by the
   command above).
2. From inside your copy of `session_4`, open `docs/exercise_prompt.md`. It has all four exercises (Zotero literature review, build a skill, literature scan, fan-out coding).

## Before Exercise 1: import the practice Zotero library

Exercise 1 needs the practice library `docs/claude_code_zotero/` imported into Zotero as a collection named `claude_code_zotero`. Do this once, before the session (it is also in the pre-work). You need the Zotero desktop app and the Zotero MCP connected to Claude Code.

1. In the Zotero desktop app, choose **File → Import…**.
2. Choose **A file (BibTeX, RIS, Zotero RDF, etc.)** and click **Continue**.
3. Select `claude_code_zotero.rdf` in `session_4/docs/claude_code_zotero/`. Keep the `files/` folder next to the `.rdf`: if the `.rdf` is imported from anywhere else, Zotero imports the metadata but not the PDFs.
4. Check **Place imported collections and items into new collection** and **Copy files to the Zotero storage folder**, then click **Continue**.
5. Check the result: a collection `claude_code_zotero` with 9 papers and 10 PDF attachments in total (one paper has two PDFs).
6. Leave Zotero open until the sync icon stops spinning, so the library is also visible through the Zotero web API.

## What is in this folder

| Path | Used for |
|---|---|
| `docs/exercise_prompt.md` | Exercise instructions |
| `data/climate_speeches/` | Corpus and coding scheme for the fan-out exercise |
| `scripts/compare_to_reference.py` | Checks agreement between your agents' codes and the reference codes |
| `agents/referee.md`, `agents/merge-checker.md` | Example subagent definitions shown in the session. Copy one to `.claude/agents/` to use it |
| `capstone-template/` | Optional self-guided capstone material. No slide covers it and it is not part of the session |
| `option_b/`, `github_collaboration_practice/` | Optional extra material |
