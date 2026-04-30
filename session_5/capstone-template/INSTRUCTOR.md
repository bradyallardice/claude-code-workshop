# Instructor Notes - Capstone Project

This file is for you. Remove it or keep it private before students access the repo.

---

## Pre-class setup

### 1. Prepare the capstone folder

The capstone assumes students already have the course repo. Everything they need should be inside `session_5/capstone-template/`.

Before class, make sure students can find `session_5/capstone-template/README.md` from the course repo. They will create their own empty GitHub repos, clone those empty repos, and copy the contents of `session_5/capstone-template/` into them.

### 2. Verify instructor-provided files

The repo should ship with:

- `zotero/pdfs/magistro_et_al_2026_ai_globalization.pdf` - assigned paper.
- `zotero/synthesis.md` - your short synthesis notes for the assigned paper and supporting literature.
- `zotero/capstone_library.bib` - Zotero import seed.
- `zotero/pdfs/` - supporting literature PDFs for the literature review.

Before class, replace the placeholder `zotero/synthesis.md` with your actual notes. The `.bib` file is intentionally ignored by Claude through `.claudeignore`; students should import it into Zotero and then have Claude query Zotero through the MCP.

### 3. Assign extensions

Assign one extension (A, B, or C) per team before the session. With 8 teams of 2, assign each extension to about 2-3 teams. Write the assignment on the board or send it in advance; students fill it into `CLAUDE.md` on their first commit.

| Extension | Teams |
|-----------|-------|
| A - Framing x job type | Teams 1, 2, 3 |
| B - Robustness battery | Teams 4, 5, 6 |
| C - Prior trade attitudes | Teams 7, 8 |

### 4. Team repo setup and branch protection

You will not know teams until class starts, so each team creates its own repo during class.

Recommended flow:

1. One partner creates an empty repo on `github.com`.
2. That partner clones the empty repo to their computer.
3. That partner copies the contents of `session_5/capstone-template/` into the empty repo.
4. That partner commits and pushes the starter files to `main`.
5. The owner adds the partner as a collaborator.
6. The partner accepts the invite and clones the team repo.
7. The team edits `ROLES.md`, then works on `lit/<name>` and `analysis/<name>` branches.

If there is time, have teams protect `main`:

- GitHub -> Settings -> Branches -> Add rule
- Branch name pattern: `main`
- Require a pull request before merging
- Require one approval if their GitHub plan supports it
- Allow force pushes: no

You cannot configure this in advance because the teams create their own repos.

### 5. Do a dry run

Create one throwaway empty team repo on GitHub and run the full workflow as a pair:

- Owner clones the empty repo, copies in `session_5/capstone-template/`, commits, pushes, and adds the partner.
- Partner clones the team repo.
- Team fills in `ROLES.md`.
- Partner A creates `lit/<name>` and edits literature/prose files.
- Partner B creates `analysis/<name>` and edits analysis files.
- Each partner opens a PR into `main`; the other reviews and merges.
- Both partners pull `main` after each merge.
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
| 0-10 min | Team repo setup, extension assignments, Zotero import |
| 10-25 min | Orient to the paper, instructor notes, and literature collection |
| 25-45 min | Data validation and Figure 1 replication planning |
| 45-75 min | Replication and extension work on branches |
| 75-95 min | Research note drafting and PR review |
| 95-105 min | Compile, final merge, pull clean `main` |
| 105-115 min | Fill in `AI_WORKFLOW_REFLECTION.md` |
| 115-120 min | Quick share-out or troubleshooting buffer |

### Common failure modes

- **Collaborator invite not accepted.** Have them accept now.
- **Wrong repo cloned.** They should clone their empty team repo from GitHub, not the old collaboration-practice repo.
- **Push rejected.** Run `git pull --rebase origin main`, resolve issues, then push again.
- **PR against wrong base.** Fix the base branch dropdown in the GitHub UI.
- **Committed directly to main.** If branch protection blocks it, create `lit/<name>` or `analysis/<name>` and push there. The initial `ROLES.md` setup can happen on `main` before protection if needed.
- **Claude says main is blocked.** This is the main-branch hook working. They should create `lit/<name>` or `analysis/<name>`.
- **Claude says reference_code is read-only.** This is expected. They should copy logic into `starter/`, not edit original replication code.
- **Merge conflict in paper.tex.** Expected. Resolve it in VS Code; this is a useful collaboration failure mode.
- **Zotero import did not attach PDFs.** Confirm paths in `zotero/capstone_library.bib` point to files under `zotero/pdfs/` and import again.
- **latexmk not found.** `brew install --cask mactex` takes too long in class. Use Overleaf or `pdflatex -interaction=nonstopmode paper.tex` as the fallback.
- **cregg package version mismatch.** `reference_code/main.R` installs version 0.4.0 explicitly. If R throws errors, check `packageVersion("cregg")`.

### Flexing for headcount

With 8 teams of 2 (16 students), all three extensions get about 2-3 teams each. For fewer students:

- 12 students (6 teams): drop Extension C, split A and B 3 teams each.
- 10 students (5 teams): 2/2/1 split across A/B/C.
- Odd student: make one trio with paper/literature owner, analysis owner, and dedicated reviewer/writer.

---

## After class

- Collect `paper/paper.pdf` from each team's `main` branch as the deliverable.
- Collect `AI_WORKFLOW_REFLECTION.md` with the paper. It is the transfer exercise: what would become context, a skill, a subagent, or a hook in their own research.
- If you want to inspect collaboration quality, check each team's PRs and `git log --oneline`.
- For a new cohort, refresh `session_5/capstone-template/` in the course repo. Do not reuse old team repos because PR history and permissions confuse new students.
