# Instructor Notes - Capstone Project

This file is for you. Remove it or keep it private before students access the repo.

---

## Pre-class setup

### 1. Prepare the capstone folder

The capstone assumes students already have the course repo. Everything they need should be inside `session_4/capstone-template/`.

Before class, make sure students can find `session_4/capstone-template/README.md` from the course repo. The Session 4 slides (back matter I) run the capstone in a **local git repository**: each student or pair copies `session_4/capstone-template` to `~/my_workspace/capstone`, runs `git init -b main`, and works on `lit/<name>` and `analysis/<name>` branches, reviewing by diff. No GitHub account is needed. The GitHub route (empty repo, collaborator, pull requests) survives in the README only as an optional variant for pairs on two machines.

### 2. Verify instructor-provided files

The repo should ship with:

- `zotero/pdfs/magistro_et_al_2026_ai_globalization.pdf` - assigned paper.
- `zotero/capstone_library/capstone_library.rdf` plus its `files/` folder - the Zotero library students import. It holds 11 items, their PDFs, and **11 synthesis notes (Zotero Memo items)**: these notes are your instructor synthesis, and the only place students get them. Verified 2026-10: 11 `bib:Memo` entries, first titled "Synthesis - Magistro et al. 2026 (Capstone)".
- `zotero/capstone_library.bib` - citation-only copy of the same 11 references. It carries no notes and no PDF attachments, so students should NOT import it alongside the `.rdf` (duplicates).
- `zotero/pdfs/` - the same literature PDFs, for reading outside Zotero.

There is no separate `synthesis.md` any more. To change the notes, edit them in your own Zotero library and re-export: **File -> Export Library... -> Zotero RDF**, tick "Export Files", and replace `zotero/capstone_library/` (keep `files/` next to the `.rdf`). `.claudeignore` blocks both the `.bib` and the `.rdf` from Claude's `Read`, so Claude gets the notes only through the Zotero MCP.

Students need Zotero with the MCP working before this session (the Session 4 prework covers it). The import steps are in the README, Step 3. The `.rdf` import copies the PDFs only if `files/` sits next to the `.rdf` during import.

### 3. Assign extensions

Assign one extension (A, B, or C) per team before the session. With 8 teams of 2, assign each extension to about 2-3 teams. Write the assignment on the board or send it in advance; students fill it into `CLAUDE.md` on their first commit.

| Extension | Teams |
|-----------|-------|
| A - Framing x job type | Teams 1, 2, 3 |
| B - Robustness battery | Teams 4, 5, 6 |
| C - Prior trade attitudes | Teams 7, 8 |

### 4. Local repo setup (default) and optional GitHub

The default flow needs nothing from you in advance:

1. Each student or pair runs, in a terminal (not through Claude Code, because the main-branch hook blocks Claude from committing starter files on `main`):

   ```bash
   cp -r session_4/capstone-template ~/my_workspace/capstone
   cd ~/my_workspace/capstone
   git init -b main
   git add .
   git commit -m "Add capstone starter files"
   ```

2. They edit `ROLES.md`, then work on `lit/<name>` and `analysis/<name>` branches.
3. Before merging, they read `git diff main..HEAD`, optionally run `pr-referee`, and merge in the terminal.

`git init -b main` needs git 2.28+. With older git the README gives `git init` followed by `git symbolic-ref HEAD refs/heads/main`. The hooks protect both `main` and `master`, but the slides and README assume `main`.

Pairs on two machines can exchange the repo folder, or share a remote. If you want them to use GitHub: one partner creates an **empty** repo, adds it as `origin`, pushes `main`, and adds the partner as a collaborator; then pull requests replace local merges. Branch protection (Settings -> Branches -> require a pull request and one approval) can only be set up by each team, since you do not know the teams in advance. This is optional and not part of the slides.

### 5. Do a dry run

Run the full workflow once in a throwaway folder:

- Copy `session_4/capstone-template/` to a scratch folder, `git init -b main`, and make the setup commit.
- Import `zotero/capstone_library/capstone_library.rdf` into Zotero (with `files/` beside it) and confirm the 11 notes and the PDFs arrive and the MCP finds them.
- Fill in `ROLES.md`.
- Create `lit/<name>` and edit literature/prose files; create `analysis/<name>` and edit analysis files.
- On each branch, read `git diff main..HEAD`, run `pr-referee`, and merge into `main` in the terminal.
- Compile `paper/paper.tex` to PDF.

Time yourself. If it takes you more than 20 minutes, find the rough edges before class.

### 6. Verify Claude Code infrastructure

The template includes project-level hooks, skills, and subagents under `.claude/`.

- Hooks: `.claude/settings.json` wires `.claudeignore`, `reference_code/` protection, main-branch protection, paper compile checks, and branch-only auto-commit.
- Skills: `.claude/skills/` contains data validation, robustness, table, citation, documentation, and prose-audit skills. The Figure 1 replication is intentionally not packaged as a skill so students practice writing a project-specific prompt.
- Subagents: `.claude/agents/` contains `spec-critic`, `results-trace-auditor`, `pr-referee`, and `note-reviewer`.

Before class, open the starter in Claude Code and confirm it sees the project-level skills and agents. Then test one blocked edit to `reference_code/main.R` and one allowed edit on a feature branch.

---

## During class

### Session flow

| Time | Activity |
|------|----------|
| 0-10 min | Local repo setup, extension assignments, Zotero import |
| 10-25 min | Orient to the paper, instructor notes, and literature collection |
| 25-45 min | Data validation and Figure 1 replication planning |
| 45-75 min | Replication and extension work on branches |
| 75-95 min | Research note drafting and branch review |
| 95-105 min | Compile, final merge, pull clean `main` |
| 105-115 min | Fill in `AI_WORKFLOW_REFLECTION.md` |
| 115-120 min | Quick share-out or troubleshooting buffer |

### Common failure modes

- **`git init -b main` rejected.** Old git. Use `git init` then `git symbolic-ref HEAD refs/heads/main` before the first commit. If someone already has a `master` branch, `git branch -m master main`.
- **Claude refuses to make the setup commit.** The main-branch hook is working: the starter files must be committed by the student in a terminal, not by Claude.
- **Committed directly to main.** Create `lit/<name>` or `analysis/<name>` from that commit and carry on there.
- **Zotero import brought no notes or no PDFs.** They imported the `.bib` instead of the `.rdf`, or the `.rdf` without `files/` beside it. Re-import the `.rdf` from `zotero/capstone_library/`.
- **GitHub variant only:** collaborator invite not accepted; wrong repo cloned (should be their own empty team repo); push rejected (`git pull --rebase origin main`, then push); PR opened against the wrong base (fix the base dropdown).
- **Claude says main is blocked.** This is the main-branch hook working. They should create `lit/<name>` or `analysis/<name>`.
- **Claude says reference_code is read-only.** This is expected. They should copy logic into `starter/`, not edit original replication code.
- **Merge conflict in paper.tex.** Expected. Resolve it in VS Code; this is a useful collaboration failure mode.
- **latexmk not found.** `brew install --cask mactex` takes too long in class. Use Overleaf or `pdflatex -interaction=nonstopmode paper.tex` as the fallback.
- **cregg package version mismatch.** `reference_code/main.R` installs version 0.4.0 explicitly. If R throws errors, check `packageVersion("cregg")`.

### Flexing for headcount

With 8 teams of 2 (16 students), all three extensions get about 2-3 teams each. For fewer students:

- 12 students (6 teams): drop Extension C, split A and B 3 teams each.
- 10 students (5 teams): 2/2/1 split across A/B/C.
- Odd student: make one trio with paper/literature owner, analysis owner, and dedicated reviewer/writer.

---

## After class

- Collect `paper/paper.pdf` from each team's `main` branch (or repo folder) as the deliverable.
- Collect `AI_WORKFLOW_REFLECTION.md` with the paper. It is the transfer exercise: what would become context, a skill, a subagent, or a hook in their own research.
- If you want to inspect collaboration quality, check `git log --oneline --graph --all` in each repo (or each team's PRs, if they used GitHub).
- For a new cohort, refresh `session_4/capstone-template/` in the course repo. Do not reuse old team repos or folders, because old history confuses new students.
