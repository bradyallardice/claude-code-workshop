# Session 3 Exercises

Session 3 has three exercise blocks. Parts 2 and 3 continue the Swiss franc project in your **`session_2` folder**. The results-to-paper exercise runs in the `results_to_paper/` folder of this `session_3` copy.

## Research question (unchanged from Session 2)

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

Codebook: `session_2/docs/codebook.md`.

---

## Part 2: Matrix, Tests, and Estimation (25 min) — in your `session_2` folder

Reopen your `my_workspace/session_2` folder in VS Code and start a new conversation. Your `CLAUDE.md` (your own verification rules from Session 2 step 4), your `expectations.md`, your merge script, and `output/merged_survey.csv` from Session 2 Part 1 should be there. If your merge did not finish, ask Claude Code to finish it and run its tests first; everything below depends on it.

### Step A: Audit your own expectations, then extend them (6 min)

**1. Audit (3 min).** Open the `expectations.md` you wrote in Session 2. For each expectation, ask:
- Where did it come from (codebook, design, raw data)?
- What source other than the pipeline checks it?
- What exact result counts as a pass?

Mark each expectation that is **too vague to fail**, **reuses the code it checks**, or **rests on a judgment instead of a number**. Rewrite those.

**2. Extend (3 min).** Turn it into `docs/requirements_matrix.md`, one row per requirement, five columns:

| Requirement | Source | Test | Independent truth | Passing condition |
|---|---|---|---|---|

Add **at least four rows for the model** (reference category, weights, outcome, sample). The requirements are yours: write them yourself. Two starter ideas: *the reference arm is control*, and *survey weights are used* (the logistic of the base-model intercept should equal the weighted control share, computed from the raw CSV). Then ask Claude Code to **review** your rows for the three weak patterns. It reviews; it does not write them.

### Step B: Tests for the new rows (3 min)

As in Session 2: ask Claude Code to write a test for each new row and show you the tests **before** it writes any model code. Run them. They should fail, because nothing has been estimated yet. Read each test: does its expected value come from the raw files, or from the pipeline it checks?

### Step C: Specify and estimate (16 min)

3. **Base model.** Logistic regression of `supports_intervention` on `treatment`, using survey weights. Tell Claude Code the reference category explicitly. Run your matrix tests.
4. **Add FX exposure** (`fx_status`). Did the sample size change? Why?
5. **Add demographic controls:** `age`, `female`, `ed_level`, `urban_rural`, `income_quintile`, `left_right`. **Predict your N before running.** Add a matrix row and a test for it, then run the model.
6. *If time:* interact treatment with FX exposure.

For every model, reconcile the sample size: rows in, minus rows dropped (by reason), equals N used. **If a test fails, fix the code or fix the row, and say which you did and why.**

---

## Part 3: Robustness, Output, and the Audit Report (25 min) — in your `session_2` folder

7. **Robustness variants** from your base model:
   - With and without survey weights
   - Different control sets (track how N changes each time)
   - The three treatment arms collapsed into "any information" vs. control
   - A subsample (for example, urban respondents only)

   **Add a matrix row for each:** what must change, and what must stay the same? (The unweighted estimate should differ from the weighted one; the collapsed model has one treatment coefficient, not three.)

8. **LaTeX table.** All specifications side by side, compiled to PDF. Add an output-manifest test: every specification appears in the table, each with its N, and the table cells match the model output.

9. **Audit report**, `output/audit_report.md`, **built from your matrix.** Use the six sections from the slides: tests run (passed, failed, skipped), requirements (each matrix row, its test, its result), not tested, numerical checks (your value against the independent value, with a tolerance), needs your call, not covered. A matrix row with no test goes under *Not tested*. Then read it as an adversary: are its gaps as visible as its passes?

10. **Revise your `CLAUDE.md`.** Pick one gap the audit report exposed (a row with no test, a judgment call nobody checked, something under *Not covered*) and write the rule that would have caught it, in your own words: the failure, the rule, how you would notice a violation. Then open `verification_protocol.md`, a reference protocol, and compare. It is in the course repo's `session_3/docs/` folder, and in your `my_workspace/session_3/docs/` copy, not in your `session_2` folder. Which of your rules does it lack? Which of its rules do you lack, and which failure of yours would each have prevented?

11. **Commit.** Save the scripts, tests, matrix, output, table, report, and `CLAUDE.md`. (If git is not set up yet, do it after the git frames: `git init`, then commit.)

---

## Exercise: Results → Paper (25 min) — in `session_3/results_to_paper/`

Open `my_workspace/session_3/results_to_paper` in VS Code (File → New Window → Open Folder). It contains:

| File | What it is |
|------|------------|
| `paper.tex` | Paper skeleton: a Data section, and a Results section with the table but no text |
| `results/regression_results.csv` | Regression results for six specifications, one row per coefficient |
| `scripts/render_regression_table.py` | Turns the CSV into a LaTeX table fragment |

The results are the same for everyone, so you can compare notes. They are not your own Part 3 output.

1. **Set up git before anything else.** In the terminal, check that you are inside `results_to_paper/` (`pwd`), then run `git init`. If your `my_workspace` folder is itself inside a git repository (for example the cloned course repo), `git init` here creates a nested repository: move your copy out of the course repo first. Ask Claude Code to write a `.gitignore` for LaTeX build files (`*.aux`, `*.log`, `*.out`, `*.fdb_latexmk`, `*.fls`, `*.synctex.gz`) and for `.env` and `__pycache__/`. Then `git add -A && git commit -m "Paper skeleton"`.

2. **Render the table into the paper.** Ask Claude Code to run the render script, then compile `paper.tex`. Open `tables/regression_table.tex` and `results/regression_results.csv` yourself: does the table say what the CSV says? Commit.

3. **Write the results paragraph.** Ask Claude Code to write the paragraph for the Results section from the table. Commit first, so you have a save point. VS Code shows you the diff before it applies the change: read it, then accept or reject it. If you accept it, say what you changed or would change. (If you accept and regret it later, `git checkout -- .` takes you back to the commit.)

4. **Cross-check every number.** In a **fresh conversation**, ask Claude Code to list every number in the results paragraph and the table cell it comes from, and to flag any claim the table does not support. Then answer for yourself: what can this check not catch?

5. **Commit.** `git log --oneline` should show your history.

### Debrief questions

- Which sentences in the paragraph went beyond what the table can support?
- Did the check find anything you missed when you read the diff in VS Code, or the reverse?
- What did you reject, and what did the commit make cheap?
