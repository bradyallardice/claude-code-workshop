# Session 2 Exercise: From Data to Results

## Setup

You have two datasets in `module_3/data/`:

- `swiss_franc_survey.csv` — a survey of 2,044 Polish adults about government intervention after the 2015 Swiss franc shock
- `respondent_demographics.csv` — additional demographic variables (income, ideology) for survey respondents

Read the codebook in `module_3/docs/codebook.md` before you begin.

## Research Question

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

The survey randomly assigned respondents to one of four conditions before asking about intervention support: a control group (no information), a factual information group, a historical context group, and a Hungary policy comparison group. Your task is to estimate the effect of these treatments on support for government intervention, considering whether the respondent's own exposure to foreign currency loans moderates this effect.

## Part 1: Merge and Explore (30 min)

Use Claude Code in **plan mode** for each step below. Review every plan before approving.

1. **Merge the demographics data into the survey.** The demographics file has more rows than the survey. You will need to decide what join type to use. The merged dataset should have exactly **2,044 rows**.

2. **Explore the merged data.** Ask Claude Code to produce summary statistics and check the data. Before you look at the output, write down what you expect to see.

3. **Verify the merge.** What should you check to confirm the merge worked correctly? Write down your verification checks before running them, then run them.

## Part 2: Specify and Estimate (30 min)

4. **Specify the base model.** Estimate a logistic regression of `supports_intervention` on `treatment`, using survey weights. Before running, decide:
   - What should the reference category for `treatment` be?
   - Tell Claude Code explicitly.

5. **Add FX exposure.** Add `fx_status` to the model. Check: did the sample size change?

6. **Add demographic controls.** Add `age`, `female`, `ed_level`, `urban_rural`, `income_quintile`, and `left_right` to the model. **Before running, predict how many observations you will have.** Then check.

7. **Interact treatment with FX exposure.** Does the information treatment have a different effect on people who are directly affected by the shock?

## Part 3: Robustness and Output (30 min)

8. **Generate robustness checks.** Using your base model from step 4, ask Claude Code to generate at least 4 specification variants:
   - With and without survey weights
   - With different sets of controls (tracking how N changes each time)
   - Collapsing the three treatment arms into a single "any information" dummy vs. control
   - Restricting to a subsample (e.g., urban respondents only)

9. **Format as LaTeX.** Ask Claude Code to produce a publication-style LaTeX regression table with all specifications side by side. Compile to PDF.

10. **Save everything.** All scripts, output, and the LaTeX table should be in `module_3/output/`.
