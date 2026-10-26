* Session 2 Solution — Part 1: Merge and Explore (Stata version)
* Merges the survey data with the demographics file using a left join.

clear all
set more off

* ── Load survey data ─────────────────────────────────────────────
import delimited "option_b/data/swiss_franc_survey.csv", clear varnames(1)
di "Survey observations: " _N
tempfile survey_tmp
save `survey_tmp'

* ── Load demographics data ───────────────────────────────────────
import delimited "option_b/data/respondent_demographics.csv", clear varnames(1)
di "Demographics observations: " _N
tempfile demog_tmp
save `demog_tmp'

* ── Merge: left join on respondent_id ────────────────────────────
use `survey_tmp', clear
merge 1:1 respondent_id using `demog_tmp', keep(master match) nogen

* ── Verify the merge ─────────────────────────────────────────────
di _n "=== MERGE VERIFICATION ==="
di "Merged observations: " _N
assert _N == 2044
di "Row count: 2,044 (no rows lost or gained)"

isid respondent_id
di "No duplicate respondent IDs"

* ── Explore the data ─────────────────────────────────────────────
di _n "=== TREATMENT GROUPS ==="
tab treatment, missing

di _n "=== OUTCOME DISTRIBUTION ==="
tab supports_intervention, missing
summarize supports_intervention

* Weighted proportion
summarize supports_intervention [aw=survey_weight]
di "Weighted proportion supporting: " r(mean)

di _n "=== FX EXPOSURE ==="
tab fx_status, missing

di _n "=== MISSING DATA ==="
misstable summarize

di _n "=== INCOME QUINTILE = 0 ==="
count if income_quintile == 0
di "Respondents with income_quintile = 0: " r(N)

* ── Save ─────────────────────────────────────────────────────────
export delimited using "option_b/output/merged_survey.csv", replace
di _n "Saved merged data to option_b/output/merged_survey.csv"
