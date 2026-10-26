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
| 0–10 | Step 1: learn the data and write your expectations, **without Claude Code** |
| 10–22 | Step 2: merge and explore in plan mode |
| 22–27 | Step 3: verify the output against your expectations |
| 27–31 | Debrief |
| 31–35 | Step 4: write your own verification rules in `CLAUDE.md` |

1. **Learn the data and write your expectations, without Claude Code.** Read `docs/codebook.md` and open both CSV files in `data/`. Then write your expectations in `expectations.md`, which is already in your `session_2` folder. Cover:
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

4. **Write your own verification rules.** Create `CLAUDE.md` in your `session_2` folder and write **3–5 rules in your own words**, each from something that happened in Part 1. For each rule write: the failure (what happened, or nearly happened), the rule (one specific instruction to Claude Code), and the check (how you would notice it was broken). Rules take effect in a new conversation. Keep the file: Session 3 builds on it.

### Debrief questions

- Which of your expectations turned out to be wrong? Was the error yours, or Claude Code's?
- What did you learn about the data that the codebook did not say outright?
- Did Claude Code's tests check what you wrote, or something easier?
- Where did Claude Code cut a corner you had not asked for? Which of your rules would have prevented it?

---

**Parts 2 and 3 are in Session 3.** Keep your `my_workspace/session_2` folder as it is: Session 3 continues the exercise in it. The instructions are in `session_3/docs/exercise_prompt.md`.
