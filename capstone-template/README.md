# Capstone: Replication + Extension of Magistro et al. 2026

You will work in a two-person team to read a published paper, use a provided Zotero library to write a short literature review, replicate Figure 1, run one small extension, and write a 2-3 page research note using Claude Code and GitHub.

The goal is not to have Claude finish a template for you. The goal is to practice directing AI work, checking it, and deciding what should be a one-off prompt, project context, skill, subagent, or hook.

**Time budget:** about 2-3 hours.

---

## Assigned paper

Magistro, Beatrice, Sophie Borwein, R. Michael Alvarez, Bart Bonikowski, and Peter Loewen. 2026. "Attitudes Toward Artificial Intelligence (AI) and Globalization: Common Microfoundations and Political Implications." *American Journal of Political Science*.

The paper studies whether people evaluate similar economic shocks differently when the cause is framed as AI automation versus offshoring. It uses a conjoint experiment with respondents in the United States and Canada.

Start here:

- Assigned paper PDF: `zotero/pdfs/magistro_et_al_2026_ai_globalization.pdf`
- Instructor synthesis notes: `zotero/synthesis.md`
- Zotero import seed: `zotero/capstone_library.bib`
- Supporting literature PDFs: `zotero/pdfs/`

The BibTeX seed is included so you can import the collection into Zotero. Claude should query Zotero through the MCP instead of reading the local `.bib` file directly; `.claudeignore` blocks `zotero/*.bib` for that reason.

---

## Team repo setup

Each two-person team creates its own GitHub repo from the starter repo. The original `github_collaboration_practice` repo is the starter. Your team repo is the workspace. Your team repo's `main` branch is the final submission.

### 1. Pick a repo owner

One partner creates an empty GitHub repo, for example:

```text
capstone-garcia-chen
```

Do not initialize it with a README, `.gitignore`, or license.

### 2. Owner copies the starter into the team repo

```bash
git clone https://github.com/bradyallardice/github_collaboration_practice.git
cd github_collaboration_practice
git remote remove origin
git remote add origin https://github.com/<owner>/<team-repo>.git
git push -u origin main
```

### 3. Owner adds partner

On GitHub:

```text
Settings -> Collaborators -> Add people
```

The partner accepts the invitation and clones the new team repo:

```bash
git clone https://github.com/<owner>/<team-repo>.git
cd <team-repo>
code .
```

### 4. Fill in roles

Edit `ROLES.md` before branching. Use two ownership lanes:

- **Paper + literature lane:** paper orientation, Zotero search, literature review draft, citation checking.
- **Data + analysis lane:** data validation, Figure 1 replication, extension script, output checking.

Both partners review each other's pull requests before merging.

### 5. Create branches

```bash
# Partner A
git switch -c lit/<name>

# Partner B
git switch -c analysis/<name>
```

Open pull requests into your team repo's `main`. If GitHub allows it, protect `main` so it requires one approval and does not allow self-approval.

---

## Orient yourself with the paper

Before asking Claude to write analysis code, use the assigned paper, instructor notes, and Zotero library to answer:

- What is the paper's research question?
- What is the core contribution?
- What are the treatments, conjoint attributes, and outcome?
- What does Figure 1 estimate?
- Why does the AI vs. offshoring comparison matter?
- What literature does the paper build on?

Your first Claude task should usually be search/synthesis, not code generation.

A useful prompt:

```text
Search the Zotero library for papers most relevant to this article's research question.
Return a table with citation key, mechanism, empirical setting, and how it connects
to Magistro et al. 2026. Do not write prose yet.
```

Then open the most important PDFs and instructor notes yourself. Check that every citation you use actually supports the sentence attached to it.

---

## Zotero workflow

1. Import `zotero/capstone_library.bib` into Zotero.
2. Confirm the PDF attachments import from `zotero/pdfs/`.
3. Confirm the Zotero MCP can find the papers.
4. Ask Claude to search Zotero, not to mine the local `.bib` file.

The local `.bib` file is blocked by `.claudeignore`. The PDFs are intentionally included for student reading.

---

## Analysis workflow

### Step 1 - Validate the data

Open `starter/replicate_fig1.R`, `starter/replicate_fig1.py`, or `starter/replicate_fig1.do`. Before running analysis code:

```text
use spec-validator on data/clean_AJPS.csv
```

Review any warnings. Decide whether they are real problems or expected features of the data.

### Step 2 - Replicate Figure 1

Fill in the replication script. The goal is a marginal means plot by treatment condition (AI vs. Offshoring) that visually matches Figure 1 of the paper.

Before asking Claude to write code, write the instruction yourself. It should specify:

- Input: `data/clean_AJPS.csv`
- Reshape target: one respondent-task per row
- Estimand: marginal means by AI vs. Offshoring treatment
- Visual target: four stacked panels matching Figure 1
- Output path: `paper/figures/figure1_replication.png`
- Checks: row counts, task counts, treatment counts before save

Ask Claude for a plan first. If the plan changes the sample, skips verification, or invents a shortcut, reject it.

When done: commit, push, open a PR into `main`. Your partner reviews and merges.

### Step 3 - Run the extension

Fill in `starter/extend_TEMPLATE.R`, `starter/extend_TEMPLATE.py`, or `starter/extend_TEMPLATE.do`.

Your extension is one of:

| Label | Extension |
|-------|-----------|
| A | **Framing x job type interaction** - Does the AI vs. offshoring frame shift preferences differently for data science jobs versus factory jobs? |
| B | **Robustness battery** - Vary attention-check filter, survey weights, estimator, and task fixed effects. Produce a robustness table or specification curve. |
| C | **Prior trade attitudes as moderator** - Split by pre-treatment support for trade liberalization and test whether free-trade supporters respond differently to the AI vs. offshoring framing. |

Your assigned extension is in `CLAUDE.md`.

Useful review prompt before opening the PR:

```text
spawn the spec-critic subagent on starter/extend_TEMPLATE.R
```

You can also ask `pr-referee` to review the branch diff, but your partner is still the reviewer who decides whether to merge.

### Step 4 - Write the research note

Edit `paper/paper.tex`. Fill in:

- Abstract: 3-4 sentences
- Introduction: motivation, literature positioning, paper contribution, your extension
- Data and design: conjoint design and extension approach
- Results: replication figure and extension result
- Discussion: interpretation, limits, and what the extension adds

Use `latex-regression-table` for regression tables. Save figures to `paper/figures/` and tables to `paper/tables/`.

When you have a full draft:

```text
spawn the note-reviewer subagent on paper/paper.tex
spawn the results-trace-auditor subagent on paper/paper.tex
use tex-reference-audit on paper/paper.tex
```

Revise, commit, push, and merge through PR review.

### Step 5 - Compile

```bash
cd paper
latexmk -pdf paper.tex
```

If `latexmk` is unavailable, ask the instructor for the fallback path.

### Step 6 - Reflect

Fill in `AI_WORKFLOW_REFLECTION.md`. This is where you separate:

- What was a one-off prompt for this capstone
- What would belong in `CLAUDE.md` for your own project
- What would become a reusable skill
- What reviewer role would become a subagent
- What safety rule would become a hook

---

## Git reference card

```bash
# Start a branch
git switch -c <branch>

# Commit work
git status
git add <files>
git commit -m "brief description"

# Push branch
git push -u origin <branch>

# After your partner merges a PR
git switch main
git pull origin main
```

Open a PR on GitHub:

1. Click **Compare & pull request** after pushing.
2. Base = `main`.
3. Add your partner as reviewer.
4. Wait for approval.
5. Merge after approval.
6. Both partners pull `main` after merge.

If something breaks:

- Push rejected: run `git pull --rebase origin main`, resolve issues, then push again.
- PR opened against wrong base: edit the base branch in GitHub.
- Merge conflict: resolve in VS Code or ask the instructor.
- Stuck for more than 2 minutes: ask Claude Code first, then flag the instructor.

---

## Deliverables

Submit from your team repo's `main` branch:

- `paper/paper.pdf` - 2-3 pages, including the replication figure and extension result.
- `AI_WORKFLOW_REFLECTION.md` - completed by the team.
- GitHub PR history showing both partners contributed and reviewed.
