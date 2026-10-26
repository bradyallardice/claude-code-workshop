*------------------------------------------------------------------*
* exercise_build_panel.do
* Exercise: Build a county-year panel of presidential vote shares.
*
* This script works but has no validation, no logging, and no edge case
* handling. Your task: ask Claude Code to improve it.
*
* Run it from the folder that CONTAINS session_1/ (your my_workspace folder),
* so that the relative paths below resolve.
*
* Stata cannot read the gzipped IPUMS files directly, so this version builds
* the election vote-share panel only. The Python and R versions also merge
* in IPUMS demographics.
*
* INPUT   session_1/data/election/countypres_sample.csv
* OUTPUT  session_1/output/county_panel_stata.dta
*------------------------------------------------------------------*

clear all
set more off

capture mkdir "session_1/output"

* --- Load election data (county_fips stays a string to keep leading zeros) ---
import delimited "session_1/data/election/countypres_sample.csv", ///
    varnames(1) stringcols(5) clear

keep if mode == "TOTAL"
drop if missing(county_fips)
keep if inlist(party, "DEMOCRAT", "REPUBLICAN")

* --- One row per county-year, one column per party ---
collapse (sum) candidatevotes (firstnm) totalvotes state county_name, ///
    by(county_fips year party)

reshape wide candidatevotes, ///
    i(county_fips year state county_name totalvotes) j(party) string
rename candidatevotesDEMOCRAT   dem_votes
rename candidatevotesREPUBLICAN rep_votes

gen dem_share = dem_votes / (dem_votes + rep_votes)
gen rep_share = rep_votes / (dem_votes + rep_votes)
gen turnout   = totalvotes

order county_fips year state county_name dem_votes rep_votes ///
    dem_share rep_share turnout

save "session_1/output/county_panel_stata.dta", replace

* ==================================================================
*  EXPLORATORY DATA ANALYSIS
* ==================================================================

display "PANEL SUMMARY"
count
egen county_tag = tag(county_fips)
count if county_tag
drop county_tag

display "Mean two-party vote share by year:"
tabstat dem_share rep_share, by(year) statistics(mean) format(%6.4f)

* --- Year-to-year swings in Democratic vote share ---
display "Largest year-to-year swings in Democratic vote share:"
sort county_fips year
by county_fips: gen dem_share_lag = dem_share[_n-1]
gen swing     = dem_share - dem_share_lag
gen abs_swing = abs(swing)

drop if missing(abs_swing)
gsort -abs_swing
list county_fips county_name state year dem_share_lag dem_share swing ///
    in 1/20, noobs sep(0)

display "Done."
