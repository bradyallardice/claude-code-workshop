# Session 2 Exercise: From Data to Results

## Setup

Run everything from your `session_2` folder (the one you opened in VS Code). You have two datasets in `data/`:

- `swiss_franc_survey.csv` — a survey of 2,044 Polish adults about government intervention after the 2015 Swiss franc shock
- `respondent_demographics.csv` — additional demographic variables (income, ideology) for survey respondents

Read the codebook before you begin. It is `docs/codebook.md`: in VS Code's Explorer panel, click `docs`, then `codebook.md` (right-click it and choose **Open Preview** to read it with its formatting). Full path: `my_workspace/session_2/docs/codebook.md`.

## Research Question

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

The survey randomly assigned respondents to one of four conditions before asking about intervention support: a control group (no information), a factual information group, a historical context group, and a Hungary policy comparison group. Your task is to estimate the effect of these treatments on support for government intervention, considering whether the respondent's own exposure to foreign currency loans moderates this effect.

## Part 1: Learn the Data, Merge, Check, Then Write Tests (Session 2)

Learning the data is the part you never delegate. Write down what a correct merge must look like *before* Claude Code touches the data, check its work against your list yourself, and only then turn your list into tests.

Part 1 comes in two halves. **Part 1a** (steps 1, 2, 3a) is before the lecture on tests; **Part 1b** (steps 3b, 4 and the debrief) is after it.

| Minutes | Step |
|---------|------|
| 0–10 | Step 1: learn the data and write your expectations, **without Claude Code** |
| 10–18 | Step 2: merge and explore in plan mode |
| 18–24 | Step 3a: check the merge yourself against your expectations |
| | *Lecture: how to turn checks into tests (about 20 min)* |
| +0–6 | Step 3b: turn your expectations into a check script, and test it |
| +6–10 | Debrief |
| +10–14 | Step 4: write your own verification rules in `CLAUDE.md` |

1. **Learn the data and write your expectations, without Claude Code.** Read `docs/codebook.md` and open both CSV files in `data/`. Then fill in the template in `expectations.md`, which is already in your `session_2` folder (for each expectation: what must be true, how you know, and how to check it; *What I found* comes later). Cover:
   - How many rows should the merged file have, and which key links the two files?
   - Which join type, and why? What happens to survey respondents with no demographics row?
   - Which variables have missing values, and how many do you expect?
   - What does `income_quintile = 0` mean, and how must it be treated?
   - For each answer: how would you check it?

   These are your expectations. Write them now, before the merge. Afterwards you add what you found under each one, but you never edit the expectation itself.

2. **Merge the demographics data into the survey**, in **plan mode**, and save the result as `output/merged_survey.csv`. Review every plan before approving.
   - **Make it a script.** Ask Claude Code to write the merge as a script in `scripts/`, in the language you use (`scripts/merge.do`, `scripts/merge.R` or `scripts/merge.py`), with the paths of the two input files and of the output file set at the top of the script, and to run it to produce `output/merged_survey.csv`. Step 3b and Session 3 build on this script.
   - The demographics file has more rows than the survey. **You decide the join type.** Do not let Claude Code choose.
   - Then explore the merged data: summary statistics, treatment group sizes, and the outcome distribution.

3a. **Check it yourself, without Claude Code.**
   - For each expectation, run the check yourself in the tool you use (for example Stata `count` or `duplicates report`, R `nrow()` or `anyDuplicated()`, or open the CSV), and fill in *What I found* under it: met or not met, with what you saw.
   - Trace three respondents from the raw files to the merged data: one typical, one with a missing outcome, and one who is absent from the demographics file.
   - An expectation turned out wrong? Say so under *What I found*. Do not edit the expectation.

   **Stop here.** The lecture that follows shows how to turn what you just checked into tests.

3b. **Turn what you wrote into tests** (after the lecture). Give Claude Code these instructions in your own words, one at a time.
   1. **Ask for a check script** made from your `expectations.md`: saved in the `tests` folder, in the language you use (a Stata do-file, an R script, or Python), printing PASS or FAIL for each expectation. No extra packages are needed. Your merge script makes the data; this separate file only checks it.
   2. **Read it before it runs:** does each check test your sentence, with your number?
   3. **Run it** (ask Claude Code, or run it yourself like any script). Does it agree with what you found by hand? If not, find out why; do not change the check to make it pass.
      Running it yourself from the Stata or RStudio app? First set the working folder to `session_2`: in Stata `cd ~/my_workspace/session_2`, in R `setwd("~/my_workspace/session_2")` (on Windows the folder is `C:\Users\<your name>\my_workspace\session_2`). Or ask Claude Code to run it.
   4. **Make running it a rule:** ask Claude Code to add a **Tests** section to `CLAUDE.md` that says to run the check script after any change to code or data and show the full output; to stop and say which check failed and why; and never to edit the tests or expected values to make them pass.
   5. **Save your traced respondents too:** ask for a check for each one (its ID and the values you confirmed), so the trace reruns with everything else.

   **Test your tests.** Break a copy on purpose, one instruction at a time:
   1. **Make a broken copy.** Ask Claude Code to copy the demographics file into `output/` and, in the copy, duplicate the row of one respondent who is **also in the survey**. The original in `data/` stays untouched.
   2. **Merge with the broken copy.** Point the demographics path at the top of your merge script at the copy in `output/`, and run the merge. It writes `output/merged_survey.csv` as usual, now from the broken copy.
   3. **Run your check script, unchanged,** and read the full output. The row-count check and the one-row-per-respondent check should FAIL. If everything passes, your checks cannot see a duplicate: add one that can.
   4. **Put it back.** Point the merge script at the original file in `data/` again, run the merge, then run the checks: all PASS.
   5. **Clean up:** delete the broken copy. Never edit the files in `data/`.

4. **Write your own verification rules.** Open the `CLAUDE.md` you started in step 3b (it has your Tests section) and add **3–5 rules of your own, in your own words**, each from something that happened in Part 1. For each rule write: the failure (what happened, or nearly happened), the rule (one specific instruction to Claude Code), and the check (how you would notice it was broken). Rules take effect in a new conversation. Keep the file: Session 3 builds on it.

### Debrief questions

- Which of your expectations turned out to be wrong? Was the error yours, or Claude Code's?
- What did you learn about the data that the codebook did not say outright?
- Did Claude Code's tests check what you wrote, or something easier?
- Where did Claude Code cut a corner you had not asked for? Which of your rules would have prevented it?

---

**Parts 2 and 3 are in Session 3.** Keep your `my_workspace/session_2` folder as it is: Session 3 continues the exercise in it. The instructions are in `session_3/docs/exercise_prompt.md`.
