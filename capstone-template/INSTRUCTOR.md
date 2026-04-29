# Instructor Notes — Capstone Project

This file is for you. Remove it or keep it private before students access the repo.

---

## Pre-class setup

### 1. Create the template repo on GitHub

Push this folder to GitHub and mark it as a **Template Repository**:

```bash
cd capstone-template/
git init
git add .
git commit -m "Initial capstone template"
gh repo create <your-org>/capstone-template --public --source=. --push
```

Then in GitHub → Settings → check **Template repository**.

### 2. Add instructor-provided files

Before marking the repo public, add:

- `zotero/magistro_2026.pdf` — your annotated PDF of the paper
- `zotero/synthesis.md` — your 1-page synthesis (claim, design, key findings, Figure 1 takeaway)
- `zotero/capstone_collection.rdf` — Zotero RDF export with 5–10 secondary references

These are not in the template repo because they require instructor annotation. Without `synthesis.md`, students have no on-ramp to the paper.

### 3. Assign extensions

Assign one extension (A, B, or C) per group before the session. With 8 groups of 2, you'll assign each extension to ~2–3 groups. Write the assignment on the board or send it in advance — students fill it into `CLAUDE.md` on their first commit.

| Extension | Groups |
|-----------|--------|
| A — Framing × job type | Groups 1, 2, 3 |
| B — Robustness battery | Groups 4, 5, 6 |
| C — Prior trade attitudes | Groups 7, 8 |

### 4. Set branch protection on each group's repo

Each group creates their repo via **Use this template**. After they do:

- GitHub → Settings → Branches → Add rule
- Branch name pattern: `main`
- Require a pull request before merging (no reviewer requirement enforced by GitHub — the exercise enforces it socially)
- Allow force pushes: **no**

You cannot set this on the template itself before groups create their repos. Options:
- Have groups do it themselves (good practice, 2 min)
- Use `gh` to script it after they create their repos

### 5. Do a dry run

Create two throwaway GitHub accounts and run the full workflow as a pair:

- Clone, branch (`replication` + `extension`), edit starter files, commit, push
- Open PR as person A, review + merge as person B
- Confirm `main` reflects both merges
- Compile `paper/paper.tex` to PDF

Time yourself. If it takes you more than 20 minutes, find the rough edges.

### 6. Verify Claude Code infrastructure

The template includes project-level hooks, skills, and subagents under `.claude/`.

- Hooks: `.claude/settings.json` wires `.claudeignore`, `reference_code/` protection, main-branch protection, paper compile checks, and branch-only auto-commit.
- Skills: `.claude/skills/` contains data validation, robustness, table, citation, documentation, and prose-audit skills. The Figure 1 replication is intentionally not packaged as a skill so students practice writing a project-specific prompt.
- Subagents: `.claude/agents/` contains `spec-critic`, `results-trace-auditor`, `pr-referee`, and `note-reviewer`.

Before class, open the template in Claude Code and confirm it sees the project-level skills and agents. Then test one blocked edit to `reference_code/main.R` and one allowed edit on a feature branch.

---

## During class

### Session flow

| Time | Activity |
|------|----------|
| 0–10 min | Intro: paper overview, extension assignments, repo setup |
| 10–25 min | Data validation + replication kickoff (both roles working) |
| 25–60 min | Replication + extension running in parallel |
| 60–90 min | Writing the research note |
| 90–105 min | Compile, final PRs, merge |
| 105–110 min | Fill in `AI_WORKFLOW_REFLECTION.md` |
| 110–120 min | Presentations (5 min/group, ~4–5 groups present) |

### Common failure modes

- **Collaborator invite not accepted.** Have them accept now — 30 seconds.
- **Push rejected.** `git pull --rebase origin main` then push again.
- **PR against wrong base.** Fix in GitHub UI (change base branch dropdown).
- **Committed directly to main.** Branch protection should block the push. Help them: `git checkout -b <branch>` then `git push -u origin <branch>`.
- **Claude says main is blocked.** This is the main-branch hook working. They should create `replication` or `extension`, except for the initial `ROLES.md` / `CLAUDE.md` setup edit.
- **Claude says reference_code is read-only.** This is expected. They should copy logic into `starter/`, not edit original replication code.
- **Merge conflict in paper.tex.** Expected — two people editing the same file. Walk them through resolving it in VS Code (the merge conflict editor makes this easy). This is the pedagogically useful failure mode.
- **latexmk not found.** `brew install --cask mactex` takes too long in class. Have a fallback: Overleaf or `pdflatex -interaction=nonstopmode paper.tex`.
- **cregg package version mismatch.** `reference_code/main.R` installs version 0.4.0 explicitly. If R throws errors, check `packageVersion("cregg")`.

### Flexing for headcount

With 8 groups of 2 (16 students), all three extensions get ~2–3 groups each. For fewer students:
- 12 students (6 groups): drop Extension C, split A and B 3 groups each
- 10 students (5 groups): 2/2/1 split across A/B/C
- Odd student: make one trio — replication person, extension person, dedicated writer/reviewer

---

## After class

- Collect `paper/paper.pdf` from each group's `main` branch as the deliverable.
- Collect `AI_WORKFLOW_REFLECTION.md` with the paper. It is the transfer exercise: what would become context, a skill, a subagent, or a hook in their own research.
- For a new cohort: create fresh group repos from the template — do not reuse old repos (PR history confuses new students).
- If you want to inspect git history quality: `git log --oneline` in each group's repo. The auto-commit hook should produce a dense, descriptive history.
