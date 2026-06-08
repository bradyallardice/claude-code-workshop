*------------------------------------------------------------------*
* exercise_build_panel.do
* Build a county-year panel of presidential vote shares.
*
* PURPOSE
*   Reads raw county-level presidential returns (countypres_sample.csv),
*   keeps the two major parties' TOTAL vote counts, reshapes to one row
*   per county-year, computes total vote shares (each party's votes as a
*   fraction of total turnout), and saves the panel
*   to session_1/output/county_panel_stata.dta. It then runs a short
*   exploratory pass (county count, mean shares by year, largest swings).
*
* INPUT   session_1/data/election/countypres_sample.csv
* OUTPUT  session_1/output/county_panel_stata.dta
*
* DESIGN NOTES
*   - county_fips is read and kept as a STRING so leading zeros survive
*     (e.g. "01001"); as a number it would collapse to 1001.
*   - This version adds validation checks, a run log, and progress
*     messages. Each stage asserts its expectations and prints a short
*     summary, so a silent data problem upstream surfaces immediately
*     instead of producing a quietly-wrong panel.
*   - Stata can't read the gzipped IPUMS files directly, so this version
*     builds the election vote-share panel only. The Python and R
*     versions also merge in IPUMS demographics.
*------------------------------------------------------------------*

clear all
set more off

* --- Start a run log so the full session is captured to disk ---
capture log close
log using "session_1/output/exercise_build_panel.log", replace text

display as text _n "=================================================="
display as text "  BUILD COUNTY-YEAR VOTE-SHARE PANEL"
display as text "=================================================="

* ==================================================================
*  STAGE 1: LOAD ELECTION DATA
* ==================================================================
display as text _n ">>> STAGE 1: Loading election data..."

* Confirm the input file exists before trying to read it.
capture confirm file "session_1/data/election/countypres_sample.csv"
if _rc {
    display as error "ERROR: input CSV not found at session_1/data/election/countypres_sample.csv"
    error 601
}

* Load election data (keep county_fips as a string for leading zeros).
import delimited "session_1/data/election/countypres_sample.csv", ///
    varnames(1) stringcols(5) clear

* Verify the columns we depend on actually arrived.
foreach v in mode county_fips party candidatevotes totalvotes year state county_name {
    capture confirm variable `v'
    if _rc {
        display as error "ERROR: expected variable '`v'' not found in the CSV."
        error 111
    }
}

* Confirm county_fips really is a string (leading-zero preservation).
capture confirm string variable county_fips
if _rc {
    display as error "ERROR: county_fips imported as numeric; leading zeros are lost."
    error 109
}

quietly count
display as text "    Rows read from CSV: " as result r(N)
assert r(N) > 0

* ==================================================================
*  STAGE 2: FILTER TO TOTAL VOTES, MAJOR PARTIES
* ==================================================================
display as text _n ">>> STAGE 2: Filtering rows..."

local n_start = _N

keep if mode == "TOTAL"
display as text "    Dropped " as result `n_start' - _N as text " non-TOTAL rows."

local n_pre_fips = _N
drop if missing(county_fips)
display as text "    Dropped " as result `n_pre_fips' - _N as text " rows with missing county_fips."

keep if inlist(party, "DEMOCRAT", "REPUBLICAN")
quietly count
display as text "    Rows remaining (DEM/REP TOTAL only): " as result r(N)
assert r(N) > 0

* After filtering we should see exactly the two parties we kept.
quietly levelsof party, local(parties)
display as text "    Parties present: `parties'"

* ==================================================================
*  STAGE 3: COLLAPSE AND RESHAPE TO ONE ROW PER COUNTY-YEAR
* ==================================================================
display as text _n ">>> STAGE 3: Collapsing and reshaping..."

* One row per county-year-party (sum votes; carry constant fields through).
collapse (sum) candidatevotes (firstnm) totalvotes state county_name, ///
    by(county_fips year party)

* A county-year-party combination should now be unique. Assert it.
quietly duplicates report county_fips year party
assert r(unique_value) == r(N)
display as text "    county_fips x year x party is unique (" as result r(N) as text " rows)."

* Reshape so each party becomes its own column.
reshape wide candidatevotes, ///
    i(county_fips year state county_name totalvotes) j(party) string
rename candidatevotesDEMOCRAT   dem_votes
rename candidatevotesREPUBLICAN rep_votes

* After the reshape there should be exactly one row per county-year.
quietly duplicates report county_fips year
assert r(unique_value) == r(N)
display as text "    Reshaped to one row per county-year: " as result _N as text " rows."

* ==================================================================
*  STAGE 4: COMPUTE TWO-PARTY VOTE SHARES
* ==================================================================
display as text _n ">>> STAGE 4: Computing vote shares..."

* A county-year is only usable if at least one major party has votes.
* Flag and drop county-years where both are missing/zero (share undefined).
gen byte _both_missing = missing(dem_votes) & missing(rep_votes)
quietly count if _both_missing
if r(N) > 0 {
    display as text "    Dropping " as result r(N) as text " county-years with no DEM or REP votes."
    drop if _both_missing
}
drop _both_missing

* Treat a missing party total as zero votes for the share denominator.
replace dem_votes = 0 if missing(dem_votes)
replace rep_votes = 0 if missing(rep_votes)

gen turnout = totalvotes

* Total vote shares: each party's votes as a fraction of ALL votes cast
* (the denominator is total turnout, not just the two-party total). Because
* third parties and write-ins are in the denominator, dem_share + rep_share
* need not equal 1.
gen dem_share = dem_votes / turnout
gen rep_share = rep_votes / turnout

* Verify the shares are well-behaved: in [0,1] and their sum does not
* exceed 1 (the remainder is third-party / other / write-in votes).
assert dem_share >= 0 & dem_share <= 1 if !missing(dem_share)
assert rep_share >= 0 & rep_share <= 1 if !missing(rep_share)
assert dem_share + rep_share <= 1 + 1e-6 if !missing(dem_share, rep_share)
display as text "    Total vote shares in [0,1] and dem_share + rep_share <= 1 (verified)."

* Turnout should be at least the two-party vote count.
assert turnout >= dem_votes + rep_votes if !missing(turnout)
display as text "    Turnout >= two-party votes (verified)."

order county_fips year state county_name dem_votes rep_votes ///
    dem_share rep_share turnout

* ==================================================================
*  STAGE 5: SAVE PANEL
* ==================================================================
display as text _n ">>> STAGE 5: Saving panel..."

save "session_1/output/county_panel_stata.dta", replace
display as text "    Saved " as result _N as text " county-year rows to " ///
    as result "session_1/output/county_panel_stata.dta"

* ==================================================================
*  EXPLORATORY DATA ANALYSIS
* ==================================================================
display as text _n ">>> EXPLORATORY DATA ANALYSIS"

* --- Number of distinct counties ---
egen ctag = tag(county_fips)
quietly count if ctag
display as text "    Distinct counties: " as result r(N)
drop ctag

* --- Year coverage ---
quietly levelsof year, local(years)
display as text "    Years in panel: `years'"

* --- Mean total vote share by year ---
display as text _n "    Mean total vote share by year:"
tabstat dem_share rep_share, by(year) statistics(mean) format(%6.4f)

* --- Largest year-to-year swings in Democratic vote share ---
display as text _n "    Largest year-to-year swings in Democratic vote share:"
encode county_fips, gen(county_id)
xtset county_id year

* NOTE: presidential elections are every 4 years. L.dem_share is the
* PREVIOUS YEAR PRESENT for the county; for a complete county this is the
* prior election, but a county missing an election year would compare
* across an uneven gap. We flag those rather than silently lagging.
gen year_gap      = year - L.year
gen dem_share_lag = L.dem_share
gen swing         = dem_share - dem_share_lag
gen abs_swing     = abs(swing)

quietly count if !missing(swing) & year_gap != 4
if r(N) > 0 {
    display as text "    WARNING: " as result r(N) as text ///
        " swings span a non-4-year gap (missing election years)."
}

gsort -abs_swing
list county_fips county_name state year year_gap dem_share_lag dem_share swing ///
    in 1/20, noobs sep(0)

display as text _n "=================================================="
display as text "  DONE."
display as text "=================================================="

log close
