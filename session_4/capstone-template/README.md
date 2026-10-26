# Capstone: Replication + Extension of Magistro et al. 2026

You will work in a two-person team (or alone, if you are working through it by yourself) to read a published paper, use a provided Zotero library to write a short literature review, replicate Figure 1, run one small extension, and write a 2-3 page research note using Claude Code and git.

The goal is not to have Claude finish a template for you. The goal is to practice directing AI work, checking it, and deciding what should be a one-off prompt, project context, skill, subagent, or hook.

**Time budget:** about 2-3 hours.

The steps below use the same numbers as the capstone slides (Step 0 to Step 9).

---

## Step 0 - What is provided

- A template with data, starter scripts, a paper skeleton, and this README.
- The assigned paper, a Zotero library with synthesis notes attached to each paper, and the PDFs.
- Hooks that protect `reference_code/`, `main`, and ignored files.
- General skills (data validation, robustness, tables, references, prose review) and reviewer subagents (code critic, results trace, PR referee, note reviewer).

## Assigned paper

Magistro, Beatrice, Sophie Borwein, R. Michael Alvarez, Bart Bonikowski, and Peter Loewen. 2026. "Attitudes Toward Artificial Intelligence (AI) and Globalization: Common Microfoundations and Political Implications." *American Journal of Political Science*.

The paper studies whether people evaluate similar economic shocks differently when the cause is framed as AI automation versus offshoring. It uses a conjoint experiment with respondents in the United States and Canada.

Where things are:

- Assigned paper PDF: `zotero/pdfs/magistro_et_al_2026_ai_globalization.pdf`
- Variable codebook: `data/Codebook_AJPS.pdf`
- Zotero library to import (with the synthesis notes and PDFs attached): `zotero/capstone_library/capstone_library.rdf`
- Supporting literature PDFs: `zotero/pdfs/`
- Citation-only BibTeX copy of the same references: `zotero/capstone_library.bib` (no notes; you do not need it if you import the `.rdf`)

The synthesis notes are the instructor's notes on each paper. They live **inside the Zotero library**, not as a separate file in this folder. You read them through Zotero (Step 3), and Claude reads them by querying Zotero through the MCP. The local `.rdf` and `.bib` files are blocked by `.claudeignore` so that Claude goes through Zotero instead of reading them directly.

---

## Step 1 - Orient yourself with the paper

Before asking Claude to write analysis code, use the assigned paper, the synthesis notes, and the Zotero library to answer:

- What is the paper's research question?
- What is the core contribution?
- What are the treatments, conjoint attributes, and outcome?
- What does Figure 1 estimate?
- Why does the AI vs. offshoring comparison matter?
- What literature does the paper build on?

Your first Claude task should usually be search/synthesis, not code generation. Open the most important PDFs and notes yourself, and check that every citation you use actually supports the sentence attached to it.

---

## Step 2 - Make a local git repository

You do not need a GitHub account. You work in a local git repository: branches, merges, and review by diff.

### 2a. Copy the template and put it under git

Run these yourself in a terminal (not through Claude Code: the main-branch hook blocks Claude from committing the starter files on `main`). Start from the folder that contains `session_4/` (the course repo, or the workspace where you copied `session_4/`):

```bash
cp -r session_4/capstone-template ~/my_workspace/capstone
cd ~/my_workspace/capstone
git init -b main
git add .
git commit -m "Add capstone starter files"
```

`session_4/capstone-template/` is the source; your copy is the workspace. Do not edit the template.

If `git init -b main` is rejected (git older than 2.28), run `git init` and then `git symbolic-ref HEAD refs/heads/main` before the first commit. The slides, hooks, and commands below all assume the branch is called `main`.

Check:

```bash
ls -a
git log --oneline
```

You should see `README.md`, `CLAUDE.md`, `.claude/`, `starter/`, `paper/`, `data/`, and `zotero/`, and exactly one commit. Open the folder in VS Code with `code .` and run every script from this folder (the repo root).

### 2b. Fill in roles and branch

Edit `ROLES.md` before branching. Use two ownership lanes:

- **Paper + literature lane:** paper orientation, Zotero search, literature review draft, citation checking.
- **Data + analysis lane:** data validation, Figure 1 replication, extension script, output checking.

Then create one branch per lane:

```bash
git switch -c lit/<name>        # paper + literature lane
git switch -c analysis/<name>   # data + analysis lane
```

Working alone: do both lanes, one branch each. Working as a pair: each partner takes a lane and reviews the other's. Never commit directly to `main` after the setup commit; the main-branch hook will stop Claude if it tries.

### 2c. Review before merging

From the branch you are about to merge:

```bash
git diff main..HEAD             # read every changed line
```

Then ask Claude: `use the pr-referee subagent on this branch's diff`. When you are satisfied, merge it yourself:

```bash
git switch main
git merge lit/<name>
```

A pair on one machine takes turns at the keyboard. A pair on two machines can exchange the repo folder, or use any shared remote you already have (see the optional GitHub variant below).

### Optional: share the repo through GitHub

Skip this unless your pair is on two machines and wants a shared remote. One partner (the owner):

1. Creates an **empty** repo on `github.com` (no README, `.gitignore`, or license), e.g. `capstone-garcia-chen`.
2. Adds it as a remote and pushes `main`:

   ```bash
   git remote add origin https://github.com/<owner>/<team-repo>.git
   git push -u origin main
   ```

3. Adds the partner under Settings -> Collaborators. The partner clones the repo.

Branches are then pushed with `git push -u origin <branch>`, and you can open a pull request into `main` instead of merging locally. The review rule is the same: the other partner reads the diff before anything merges.

---

## Step 3 - Zotero

1. In Zotero: **File -> Import... -> A file (BibTeX, RIS, Zotero RDF, etc.)**, choose `zotero/capstone_library/capstone_library.rdf`.
2. Check **"Place imported collections and items into new collection"** and **"Copy files to the Zotero storage folder"**.
3. Keep the `files/` folder **next to** the `.rdf` while importing. If it is moved, Zotero imports the metadata but not the PDFs or the notes' attachments.
4. Confirm that the 11 items and their PDFs imported, that each paper has a synthesis note, and that the Zotero MCP can find the papers.
5. Ask Claude to search Zotero, not to mine a local file.

Do not import `zotero/capstone_library.bib` as well: it holds the same references without notes or attachments and would create duplicates. It is only a plain-text copy of the citations.

---

## Step 4 - Write the literature review

The synthesis notes are already attached to each paper in your Zotero library. A useful first prompt:

```text
Read the synthesis notes attached to each paper in the Zotero library.
Across all notes, identify the three or four recurring mechanisms that
connect automation and trade shocks to political preferences. Then draft
2-3 paragraphs that position the capstone paper relative to those
mechanisms. Every sentence must be traceable to a specific note.
```

Then check that every citation supports the sentence attached to it, add connections the model missed, and cut anything that does not directly motivate the capstone's design.

---

## Step 5 - Validate the data

Open `starter/replicate_fig1.R`, `starter/replicate_fig1.py`, or `starter/replicate_fig1.do`. Before running analysis code:

```text
use spec-validator on data/clean_AJPS.csv
```

Review any warnings. Decide whether they are real problems or expected features of the data.

---

## Step 6 - Replicate Figure 1

Fill in the replication script. The goal is a marginal means plot by treatment condition (AI vs. Offshoring) that visually matches Figure 1 of the paper.

Before asking Claude to write code, write the instruction yourself. It should specify:

- Input: `data/clean_AJPS.csv`
- Reshape target: one respondent-task per row
- Estimand: marginal means by AI vs. Offshoring treatment
- Visual target: four stacked panels matching Figure 1
- Output path: `paper/figures/figure1_replication.png`
- Checks: row counts, task counts, treatment counts before save

Ask Claude for a plan first. If the plan changes the sample, skips verification, or invents a shortcut, reject it.

When done: commit on your branch, then review and merge as in Step 2c.

---

## Step 7 - Run the extension and write the note

Fill in `starter/extend_TEMPLATE.R`, `starter/extend_TEMPLATE.py`, or `starter/extend_TEMPLATE.do`.

Your extension is one of:

| Label | Extension |
|-------|-----------|
| A | **Framing x job type interaction** - Does the AI vs. offshoring frame shift preferences differently for data science jobs versus factory jobs? |
| B | **Robustness battery** - Vary attention-check filter, survey weights, estimator, and task fixed effects. Produce a robustness table or specification curve. |
| C | **Prior trade attitudes as moderator** - Split by pre-treatment support for trade liberalization and test whether free-trade supporters respond differently to the AI vs. offshoring framing. |

Your assigned extension goes in `CLAUDE.md` (on your first commit).

Useful review prompt before merging:

```text
spawn the spec-critic subagent on starter/extend_TEMPLATE.R
```

You can also ask `pr-referee` to review the branch diff, but the reviewer who decides whether to merge is a person: your partner, or you, after reading the diff.

Then edit `paper/paper.tex`. Fill in:

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

Revise, commit, and merge after reading the diff. Then compile:

```bash
cd paper
latexmk -pdf paper.tex
```

If `latexmk` is unavailable, use `pdflatex -interaction=nonstopmode paper.tex`, or Overleaf.

---

## Step 8 - Reflect

Fill in `AI_WORKFLOW_REFLECTION.md`. This is where you separate:

- What was a one-off prompt for this capstone
- What would belong in `CLAUDE.md` for your own project
- What would become a reusable skill
- What reviewer role would become a subagent
- What safety rule would become a hook

## Step 9 - Transfer

Figure 1 is deliberately not a skill. It is project-specific: one paper, one dataset, one visual target. The transferable move is the pattern: read the reference code, state the reshape target and estimand, specify the output, tell Claude which checks to print before saving, and review the plan, the code, and the final figure. Use your reflection to decide which of your own repeated conventions deserve a skill, a subagent, or a hook.

---

## Git reference card

```bash
# Start a branch
git switch -c <branch>

# Commit work
git status
git add <files>
git commit -m "brief description"

# Read what you are about to merge, then merge it
git diff main..HEAD
git switch main
git merge <branch>

# See the history
git log --oneline --graph --all
```

If something breaks:

- Claude says `main` is blocked: this is the main-branch hook. Switch to a `lit/<name>` or `analysis/<name>` branch.
- Claude says `reference_code/` is read-only: expected. Copy the logic into `starter/`.
- Merge conflict (typically in `paper/paper.tex`): resolve in VS Code, then `git add` and `git commit`.
- Stuck for more than 2 minutes: ask Claude Code first, then flag the instructor.

---

## Deliverables

Submit from your repo's `main` branch:

- `paper/paper.pdf` - 2-3 pages, including the replication figure and extension result.
- `AI_WORKFLOW_REFLECTION.md` - completed by the team.
- `git log --oneline --graph --all` output (or your pull request history, if you used GitHub) showing both lanes were worked on and reviewed.
