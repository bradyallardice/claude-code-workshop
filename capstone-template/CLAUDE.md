# CLAUDE.md — Capstone Project

## Project overview

This is a group capstone for the AI-assisted research workflow workshop. You are replicating and extending Magistro et al. 2026 ("Attitudes Toward AI and Globalization"), a conjoint survey experiment published in AJPS (N=6,056, US + Canada).

## Repository layout

- `data/clean_AJPS.csv` — cleaned conjoint data (all analyses run from here)
- `data/Codebook_AJPS.pdf` — variable definitions and coding
- `reference_code/` — original Magistro R scripts; **read-only, do not modify**
- `starter/` — your working files; edit these
- `paper/paper.tex` — your research note; edit this
- `paper/refs.bib` — bibliography; add entries here
- `paper/tables/` — LaTeX tables go here (populated by `latex-regression-table`)
- `zotero/` — synthesis and annotated PDF provided by instructor

## Your extension assignment

**Fill this in on your first commit:**

> Extension: _______________________________________________
> Group members: _______________________________________________

Choose one of:
- **A — Framing × job type interaction:** Does the AI vs. offshoring framing shift preferences differently for data science jobs vs. factory jobs? Estimate the framing effect separately for each job attribute and test whether the interaction differs.
- **B — Robustness battery:** Rerun the main AI vs. offshoring framing effect varying: attention-check filter (pass only vs. all), survey weights (on/off), estimator (OLS vs. ordered logit), and task fixed effects (on/off). Produce a specification curve.
- **C — Prior trade attitudes as moderator:** Split the sample by pre-treatment support for trade liberalization (`tables_policygr_5`, median split) and test whether free-trade supporters respond differently to the AI vs. offshoring framing. Connects the conjoint to the paper's downstream microfoundations argument.

## Conventions

- R, Python, or Stata — group's choice; be consistent
- Run all scripts from the repo root: `capstone-template/`
- Data path: `data/clean_AJPS.csv`
- `reference_code/` is read-only — copy and adapt, never edit in place
- Figures save to `paper/figures/`, tables to `paper/tables/`

## Skills available

Use these Claude Code skills at the appropriate steps:

| Step | Skill |
|------|-------|
| Validate data before analysis | `spec-validator` |
| Extension analysis | `robustness-checks` (Extension B especially) |
| Generate regression tables | `latex-regression-table` |
| Full paper review | `/note-reviewer` subagent (runs 5 audits in one shot) |
| Individual prose audits | `intro-structure-audit`, `abstract-structure-audit`, `paragraph-structure-audit`, `causal-language-audit`, `llm-prose-audit` |
| Check citations and cross-refs | `tex-reference-audit` |
| Track analysis decisions | `research-docs` |
