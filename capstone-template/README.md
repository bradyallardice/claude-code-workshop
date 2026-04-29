# Capstone: Replication + Extension of Magistro et al. 2026

You will replicate a published conjoint experiment on AI and globalization attitudes, run a short original extension, and write up a 2–3 page research note — all in one session using Claude Code and GitHub.

**Time budget:** ~2–3 hours (much of the heavy lifting is done by AI agents)

---

## The paper

Magistro, Borwein, Alvarez, Bonikowski, and Loewen (2026). "Attitudes Toward Artificial Intelligence (AI) and Globalization: Common Microfoundations and Political Implications." *American Journal of Political Science.*

The paper runs a conjoint experiment framing an economic shock as caused by either AI automation or offshoring. The key question: do people evaluate job outcomes differently depending on whether AI or globalization is blamed? N=6,056 (US + Canada, YouGov).

Read `zotero/synthesis.md` before you start. Skim the annotated `zotero/magistro_2026.pdf` if you want more detail.

---

## Setup (~10 min)

1. One group member clicks **Use this template** on GitHub to create your group's repo (e.g., `capstone-group-A`).
2. Add your partner as a collaborator: Settings → Collaborators → Add people.
3. Both members clone the repo locally.
4. Fill in `ROLES.md` — names and branch assignment — and commit to `main`.
5. Each person creates their branch: `git checkout -b replication` or `git checkout -b extension`.

The template includes hooks that protect the workflow: Claude cannot edit `reference_code/`, auto-commit skips `main`, and paper edits trigger a compile check when LaTeX is available.

---

## The workflow

### Step 1 — Validate the data (15 min, replication)

Open `starter/replicate_fig1.R` (or `.py` / `.do`). Before running anything:

```
use spec-validator on data/clean_AJPS.csv
```

Fix any issues the skill flags, then proceed.

### Step 2 — Replicate Figure 1 (30 min, replication)

Fill in `starter/replicate_fig1.R`. The goal is a marginal means plot by treatment condition (AI vs. Offshoring) that visually matches Figure 1 of the paper. `reference_code/main.R` is your guide — read it, don't copy-paste blindly.

Before asking Claude Code to write code, write your instruction in your own words. It should specify:

- the input file
- the reshape target (one respondent-task per row)
- the estimand (marginal means by AI vs. Offshoring treatment)
- the visual target (the Figure 1 style)
- the output path
- the checks you expect it to print before saving the figure

After it runs, inspect the code and output. If you want a second set of eyes, spawn `spec-critic` on the replication script.

When done: commit, push, open a PR into `main`. Your partner reviews and merges.

### Step 3 — Extension analysis (45–60 min, extension)

Fill in `starter/extend_TEMPLATE.R`. Your extension is one of:

- **A — Framing × job type interaction**
- **B — Robustness battery**
- **C — Prior trade attitudes as moderator**

Your assignment is in `CLAUDE.md`. The `robustness-checks` skill is especially useful for Extension B. For A and C, ask Claude to generate the analysis code, then review and run it.

Before opening the PR:

```text
spawn the spec-critic subagent on starter/extend_TEMPLATE.R
```

You can also ask `pr-referee` to review the branch diff, but your partner is still the reviewer who decides whether to merge.

When done: commit, push, open a PR. Your partner reviews and merges.

### Step 4 — Write the research note (45–60 min, extension + writing)

Edit `paper/paper.tex`. The skeleton has `% TODO` markers throughout. Fill in:

- Abstract (3–4 sentences)
- Introduction (motivation, gap, what you do)
- Methods (conjoint design, your extension approach)
- Results (describe your figure/table)
- Discussion (what it means, limits)

Use `latex-regression-table` to generate any tables. Save figures to `paper/figures/`.

Run the `note-reviewer` subagent when you have a full draft:

```
spawn the note-reviewer subagent on paper/paper.tex
```

It runs five prose audits in one shot and returns a consolidated review.

Then trace claims back to outputs:

```text
spawn the results-trace-auditor subagent on paper/paper.tex
use tex-reference-audit on paper/paper.tex
```

Revise, then commit.

### Step 5 — Compile and present (10 min)

```bash
cd paper && latexmk -pdf paper.tex
```

Each group presents for ~5 minutes: what was your extension, what did you find, anything surprising?

### Step 6 — Reflect on the AI workflow (10 min)

Fill in `AI_WORKFLOW_REFLECTION.md`. This is where you separate:

- what was a one-off prompt for this capstone
- what would belong in `CLAUDE.md` for your own project
- what would be worth turning into a skill
- what reviewer role would be worth turning into a subagent
- what safety rule would be worth enforcing with a hook

---

## Extension menu

| Label | Extension |
|-------|-----------|
| A | **Framing × job type interaction** — Does the AI vs. offshoring frame shift preferences differently for data science jobs vs. factory jobs? Estimate the framing effect separately for each job attribute. |
| B | **Robustness battery** — Vary attention-check filter, survey weights, estimator (OLS vs. ordered logit), and task FEs. Produce a specification curve or robustness table. |
| C | **Prior trade attitudes as moderator** — Split by pre-treatment trade liberalization support (`tables_policygr_5`, median split). Do free-traders respond differently to the AI vs. offshoring frame? |

---

## Reference card

Replace `<branch>` with your branch name (`replication` or `extension`).

```bash
# 1. Clone the repo (first time only)
git clone <repo-url>
cd <repo-name>
code .

# 2. Create your branch
git checkout -b <branch>

# 3. Do your work, then commit and push
git add <files>
git commit -m "brief description"
git push -u origin <branch>
```

Then open a PR on GitHub:

1. Click the **Compare & pull request** banner after you push.
2. Base = `main`. Title it clearly (e.g., `Replication: Figure 1`).
3. Add your partner as reviewer.
4. After approval: **Merge pull request** → **Confirm merge**.
5. Pull main locally before starting new work: `git pull origin main`.

**If something breaks:**
- Push rejected? `git pull --rebase origin main` then push again.
- PR against wrong base? Edit it in the GitHub UI.
- Merge conflict? Flag the instructor — it's likely in `paper.tex` and is a useful teaching moment.
- Stuck for more than 2 minutes? Ask Claude Code first, then flag the instructor.

---

## Deliverable

- A compiled `paper/paper.pdf` — 2–3 pages, including your replication figure and extension result.
- A completed `AI_WORKFLOW_REFLECTION.md`.
