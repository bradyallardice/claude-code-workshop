* Build a county-level panel joining presidential vote shares with IPUMS demographics.
*
* Reads:
*   - session_1/data/election/countypres_sample.csv (MIT Election Data + Science Lab)
*   - session_1/data/IPUMS/census_{year}_sample.csv.gz (IPUMS USA microdata)
*
* Outputs:
*   - session_1/output/county_panel.csv
*   - session_1/output/vote_share_2p_over_time.png
*   - session_1/output/vote_share_total_over_time.png
*   - session_1/output/demographics_over_time.png
*
* Variable coding (from IPUMS codebooks):
*   EDUC: 0=N/A or no schooling ... 10=4yr college (bachelor's), 11=5+ years (graduate)
*   INCWAGE: 0=no wage income, 999998=missing, 999999=N/A
*   RACE: 1=White, 2=Black/African American, ... 9=Three+ major races
*   HISPAN: 0=Not Hispanic, 1=Mexican, 2=Puerto Rican, 3=Cuban, 4=Other, 9=Not Reported
*
* Run from the project root (AIAgentsCourse/):
*   do session_2/scripts/build_county_panel.do
*
* NOTE: Stata cannot read .gz directly. We decompress each IPUMS file to a
* tempfile with `gunzip -c` (available on macOS/Linux) before importing.

clear all
set more off

capture mkdir "session_1/output"

* ====================================================================
*  1. ELECTION DATA -> county-year vote shares
* ====================================================================
display "Loading presidential election data..."
import delimited "session_1/data/election/countypres_sample.csv", clear case(preserve)

* Keep only TOTAL mode rows (excludes absentee/provisional breakdowns in 2020)
keep if mode == "TOTAL"

* Drop rows with missing FIPS
drop if missing(county_fips)

* Build clean 5-digit FIPS
gen str5 cfips = string(county_fips, "%05.0f")

* Keep major parties and pivot to dem/rep votes per county-year
keep if inlist(party, "DEMOCRAT", "REPUBLICAN")
gen double dem_votes = candidatevotes if party == "DEMOCRAT"
gen double rep_votes = candidatevotes if party == "REPUBLICAN"
collapse (sum) dem_votes rep_votes (firstnm) totalvotes state county_name, by(cfips year)

* Two-party vote share
gen double dem_share_2p = dem_votes / (dem_votes + rep_votes)
gen double rep_share_2p = rep_votes / (dem_votes + rep_votes)

* Total vote share (fraction of all votes cast, including third parties)
gen double turnout = totalvotes
gen double dem_share_total = dem_votes / turnout
gen double rep_share_total = rep_votes / turnout
gen double third_party_share = 1 - dem_share_total - rep_share_total

quietly count
display "  " r(N) " county-year observations"
quietly summarize third_party_share
display "  Mean third-party share: " %6.4f r(mean)

keep cfips year state county_name dem_votes rep_votes turnout ///
     dem_share_2p rep_share_2p dem_share_total rep_share_total third_party_share
tempfile election
save "`election'"

* ====================================================================
*  2. IPUMS DATA -> county-level demographics, per year
* ====================================================================
display _newline "Loading and aggregating IPUMS data by county..."
local years 2012 2016 2020 2024
local firstyear 1
tempfile census

foreach yr of local years {
    display _newline "Year `yr':"
    local gz "session_1/data/IPUMS/census_`yr'_sample.csv.gz"
    capture confirm file "`gz'"
    if _rc {
        display "  WARNING: `gz' not found, skipping year `yr'"
        continue
    }

    * Decompress to a tempfile, then import
    tempfile csvtmp
    shell gunzip -c "`gz'" > "`csvtmp'"
    import delimited "`csvtmp'", clear case(preserve)

    * Drop unidentified counties (COUNTYFIP == 0)
    drop if COUNTYFIP == 0
    gen str5 cfips = string(STATEFIP, "%02.0f") + string(COUNTYFIP, "%03.0f")
    tempfile raw
    save "`raw'"

    * --- (a) Population: raw sum of person weights ---
    collapse (sum) population = PERWT, by(cfips)
    tempfile agg
    save "`agg'"

    * --- (b) Weighted shares / means over full population ---
    use "`raw'", clear
    gen byte age1834 = AGE >= 18 & AGE <= 34
    gen byte age65   = AGE >= 65
    gen byte college = EDUC >= 10
    gen byte nohs    = EDUC <= 5
    gen byte white   = RACE == 1
    gen byte black   = RACE == 2
    collapse (mean) mean_age = AGE share_age_18_34 = age1834 ///
        share_age_65_plus = age65 share_college = college share_no_hs = nohs ///
        share_white = white share_black = black [aweight=PERWT], by(cfips)
    merge 1:1 cfips using "`agg'", nogen
    save "`agg'", replace

    * --- (c) Income among wage earners (INCWAGE > 0 and < 999998) ---
    use "`raw'", clear
    keep if INCWAGE > 0 & INCWAGE < 999998
    collapse (median) median_wage = INCWAGE (mean) mean_wage = INCWAGE [aweight=PERWT], by(cfips)
    merge 1:1 cfips using "`agg'", nogen
    save "`agg'", replace

    * --- (d) Hispanic origin (exclude HISPAN == 9, Not Reported) ---
    use "`raw'", clear
    keep if HISPAN != 9
    gen byte hisp = inlist(HISPAN, 1, 2, 3, 4)
    collapse (mean) share_hispanic = hisp [aweight=PERWT], by(cfips)
    merge 1:1 cfips using "`agg'", nogen
    save "`agg'", replace

    use "`agg'", clear
    gen int year = `yr'
    quietly count
    display "  -> " r(N) " counties with identified FIPS"

    if `firstyear' {
        save "`census'"
        local firstyear 0
    }
    else {
        append using "`census'"
        save "`census'", replace
    }
}

* ====================================================================
*  3. MERGE + BALANCE
* ====================================================================
display _newline "--- Merging datasets ---"
use "`census'", clear
merge 1:1 cfips year using "`election'"
keep if _merge == 3
drop _merge
quietly count
display "Merged panel (before balancing): " r(N) " county-year observations"

* Balance: keep only counties present in all 4 years
display _newline "--- Balancing panel ---"
bysort cfips year: gen byte _firstcy = _n == 1
bysort cfips: egen byte _nyears = total(_firstcy)
keep if _nyears == 4
drop _firstcy _nyears
quietly count
display "  Balanced panel: " r(N) " county-year observations"

* ====================================================================
*  4. FINAL VALIDATION
* ====================================================================
display _newline "--- Final panel validation ---"
quietly duplicates report cfips year
assert r(unique_value) == r(N)
display "  No duplicate county-year observations (1:1 confirmed)"

assert inrange(dem_share_2p, 0, 1) & inrange(rep_share_2p, 0, 1)
assert round(dem_share_2p + rep_share_2p, 1e-10) == 1
display "  Two-party shares valid (sum to 1)"

assert round(dem_share_total + rep_share_total + third_party_share, 1e-10) == 1
assert inrange(third_party_share, 0, 1)
display "  Total shares valid (dem + rep + third party sum to 1)"

assert population > 0
display "  Population: all positive"

* ====================================================================
*  5. SAVE PANEL
* ====================================================================
order cfips year state county_name
export delimited using "session_1/output/county_panel.csv", replace
display _newline "Panel saved to session_1/output/county_panel.csv"
quietly count
display "Rows: " r(N)

* ====================================================================
*  6. EXPLORATORY DATA ANALYSIS
* ====================================================================
display _newline "{hline 60}"
display "EXPLORATORY DATA ANALYSIS"
display "{hline 60}"

display _newline "Mean two-party vote share by year:"
table year, statistic(mean dem_share_2p rep_share_2p)

display _newline "Mean total vote share by year:"
table year, statistic(mean dem_share_total rep_share_total third_party_share)

* Year-to-year swings (two-party). encode cfips for tsset.
encode cfips, gen(cfips_n)
tsset cfips_n year, delta(4)
gen double swing_2p = dem_share_2p - L.dem_share_2p
gen double swing_total = dem_share_total - L.dem_share_total

display _newline "Largest year-to-year swings in Democratic two-party vote share:"
gsort -=abs(swing_2p)
list cfips county_name state year dem_share_2p swing_2p if !missing(swing_2p) in 1/20, ///
    noobs sep(0)

display _newline "Largest year-to-year swings in Democratic total vote share:"
gsort -=abs(swing_total)
list cfips county_name state year dem_share_total swing_total if !missing(swing_total) in 1/20, ///
    noobs sep(0)

* Largest change from 2012
preserve
    gen double dem_2p_2012 = dem_share_2p if year == 2012
    bysort cfips_n (year): replace dem_2p_2012 = dem_2p_2012[1]
    gen double change_from_2012 = dem_share_2p - dem_2p_2012
    drop if year == 2012
    bysort cfips_n (year): egen double _maxabs = max(abs(change_from_2012))
    keep if abs(change_from_2012) == _maxabs
    gsort -_maxabs
    display _newline "Largest change from 2012 Democratic two-party vote share (any year):"
    list cfips county_name state year dem_2p_2012 dem_share_2p change_from_2012 in 1/20, ///
        noobs sep(0)
restore

* ====================================================================
*  7. GRAPHICS
* ====================================================================
preserve
    collapse (mean) dem_share_2p rep_share_2p dem_share_total rep_share_total third_party_share, by(year)

    * Plot 1: two-party vote share over time
    twoway (connected dem_share_2p year, lcolor(navy) mcolor(navy)) ///
           (connected rep_share_2p year, lcolor(cranberry) mcolor(cranberry)), ///
        ylabel(0.3(0.1)0.7) ytitle("Vote Share") xtitle("Year") ///
        title("Mean Two-Party Vote Share Over Time") ///
        legend(order(1 "Democratic" 2 "Republican")) graphregion(color(white))
    graph export "session_1/output/vote_share_2p_over_time.png", replace width(1200)
    display _newline "Saved: vote_share_2p_over_time.png"

    * Plot 2: total vote share over time (including third parties)
    twoway (connected dem_share_total year, lcolor(navy) mcolor(navy)) ///
           (connected rep_share_total year, lcolor(cranberry) mcolor(cranberry)) ///
           (connected third_party_share year, lcolor(gray) mcolor(gray) lpattern(dash) msymbol(square)), ///
        ylabel(0(0.1)0.7) ytitle("Vote Share") xtitle("Year") ///
        title("Mean Total Vote Share Over Time (Including Third Parties)") ///
        legend(order(1 "Democratic" 2 "Republican" 3 "Third Party")) graphregion(color(white))
    graph export "session_1/output/vote_share_total_over_time.png", replace width(1200)
    display "Saved: vote_share_total_over_time.png"
restore

* Plot 3: mean demographic variables over time (2x3 grid)
preserve
    collapse (mean) mean_age share_college share_white share_hispanic mean_wage, by(year)
    local i = 0
    foreach v in mean_age share_college share_white share_hispanic mean_wage {
        local ++i
        twoway connected `v' year, lcolor(steelblue) mcolor(steelblue) ///
            title("`v'") xtitle("Year") ytitle("") graphregion(color(white)) name(g`i', replace)
    }
    graph combine g1 g2 g3 g4 g5, cols(3) ///
        title("Mean Demographic Variables Over Time (County-Level)") graphregion(color(white))
    graph export "session_1/output/demographics_over_time.png", replace width(1800)
    display "Saved: demographics_over_time.png"
restore

display _newline "Done!"
