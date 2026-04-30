---
name: latex-regression-table
description: Use when creating or updating LaTeX regression, robustness, or summary tables for paper/tables/. Produces booktabs tables with clear notes, model labels, N, and reproducible source output.
---

# LaTeX Regression Table

Use this skill when converting analysis output into a table for `paper/paper.tex`.

## Table conventions

1. Save LaTeX tables under `paper/tables/`.
2. Use `booktabs` style: `\toprule`, `\midrule`, `\bottomrule`.
3. Include model labels that describe the specification, not just numbers.
4. Include `N` and, where relevant, respondent count.
5. Include standard error or confidence interval notation in the table note.
6. Include clear notes for:
   - estimator
   - fixed effects
   - attention filter
   - weights
   - reference category
7. Do not paste console output directly into the manuscript.
8. Ensure `paper/paper.tex` includes the table with `\input{tables/<name>.tex}`.

## Verification

Before finalizing:

- Confirm every number in the `.tex` table comes from a saved script output.
- Confirm the table compiles.
- Confirm the caption does not overinterpret the estimate.
- Confirm labels fit in a 2-3 page note.

Return the table path and the script/output file used to generate it.
