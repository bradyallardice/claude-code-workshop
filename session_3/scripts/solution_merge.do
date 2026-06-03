* Session 2 Solution -- Part 1: Merge and Explore
* Merges the survey data with the demographics file using a left join.
*
* Run from the project root (AIAgentsCourse/):
*   do session_3/scripts/solution_merge.do

clear all
set more off

* -- Load demographics (the "using" side) and stash as a tempfile -----
import delimited "session_3/data/respondent_demographics.csv", clear case(preserve)
quietly count
display "Demographics shape: " r(N) " rows"
quietly duplicates report respondent_id
tempfile demog
save "`demog'"

* -- Load survey (the master) ----------------------------------------
import delimited "session_3/data/swiss_franc_survey.csv", clear case(preserve)
quietly count
display "Survey shape: " r(N) " rows"

* -- Merge: left join on respondent_id -------------------------------
* _merge==1 master only (no demog match), ==3 matched. A left join keeps
* all master rows, so we drop rows that are using-only (_merge==2).
merge 1:1 respondent_id using "`demog'"
drop if _merge == 2
drop _merge

* -- Verify the merge ------------------------------------------------
display _newline "=== MERGE VERIFICATION ==="
quietly count
display "Merged rows: " r(N)
assert r(N) == 2044
display "Row count: 2,044 (no rows lost or gained)"

quietly duplicates report respondent_id
assert r(unique_value) == 2044
display "No duplicate respondent IDs"

* -- Explore the data ------------------------------------------------
display _newline "=== TREATMENT GROUPS ==="
tabulate treatment, missing

display _newline "=== OUTCOME DISTRIBUTION ==="
tabulate supports_intervention, missing
quietly summarize supports_intervention
display "Unweighted proportion supporting: " %6.4f r(mean)

quietly summarize supports_intervention [aweight=survey_weight]
display "Weighted proportion supporting: " %6.4f r(mean)

display _newline "=== FX EXPOSURE ==="
tabulate fx_status, missing

display _newline "=== MISSING DATA ==="
foreach v of varlist _all {
    quietly count if missing(`v')
    if r(N) > 0 {
        display "  `v': " r(N) " missing"
    }
}

display _newline "=== INCOME QUINTILE = 0 ==="
quietly count if income_quintile == 0
display "Respondents with income_quintile = 0: " r(N)

* -- Save ------------------------------------------------------------
export delimited using "session_3/output/merged_survey.csv", replace
display _newline "Saved merged data to session_3/output/merged_survey.csv"
