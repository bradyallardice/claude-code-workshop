# Session 4

Start here:

1. Make sure you copied the Session 4 slides into your local course workspace.

Replace `[my_workspace]` with wherever you keep your local course files.

Choose exactly one slide-copy option:

Option A: if you already have `[my_workspace]/slides/`, copy just today's PDF:

```bash
cp slides/session4_slides.pdf [my_workspace]/slides/
```

Option B: if you do not have a slides folder yet, copy the whole folder:

```bash
cp -r slides/ [my_workspace]/slides/
```

Do not run both Option A and Option B.

2. Open `../slides/session4_slides.pdf` from your local Session 4 folder. If you are in the course repo root, open `slides/session4_slides.pdf`.
3. From inside your copy of `session_4`, open `docs/exercise_prompt.md`. It has all four exercises (Zotero literature review, build a skill, literature scan, fan-out coding).

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
