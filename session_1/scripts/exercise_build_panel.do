*------------------------------------------------------------------*
* exercise_build_panel.do
* Build a county-year panel of presidential vote shares.
*
* This script works but has no validation, no logging, and no edge
* case handling. Your task: ask Claude Code to improve it.
*
* Note: Stata can't read the gzipped IPUMS files directly, so this
* version builds the election vote-share panel only. The Python and R
* versions also merge in IPUMS demographics.
*------------------------------------------------------------------*

clear all
set more off

* --- Load election data (keep county_fips as a string for leading zeros) ---
import delimited "session_1/data/election/countypres_sample.csv", ///
    varnames(1) stringcols(5) clear

keep if mode == "TOTAL"
drop if missing(county_fips)
keep if inlist(party, "DEMOCRAT", "REPUBLICAN")

* --- One row per county-year-party, then reshape to one row per county-year ---
collapse (sum) candidatevotes (firstnm) totalvotes state county_name, ///
    by(county_fips year party)

reshape wide candidatevotes, ///
    i(county_fips year state county_name totalvotes) j(party) string
rename candidatevotesDEMOCRAT   dem_votes
rename candidatevotesREPUBLICAN rep_votes

* --- Vote shares ---
gen dem_share = dem_votes / (dem_votes + rep_votes)
gen rep_share = rep_votes / (dem_votes + rep_votes)
gen turnout   = totalvotes

order county_fips year state county_name dem_votes rep_votes ///
    dem_share rep_share turnout
save "session_1/output/county_panel_stata.dta", replace

* ==================================================================
*  EXPLORATORY DATA ANALYSIS
* ==================================================================

egen ctag = tag(county_fips)
count if ctag
display "Counties above"
drop ctag

* --- Mean two-party vote share by year ---
tabstat dem_share rep_share, by(year) statistics(mean) format(%6.4f)

* --- Largest year-to-year swings in Democratic vote share ---
encode county_fips, gen(county_id)
xtset county_id year
gen dem_share_lag = L.dem_share
gen swing         = dem_share - dem_share_lag
gen abs_swing     = abs(swing)

gsort -abs_swing
list county_fips county_name state year dem_share_lag dem_share swing ///
    in 1/20, noobs sep(0)
