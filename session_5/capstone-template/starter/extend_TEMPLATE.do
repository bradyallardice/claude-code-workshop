* extend_TEMPLATE.do
* Extension analysis for Magistro et al. 2026 replication
*
* Set EXTENSION to "A", "B", or "C" and fill in the relevant section.
* Run from the repo root: stata -b do starter/extend_TEMPLATE.do

local EXTENSION "A"   // change to "A", "B", or "C"

* ── Load and reshape data ──────────────────────────────────────────────────
* Copy your working reshape code from replicate_fig1.do here.

import delimited "data/clean_AJPS.csv", clear varnames(1) case(lower)

* multi2_reshape: long format, one row per (id, task)
* your reshape code here

* ── Extension A: Framing × job type interaction ────────────────────────────
* Does the AI vs. offshoring frame shift preferences differently for
* data science jobs vs. factory jobs?
*
* Approach:
*   1. Regress qtable on job-type dummies × treat_offshoring interactions,
*      clustered by id.
*   2. Use margins to recover conditional marginal means.
*   3. Plot: coefplot or twoway with two panels (ds jobs vs. factory jobs).

if "`EXTENSION'" == "A" {
    * TODO: your Extension A code here
}

* ── Extension B: Robustness battery ────────────────────────────────────────
* Specification grid:
*   attention_filter: all vs. pass_only (manipulation_check2 == "Pass")
*   weights:          unweighted vs. weighted
*   estimator:        OLS (regress) vs. ordered logit (ologit)
*   task_fe:          no FE vs. iteration FEs
*
* Loop over combinations, store estimates, produce a results table.

if "`EXTENSION'" == "B" {
    * TODO: your Extension B code here
}

* ── Extension C: Prior trade attitudes as moderator ────────────────────────
* Variable: tables_policygr_5 (1–5, higher = more pro-trade)
* Median split → trade_hi / trade_lo
* Estimate framing effect within each group; test moderation interaction.

if "`EXTENSION'" == "C" {
    * TODO: your Extension C code here
}

* ── Save outputs ───────────────────────────────────────────────────────────
* graph export "paper/figures/extension_result.png", replace width(2400)
* export delimited using "paper/tables/robustness.csv", replace
