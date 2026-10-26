# Session 3 Exercises

Session 3 has three exercise blocks. Parts 2 and 3 continue the Swiss franc project in your **`session_2` folder**. The results-to-paper exercise runs in the `results_to_paper/` folder of this `session_3` copy.

## Research question (unchanged from Session 2)

**Does providing information about the Swiss franc crisis increase support for government intervention to help affected borrowers?**

Codebook: `session_2/docs/codebook.md`.

---

## Part 2: Specify and Estimate (25 min) — in your `session_2` folder

Reopen your `my_workspace/session_2` folder in VS Code. Your `CLAUDE.md` (the verification protocol), your merge script, and `output/merged_survey.csv` from Session 2 Part 1 should be there. If your merge did not finish, ask Claude Code to finish it first and run its tests; everything below depends on it.

4. **Specify the base model.** Estimate a logistic regression of `supports_intervention` on `treatment`, using survey weights. Before running, decide:
   - What should the reference category for `treatment` be? Tell Claude Code explicitly.
   - Independent check: the logistic of the model's intercept should equal the weighted share of supporters in the control group. Compute that share directly from the raw CSV, without using the model code, and compare.

5. **Add FX exposure.** Add `fx_status` to the model. Check: did the sample size change?

6. **Add demographic controls.** Add `age`, `female`, `ed_level`, `urban_rural`, `income_quintile`, and `left_right`. **Before running, predict how many observations you will have.** Then check.

7. **Interact treatment with FX exposure.** Does the information treatment have a different effect on people who are directly affected by the shock?

For every model in steps 4–7, reconcile the sample size: rows in, minus rows dropped (by reason), equals N used.

---

## Part 3: Robustness and Output (25 min) — in your `session_2` folder

8. **Generate robustness checks.** From your base model, ask Claude Code for at least four variants:
   - With and without survey weights
   - Different control sets (track how N changes each time)
   - The three treatment arms collapsed into "any information" vs. control
   - A subsample (for example, urban respondents only)

9. **Format as LaTeX.** Produce a publication-style regression table with all specifications side by side, and compile it to PDF. Add an output-manifest test: every specification appears in the table, each with its N.

10. **Audit report.** Ask Claude Code to write `output/audit_report.md`: tests run (passed, failed, skipped), each requirement and the test that covers it, anything not tested, numerical checks (your value against the independent value), choices that need your judgment, and what the tests do not cover.

11. **Commit.** Save the scripts, tests, output, and LaTeX table. (If you have not set up git yet, do it after the git frames: `git init`, then commit.)

---

## Exercise: Results → Paper (25 min) — in `session_3/results_to_paper/`

Open `my_workspace/session_3/results_to_paper` in VS Code (File → New Window → Open Folder). It contains:

| File | What it is |
|------|------------|
| `paper.tex` | Paper skeleton: a Data section, and a Results section with the table but no text |
| `results/regression_results.csv` | Regression results for six specifications, one row per coefficient |
| `scripts/render_regression_table.py` | Turns the CSV into a LaTeX table fragment |

The results are the same for everyone, so you can compare notes. They are not your own Part 3 output.

1. **Set up git before anything else.** In the terminal, `git init`. Ask Claude Code to write a `.gitignore` for LaTeX build files (`*.aux`, `*.log`, `*.out`, `*.fdb_latexmk`, `*.fls`, `*.synctex.gz`) and for `.env` and `__pycache__/`. Then `git add -A && git commit -m "Paper skeleton"`.

2. **Render the table into the paper.** Ask Claude Code to run the render script, then compile `paper.tex`. Open `tables/regression_table.tex` and `results/regression_results.csv` yourself: does the table say what the CSV says? Commit.

3. **Write the results paragraph.** Ask Claude Code to write the paragraph for the Results section from the table. Run `git diff` and read it. Keep it (commit) or revert it (`git checkout -- .`). If you keep it, say what you changed or would change.

4. **Cross-check every number.** In a **fresh conversation**, ask Claude Code to list every number in the results paragraph and the table cell it comes from, and to flag any claim the table does not support. Then answer for yourself: what can this check not catch?

5. **Commit.** `git log --oneline` should show your history.

### Debrief questions

- Which sentences in the paragraph went beyond what the table can support?
- Did the check find anything the diff reading missed, or the reverse?
- What did you revert, and how did git make that cheap?
