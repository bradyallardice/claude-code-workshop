# Session 2 Exercise: From Data to Results

## Setup

You have two datasets in `session_2/data/`:

- `swiss_franc_survey.csv` — a survey of 2,044 Polish adults about government intervention after the 2015 Swiss franc shock
- `respondent_demographics.csv` — additional demographic variables (income, ideology) for survey respondents

Read the codebook in `session_2/docs/codebook.md` before you begin.

## Research Question

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

The survey randomly assigned respondents to one of four conditions before asking about intervention support: a control group (no information), a factual information group, a historical context group, and a Hungary policy comparison group. Your task is to estimate the effect of these treatments on support for government intervention, considering whether the respondent's own exposure to foreign currency loans moderates this effect.

## Warm-Up: Install the Verification Protocol (10 min)

1. **Add the protocol to your project.** Copy `docs/verification_protocol.md` into a file named `CLAUDE.md` in your `session_2` folder. If you already have a `CLAUDE.md`, append it.

2. **Check that Claude Code sees it.** Start Claude Code in the `session_2` folder and ask: "What verification rules apply in this project?" Its answer should describe the protocol.

3. **Write a requirements-to-tests matrix by hand**, without Claude Code. For the merge you are about to do, write three rows: a requirement, the test that checks it, and the condition under which the test passes.

## Part 1: Merge and Explore (30 min)

Use Claude Code in **plan mode** for each step below. Review every plan before approving.

1. **Merge the demographics data into the survey.** The demographics file has more rows than the survey. You will need to decide what join type to use. The merged dataset should have exactly **2,044 rows**.
   - Tests first: have Claude Code write the verification tests from your matrix, and read them before it writes the merge.

2. **Explore the merged data.** Ask Claude Code to produce summary statistics and check the data. Before you look at the output, write down what you expect to see.

3. **Verify the merge.**
   - Run the tests.
   - Trace three respondents from the raw files to the merged data: one typical, one with a missing outcome, and one who is absent from the demographics file.
   - Test the tests: make a **copy** of the demographics file with the row of one survey respondent duplicated, run the merge tests on the copy, and confirm that they fail. Never edit the files in `data/`.

## Part 2: Specify and Estimate (30 min)

4. **Specify the base model.** Estimate a logistic regression of `supports_intervention` on `treatment`, using survey weights. Before running, decide:
   - What should the reference category for `treatment` be?
   - Tell Claude Code explicitly.
   - Independent check: the logistic of the model's intercept should equal the weighted share of supporters in the control group. Compute that share directly from the raw CSV, without using the model code, and compare.

5. **Add FX exposure.** Add `fx_status` to the model. Check: did the sample size change?

6. **Add demographic controls.** Add `age`, `female`, `ed_level`, `urban_rural`, `income_quintile`, and `left_right` to the model. **Before running, predict how many observations you will have.** Then check.

7. **Interact treatment with FX exposure.** Does the information treatment have a different effect on people who are directly affected by the shock?

For every model in steps 4-7, reconcile the sample size: rows in, minus rows dropped (by reason), equals N used.

## Part 3: Robustness and Output (30 min)

8. **Generate robustness checks.** Using your base model from step 4, ask Claude Code to generate at least 4 specification variants:
   - With and without survey weights
   - With different sets of controls (tracking how N changes each time)
   - Collapsing the three treatment arms into a single "any information" dummy vs. control
   - Restricting to a subsample (e.g., urban respondents only)

9. **Format as LaTeX.** Ask Claude Code to produce a publication-style LaTeX regression table with all specifications side by side. Compile to PDF. Add an output manifest test: every specification appears in the table, each with its N.

10. **Audit report.** Ask Claude Code to write `session_2/output/audit_report.md` covering: the tests run (with passed, failed, and skipped counts), each requirement and the test that covers it, anything not tested, numerical checks (your value against the independent value), choices that need your judgment, and what the tests do not cover.

11. **Save everything.** All scripts, tests, output, and the LaTeX table should be in `session_2/output/`.
