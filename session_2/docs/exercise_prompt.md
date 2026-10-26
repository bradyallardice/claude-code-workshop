# Session 2 Exercise: From Data to Results

## Setup

You have two datasets in `session_2/data/`:

- `swiss_franc_survey.csv` — a survey of 2,044 Polish adults about government intervention after the 2015 Swiss franc shock
- `respondent_demographics.csv` — additional demographic variables (income, ideology) for survey respondents

Read the codebook in `session_2/docs/codebook.md` before you begin.

## Research Question

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

The survey randomly assigned respondents to one of four conditions before asking about intervention support: a control group (no information), a factual information group, a historical context group, and a Hungary policy comparison group. Your task is to estimate the effect of these treatments on support for government intervention, considering whether the respondent's own exposure to foreign currency loans moderates this effect.

## Part 1: Learn the Data, Then Merge and Verify (Session 2, 35 min)

Learning the data is the part you never delegate. Write down what a correct merge must look like *before* Claude Code touches the data, then check its work against your list.

| Minutes | Step |
|---------|------|
| 0–2 | Step 0: install the verification protocol |
| 2–12 | Step 1: learn the data and write your expectations, **without Claude Code** |
| 12–24 | Step 2: merge and explore in plan mode |
| 24–29 | Step 3: verify the output against your expectations |
| 29–35 | Debrief |

0. **Install the verification protocol.** Copy `docs/verification_protocol.md` into a file named `CLAUDE.md` in your `session_2` folder. If you already have a `CLAUDE.md`, append it. Start Claude Code in the `session_2` folder and ask: "What verification rules apply in this project?" Its answer should describe the protocol.

1. **Learn the data and write your expectations, without Claude Code.** Read `docs/codebook.md` and open both CSV files in `data/`. Then write `expectations.md` in your `session_2` folder, answering:
   - How many rows should the merged file have, and which key links the two files?
   - Which join type, and why? What happens to survey respondents with no demographics row?
   - Which variables have missing values, and how many do you expect?
   - What does `income_quintile = 0` mean, and how must it be treated?
   - For each answer: how would you check it?

   These are your expectations. Claude Code writes its tests from this file.

2. **Merge the demographics data into the survey**, in **plan mode**, and save the result as `output/merged_survey.csv`. Review every plan before approving.
   - Tests first: "Write the merge tests from expectations.md." Read the tests before Claude Code writes the merge.
   - The demographics file has more rows than the survey. **You decide the join type.** Do not let Claude Code choose.
   - Then explore the merged data: summary statistics, treatment group sizes, and the outcome distribution.

3. **Verify it yourself.** Go down `expectations.md` and mark each item met or not met, with the evidence.
   - Run the tests. Trace three respondents from the raw files to the merged data: one typical, one with a missing outcome, and one who is absent from the demographics file.
   - Test the tests: make a **copy** of the demographics file with the row of one survey respondent duplicated, run the merge tests on the copy, and confirm that they fail. Never edit the files in `data/`.

### Debrief questions

- Which of your expectations turned out to be wrong? Was the error yours, or Claude Code's?
- What did you learn about the data that the codebook did not say outright?
- Did Claude Code's tests check what you wrote, or something easier?

---

**Parts 2 and 3 are in Session 3.** Keep your `my_workspace/session_2` folder as it is: Session 3 continues the exercise in it.

## Part 2: Specify and Estimate (25 min)

4. **Specify the base model.** Estimate a logistic regression of `supports_intervention` on `treatment`, using survey weights. Before running, decide:
   - What should the reference category for `treatment` be?
   - Tell Claude Code explicitly.
   - Independent check: the logistic of the model's intercept should equal the weighted share of supporters in the control group. Compute that share directly from the raw CSV, without using the model code, and compare.

5. **Add FX exposure.** Add `fx_status` to the model. Check: did the sample size change?

6. **Add demographic controls.** Add `age`, `female`, `ed_level`, `urban_rural`, `income_quintile`, and `left_right` to the model. **Before running, predict how many observations you will have.** Then check.

7. **Interact treatment with FX exposure.** Does the information treatment have a different effect on people who are directly affected by the shock?

For every model in steps 4-7, reconcile the sample size: rows in, minus rows dropped (by reason), equals N used.

## Part 3: Robustness and Output (25 min)

8. **Generate robustness checks.** Using your base model from step 4, ask Claude Code to generate at least 4 specification variants:
   - With and without survey weights
   - With different sets of controls (tracking how N changes each time)
   - Collapsing the three treatment arms into a single "any information" dummy vs. control
   - Restricting to a subsample (e.g., urban respondents only)

9. **Format as LaTeX.** Ask Claude Code to produce a publication-style LaTeX regression table with all specifications side by side. Compile to PDF. Add an output manifest test: every specification appears in the table, each with its N.

10. **Audit report.** Ask Claude Code to write `session_2/output/audit_report.md` covering: the tests run (with passed, failed, and skipped counts), each requirement and the test that covers it, anything not tested, numerical checks (your value against the independent value), choices that need your judgment, and what the tests do not cover.

11. **Save everything.** All scripts, tests, output, and the LaTeX table should be in `session_2/output/`.
