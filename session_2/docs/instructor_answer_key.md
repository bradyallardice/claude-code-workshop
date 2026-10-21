# Instructor Answer Key: Session 2 Exercise

**Do not distribute to students.** This contains the expected values for all verification steps.

---

## After the Merge (Steps 1-3)

### Demographics merge (`respondent_demographics.csv`)
- The demographics file has **2,994 rows** — 1,994 real respondents + 1,000 fake respondent IDs that don't match anyone in the survey.
- 50 real respondents are missing from the demographics file entirely.
- **Only a left join is correct.** Results by join type:
  - Left join: **2,044 rows** (correct — 50 respondents get NaN for demographics)
  - Inner join: **1,994 rows** (loses 50 survey respondents)
  - Right join: **2,994 rows** (adds ~1,000 fake respondents)
  - Outer join: **3,044 rows** (both problems)
- If students get anything other than 2,044 rows, they used the wrong join type.

### Verification checks students should think of
- [ ] Row count: **exactly 2,044 rows** after merge
- [ ] No duplicate respondent IDs in the merged output
- [ ] Treatment groups: Control **480** | Info **549** | History **520** | Hungary **495**
- [ ] Total with non-missing outcome (`supports_intervention`): **2,036**
- [ ] Proportion supporting intervention (unweighted): approximately **0.479**
- [ ] Weighted proportion: approximately **0.486**

## FX Exposure

- [ ] Current FX borrowers: **69** | Past borrowers: **55** | Never borrowed: **1,918** | Missing: **2**

## The Missing Data Trap (Step 6)

This is the most important teaching moment in the exercise.

| Specification | Expected N | What happened |
|--------------|-----------|---------------|
| Base model: treatment only | **2,036** | Full sample (8 missing outcome) |
| Add fx_status | **2,035** | 1 additional missing |
| Add age + female + ed_level + urban_rural | **2,035** | No additional missingness |
| Add income_quintile | ~**1,473** | 565 missing income (525 original + ~40 from missing demographics) |
| Add left_right | ~**1,499** | 542 missing left-right (504 original + ~38 from missing demographics) |
| Add both income_quintile and left_right | ~**1,151** | 44% of sample dropped |

**If Claude Code does not mention the sample size change when you add controls, that is the teaching moment.**

The info treatment goes from **p=0.016** (significant) in the base model to **p=0.118** (not significant) with full controls — primarily because of the sample change, not because the controls explain away the effect.

## Income Quintile = 0

- [ ] **8 respondents** have `income_quintile = 0`, meaning "no income." This is a valid value, not missing data. If Claude Code treats 0 as missing or drops these rows, intervene.

## Survey Weights

- [ ] Unweighted proportion supporting intervention: **0.479**
- [ ] Weighted proportion supporting intervention: **0.486**

## Base Model Coefficients

### Weighted (what the exercise asks for)
| Variable | Coefficient | SE | p-value |
|----------|-----------|------|---------|
| Intercept | -0.219 | 0.093 | 0.019 |
| Info treatment | +0.302 | 0.126 | 0.016 |
| History treatment | +0.123 | 0.128 | 0.337 |
| Hungary treatment | +0.194 | 0.130 | 0.134 |

### Unweighted (for comparison)
| Variable | Coefficient | SE | p-value |
|----------|-----------|------|---------|
| Intercept | -0.210 | 0.092 | 0.022 |
| Info treatment | +0.290 | 0.126 | 0.021 |
| History treatment | +0.047 | 0.127 | 0.710 |
| Hungary treatment | +0.145 | 0.129 | 0.261 |

Key pattern: the info treatment increases support for intervention; the other treatments do not have statistically significant effects.

## Robustness Table Reference

| Col | Label | N | Info coef | Info p | Key lesson |
|-----|-------|---|-----------|--------|------------|
| (1) | Base (weighted) | 2,036 | +0.302 | 0.016 | Baseline |
| (2) | Base (unweighted) | 2,036 | +0.290 | 0.021 | Weighting changes coefficients slightly |
| (3) | + Controls | 2,035 | +0.324 | 0.011 | Controls don't change story, same N |
| (4) | Full controls | 1,151 | +0.267 | 0.118 | **The trap**: N drops 44%, significance vanishes |
| (5) | Pooled treatment | 2,035 | +0.218 | 0.042 | Weaker but significant with pooled arms |
| (6) | Urban only | 1,208 | +0.326 | 0.051 | Subsample restriction, borderline |

---

## Verification Steps (Warm-Up, Steps 1, 3, 4, 9, 10)

These are the checks added by the verification section. Values were computed directly from the files in `session_2/data/`.

### Warm-up
- After the student copies `docs/verification_protocol.md` into `CLAUDE.md`, asking "What verification rules apply in this project?" should return a description of the protocol. If Claude Code does not describe it, the file is in the wrong folder or has the wrong name.

### Fault injection (Step 3)
- The duplicated row must belong to a **survey respondent**. The demographics file contains 1,000 IDs that match no survey respondent, and duplicating one of those leaves a left join at 2,044 rows, so the tests correctly **pass**. Students who pick a non-survey ID will think their tests are broken.
- Example: duplicating the demographics row for `respondent_id` 299 gives **2,045 rows** after a left join and a non-unique `respondent_id`. The row-count test and the key-uniqueness test should both fail.
- Watch for: a student whose tests still pass after injecting the fault. Either the fault did not touch what the tests check, or the tests are not testing the merge output.

### Independent check on the base model (Step 4)
- Base model: weighted logistic regression of `supports_intervention` on `treatment`, reference category `cntrl`, N = 2,036.
- logistic(intercept) = logistic(-0.219) = **0.4455**, which equals the weighted share of supporters in the control group among respondents with a non-missing outcome (**478** respondents), computed directly from the raw CSV.
- The unweighted share is **0.4477** (and logistic of the unweighted intercept, -0.210, is also 0.4477). The two differ in the third decimal, so this check detects whether weights were applied.
- The same identity holds for each other arm: logistic(intercept + arm coefficient) equals that arm's weighted share (info 0.5209, history 0.4761, Hungary 0.4939). It holds because the model is saturated in treatment.
- It stops holding once controls are added. It is a check for the base model only.

### Sample accounting (Steps 4-7)
- The reconciliation for each model should reproduce the table in "The Missing Data Trap" above, with a reason for each drop.

### Output manifest and audit report (Steps 9-10)
- The manifest test should find every specification in the table, each with its N.
- Things the audit report should flag as needing the student's judgment: the join type, the treatment of `income_quintile = 0`, and the 44% sample loss when both income and left-right are added.
- Watch for: an audit report that says "all tests passed" with no "not tested" or "not covered" entries, tests whose expected values were copied from the script's own output, and expected values or assertions edited after a failure.
