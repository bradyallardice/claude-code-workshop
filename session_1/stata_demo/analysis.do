*------------------------------------------------------------------*
* analysis.do  --  county-panel regressions (legacy, inherited)
*
* Demo file for the Session 1 terminal walkthrough. Intentionally
* terse and Stata-idiomatic: the point is to ask Claude Code (from the
* terminal) to explain it and port it to documented Python.
*------------------------------------------------------------------*

clear all
set more off

* --- Load the county-year panel built earlier in the session ---
import delimited "../output/county_panel.csv", clear

* county_fips comes in as a string with a leading zero; keep it as the
* panel id, and set the panel structure for the xt commands below.
encode county_fips, generate(county_id)
xtset county_id year

* --- Outcome and a few demographic predictors ---
* dem_share_2p : Democratic two-party vote share
gen college_pct = share_college * 100
gen senior_pct  = share_age_65_plus * 100
gen wage_k      = median_wage / 1000

* --- Model 1: pooled OLS, robust SEs ---
reg dem_share_2p college_pct senior_pct wage_k, robust

* --- Model 2: add year fixed effects ---
reg dem_share_2p college_pct senior_pct wage_k i.year, robust

* --- Model 3: county + year FE, SEs clustered by county ---
xtreg dem_share_2p college_pct senior_pct wage_k i.year, fe vce(cluster county_id)

* --- Export the final model ---
* (requires the user-written outreg2 package)
outreg2 using "../output/regression_dem_share.txt", replace ctitle(County + Year FE)
