---
name: robustness-checks
description: Use when generating or auditing Extension B robustness checks, specification grids, specification curves, or robustness tables. Tracks sample size, estimator, attention filtering, weights, and task fixed effects.
---

# Robustness Checks

Use this skill for Extension B or for auditing any robustness battery. The user chooses the analysis target; you generate and verify variants.

## Capstone robustness grid

Run the main AI vs. Offshoring framing effect across all combinations of:

- attention filter: all respondents vs. `manipulation_check2 == "Pass"`
- weights: unweighted vs. weighted placeholder if no valid weight exists
- estimator: OLS vs. ordered logit
- task fixed effects: absent vs. present

For each specification, record:

- specification label
- exact sample restriction
- estimator
- fixed effects included
- number of observations
- number of respondents
- estimate
- standard error or confidence interval
- convergence or warning messages

## Verification rules

1. Print sample size for every specification.
2. Explain any N changes before interpreting estimates.
3. Do not call a result "robust" if the sample changes and the change is not discussed.
4. Keep the main identifying specification fixed unless the user explicitly changes it.
5. Save a machine-readable results file to `paper/tables/`.
6. Save the specification curve or table to `paper/figures/extension_result.png` or `paper/tables/main.tex`.

## Output format

Return a concise summary with:

- grid size
- specifications that failed
- largest sample-size changes
- whether signs and magnitudes are stable
- exact output files created
