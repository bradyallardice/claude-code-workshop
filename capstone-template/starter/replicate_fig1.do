* replicate_fig1.do
* Goal: reproduce Figure 1 of Magistro et al. 2026
* (marginal means by treatment condition: AI vs. Offshoring)
*
* Run from the repo root: stata -b do starter/replicate_fig1.do
* Or interactively: open in Stata, run line by line

* ── Load data ──────────────────────────────────────────────────────────────
import delimited "data/clean_AJPS.csv", clear varnames(1) case(lower)

* ── TODO: reshape conjoint data ────────────────────────────────────────────
* The data is wide: each task iteration is a separate column
* (e.g., price_after_1 ... price_after_4, qtable_1 ... qtable_4).
* You need to reshape to long format so each row is one (respondent, task).
*
* Rename columns to Stata-friendly names first, then use reshape long.
* Keep: id countr treat_offshoring party party2
* Attributes: priceafter csafter factoryafter dsafter
* Outcome: qtable

* your reshape code here

* ── TODO: estimate marginal means by treatment ─────────────────────────────
* For each attribute level, regress qtable on level dummies interacted with
* treat_offshoring, clustering SEs by id.
* margins can recover the marginal means.
*
* Or: compute group means directly with collapse/tabstat.

* your estimation code here

* ── TODO: plot ─────────────────────────────────────────────────────────────
* Reproduce Figure 1: horizontal coefficient plot by attribute and treatment.
* coefplot or twoway rspike + scatter are both workable.

* your plotting code here

* ── Save ───────────────────────────────────────────────────────────────────
* Uncomment when ready:
* graph export "paper/figures/figure1_replication.png", replace width(1950)
