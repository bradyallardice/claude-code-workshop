# Session 2 Exercise: From Data to Results

## Setup

You have two datasets in `session_2/data/`:

- `swiss_franc_survey.csv` — a survey of 2,044 Polish adults about government intervention after the 2015 Swiss franc shock
- `respondent_demographics.csv` — additional demographic variables (income, ideology) for survey respondents

Read the codebook in `session_2/docs/codebook.md` before you begin.

## Research Question

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

The survey randomly assigned respondents to one of four conditions before asking about intervention support: a control group (no information), a factual information group, a historical context group, and a Hungary policy comparison group. Your task is to estimate the effect of these treatments on support for government intervention, considering whether the respondent's own exposure to foreign currency loans moderates this effect.

## Part 1: Merge and Explore, With Two Tabs (Session 2, 35 min)

You run two Claude Code tabs in your `session_2` folder. Each has one role.

- **Builder (tab 1)** installs the verification protocol, then merges and explores in plan mode. You direct it and make the design decisions.
- **Checker (tab 2)** is a fresh tab that never sees the builder's conversation or code. Claude drafts the expectations and checks from the codebook and the research question; **you review them**.

The tabs share nothing except files. Anything one tab needs to know, put in a file.

| Minutes | What happens |
|---------|--------------|
| 0–5 | Builder: install the protocol (step 0). Then open the checker tab and send its prompt |
| 5–22 | Builder: merge and explore. Between plans, read the checker's expectations |
| 22–27 | Run the checker's checks on the builder's output, and compare |
| 27–35 | Debrief |

### Builder (tab 1)

0. **Install the verification protocol.** Copy `docs/verification_protocol.md` into a file named `CLAUDE.md` in your `session_2` folder. If you already have a `CLAUDE.md`, append it. Start Claude Code in the `session_2` folder and ask: "What verification rules apply in this project?" Its answer should describe the protocol. Then open the checker tab (`Cmd+Shift+Esc` on Mac, `Ctrl+Shift+Esc` on Windows) and send it the prompt below.

1. **Merge the demographics data into the survey**, in **plan mode**, and save the result as `output/merged_survey.csv`. Review every plan before approving.
   - The demographics file has more rows than the survey. **You decide the join type.** Do not let Claude Code choose.
   - Tests first: read the tests Claude Code writes before it writes the merge.

2. **Explore the merged data.** Ask Claude Code for summary statistics, treatment group sizes, and the outcome distribution. Before you look at the output, write down what you expect to see.

3. **Verify the merge.** Run the tests. Trace three respondents from the raw files to the merged data: one typical, one with a missing outcome, and one who is absent from the demographics file.

### Checker (tab 2)

Never paste anything from the builder's conversation into this tab. Send it:

```
You are an independent checker. Another session is merging
data/swiss_franc_survey.csv with data/respondent_demographics.csv
and will save output/merged_survey.csv. You will not see its code.
Use only docs/codebook.md, the raw files in data/, and this
research question: does information about the Swiss franc crisis
increase support for government intervention?
Do not open anything in scripts/, tests/, or output/.
1. Write checks/expectations.md: what a correct merged file must
   satisfy (rows, keys, columns, missing values, group sizes),
   and where each expectation comes from.
2. Write checks/check_merge.py, which takes a file path (default
   output/merged_survey.csv) and tests every expectation.
   Do not run it yet.
```

3. **Review `checks/expectations.md`.** Claude drafted it to save time, since you don't know this data well yet. Reviewing it is your job: correct anything wrong before any check runs.
4. When the builder has saved its output, tell the checker: "Run checks/check_merge.py and report each result."
5. **Test the checks:** "Copy the merged file with one row duplicated, run the checks on the copy, and show me which fail." Never edit the files in `data/`.

### Debrief questions

- Where did the builder's tests and the checker's checks disagree? Which one was right?
- The checker never saw your decisions. Which ones did it need (join type, output path, ...), and which had to be written into a file to reach it?
- Did anyone lose work to a collision, or find a tab stalled on a permission prompt?

---

**Parts 2 and 3 are in Session 3.** Keep your `my_workspace/session_2` folder as it is: Session 3 continues the exercise in it.

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
