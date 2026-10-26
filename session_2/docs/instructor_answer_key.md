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
| Add fx_status | **2,035** | 1 additional missing (2 lack FX status; 1 of them also lacks the outcome) |
| Add age + female + ed_level + urban_rural | **2,035** | No additional missingness |
| Add income_quintile | **1,473** | 562 missing income |
| Add left_right (without income) | **1,499** | 536 missing left-right |
| Add both income_quintile and left_right | **1,151** | 884 dropped, 43% of the 2,035 |

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
| (4) | Full controls | 1,151 | +0.267 | 0.118 | **The trap**: N drops 43%, significance vanishes |
| (5) | Pooled treatment | 2,035 | +0.218 | 0.042 | Weaker but significant with pooled arms |
| (6) | Urban only | 1,208 | +0.326 | 0.051 | Subsample restriction, borderline |

---

## Verification Steps (Steps 0, 1, 3, 4, 9, 10)

These are the checks added by the verification section. Values were computed directly from the files in `session_2/data/`.

A runnable reference suite that checks all of these against the solution pipeline is in `session_2/tests/` (see its `README.md`). It is removed from the student branch by `sync_student.sh`.

### Step 4 (the participant's own `CLAUDE.md` rules)
There is no single right answer; the reference protocol (`session_3/docs/verification_protocol.md`) is what Session 3 compares against. Rules worth seeing, each tied to something that happened in Part 1:
- Expected values come from `expectations.md` or the raw files, never from the script's output.
- Ask before choosing the join type (or any design choice), and mark anything Claude proposed itself.
- Never edit a test or an expected value to make it pass; report the failure.
- Report what was not tested, not only what passed.

Weak rules to push back on: generic ("verify carefully"), unfalsifiable (no way to notice a violation), or copied from a slide.

### Step 1: the participant's `expectations.md`
Everything step 1 asks is answerable from the codebook and a look at the CSVs:
- 2,044 rows after the merge, one per survey respondent; the key is `respondent_id`, unique.
- A left join onto the survey: the demographics file has more rows (2,994) and does not cover every respondent, so respondents without a demographics row keep their survey data with missing `income_quintile` and `left_right`. There are 50 of them; the codebook says only "some".
- Missing values: `supports_intervention` 8 and `fx_status` 2 (from the codebook); `income_quintile` and `left_right` also have missing values.
- `income_quintile = 0` means "no income": a valid value, not missing.

Common misses: no answer to "how would you check it?"; expecting an inner join; treating 0 as missing; not thinking through what the 1,000 extra IDs do to a right or outer join.

### Automated checker (Session 4 demo, block 32; not part of Part 1)
The checker works from `docs/codebook.md` and the raw files only. What a good `checks/expectations.md` contains, and where each item can come from:
- **From the codebook:** 2,044 rows; `respondent_id` unique and covering 1–2044; all 11 survey columns present and unchanged; 8 missing `supports_intervention`, 2 missing `fx_status`; `income_quintile` 0 is a valid value, not missing; some respondents have no demographics row, so `income_quintile` and `left_right` have missing values.
- **From the raw files, computed independently:** treatment groups 480 / 549 / 520 / 495; FX status 1,918 / 69 / 55 (+2 missing); 50 survey respondents without a demographics row.

Disagreements worth surfacing in the debrief:
- The builder used an inner join: 1,994 rows, and the checker's row-count check fails. This is the case the design exists to catch.
- The checker expects columns or an output path the builder did not use. These are decisions that lived only in the builder's conversation.
- The checker counts `income_quintile == 0` as missing, against the codebook. The participant should catch this when reading `expectations.md` (checker step 3).

Checker fault injection (checker step 5) duplicates a row of the **merged** file, so it always gives 2,045 rows and a repeated `respondent_id`: the row-count and uniqueness checks should both fail. The survey-respondent subtlety below applies to Part 1's version, which duplicates a row in the demographics file and re-runs the merge.

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
