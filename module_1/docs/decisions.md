# Analytical Decisions: build_county_panel.py

Every decision below could have reasonably gone a different way. This document records what we chose and why.

---

## Election Data

### 1. Filter to mode == "TOTAL" only
- **Decision:** Drop all rows where `mode` is not `"TOTAL"` (e.g., absentee, provisional breakdowns in 2020).
- **Why:** The 2020 data reports some counties with separate rows per voting mode. Keeping them would double-count votes. `TOTAL` gives a single aggregate per county-year.
- **Alternative:** Could have summed across modes, but `TOTAL` already does this and avoids the risk of partial mode reporting.

### 2. Drop rows with missing county_fips
- **Decision:** Drop any row where `county_fips` is NaN.
- **Why:** We cannot merge these rows to census data without a FIPS code. They are unidentifiable.
- **Alternative:** Could have attempted to recover FIPS from `state` + `county_name`, but name-matching is error-prone and these are a small share of observations.

### 3. Two-party vote share as the primary measure
- **Decision:** Compute `dem_share_2p` = dem_votes / (dem_votes + rep_votes), excluding third-party votes from the denominator.
- **Why:** Two-party share is standard in the political science literature. It is more comparable across elections because third-party candidacies vary in strength year to year (e.g., strong Libertarian showing in 2016).
- **Alternative:** Total vote share (dem_votes / totalvotes) is also computed and kept in the panel as `dem_share_total` for robustness.

### 4. Third-party candidates grouped into a single residual
- **Decision:** All non-Democrat, non-Republican candidates are captured in `third_party_share` = 1 - dem_share_total - rep_share_total.
- **Why:** Third parties vary across years (Libertarian, Green, independent candidates). Tracking each individually would create sparse columns that are mostly zero. A single residual captures the share of votes going to non-major-party candidates.
- **Alternative:** Could have kept Libertarian and Green as separate columns. Would matter if studying third-party voting specifically, but not for our use case.

### 5. Fill missing party votes with zero
- **Decision:** If a county reports votes for one major party but not the other (e.g., Democrat but no Republican row), fill the missing party's votes with 0.
- **Why:** Some very small counties or unusual jurisdictions may only report one party. Treating them as zero rather than NaN keeps them in the panel. The script logs a warning when this happens.
- **Alternative:** Could have dropped these counties entirely. Filling with zero assumes the party received no votes, which may not be true if data is simply unreported.

---

## Census / IPUMS Data

### 6. Drop observations with COUNTYFIP == 0
- **Decision:** Exclude all IPUMS person-records where `COUNTYFIP == 0` (county not identified).
- **Why:** These individuals cannot be assigned to a county. Including them would bias county-level aggregates if they are systematically different from identified individuals.
- **Alternative:** None reasonable—without a county identifier, these records cannot contribute to a county-level panel.

### 7. Wage calculations restricted to wage earners (INCWAGE > 0 and < 999998)
- **Decision:** Exclude individuals with INCWAGE == 0 (no wage income), 999998 (missing), or 999999 (N/A / not in universe) from mean and median wage calculations.
- **Why:** We want the wage distribution among people who work for wages, not the full population (which includes children, retirees, self-employed). Including zeros would conflate "not a wage earner" with "earns low wages."
- **Alternative:** Could have included INCWAGE == 0 to capture a broader labor market picture. Would substantially lower means and medians and change interpretation.

### 8. Hispanic share excludes HISPAN == 9 (Not Reported)
- **Decision:** Remove individuals with `HISPAN == 9` from both the numerator and denominator when computing `share_hispanic`.
- **Why:** "Not Reported" is not the same as "Not Hispanic." Including them in the denominator would deflate Hispanic shares in counties with high non-response.
- **Alternative:** Could have treated HISPAN == 9 as non-Hispanic (common but biased) or dropped the entire observation from all calculations (loses data unnecessarily for other variables).

### 9. Education coding: college = EDUC >= 10
- **Decision:** Define "college-educated" as bachelor's degree or higher (EDUC codes 10 and 11).
- **Why:** This is the standard definition used in most applied work on education and voting. EDUC == 10 is a four-year degree; EDUC == 11 is five or more years (graduate school).
- **Alternative:** Could have used "some college" (EDUC >= 7) as the threshold. This is a meaningful alternative that would substantially increase the college share and change the interpretation.

### 10. All demographic aggregations are person-weighted (PERWT)
- **Decision:** Every county-level statistic (means, shares, medians) uses IPUMS person weights.
- **Why:** IPUMS samples are not simple random samples. Person weights account for sampling design and ensure aggregates are representative of the county population.
- **Alternative:** Unweighted aggregates would be simpler but would misrepresent counties where certain groups are over- or under-sampled.

---

## Merge and Panel Construction

### 11. Inner join on county_fips × year
- **Decision:** Merge election and census data using an inner join—only county-years present in both datasets are kept.
- **Why:** We need both election outcomes and demographic covariates for analysis. Counties in only one dataset cannot be used.
- **Alternative:** A left join (keeping all election counties) would preserve more election data but leave demographics as NaN. An outer join would keep everything but create many incomplete rows.

### 12. Balance the panel: keep only counties present in all four election years
- **Decision:** After merging, drop any county that does not appear in all four years (2012, 2016, 2020, 2024).
- **Why:** A balanced panel simplifies analysis (fixed effects, lag construction) and avoids confounding composition changes with substantive changes. If county X enters in 2020, its appearance would change the cross-sectional mean even if no county changed.
- **Alternative:** Could have kept the unbalanced panel and handled missing years in the analysis. This preserves more data but requires more careful econometric treatment.

### 13. 2012 as the baseline year for change calculations
- **Decision:** Compute `change_from_2012` as the difference in Democratic two-party share relative to 2012.
- **Why:** 2012 is the first year in our panel, making it the natural baseline. It also predates the major realignment visible in 2016+, so changes from 2012 capture the full shift.
- **Alternative:** Could have used 2016 or computed all pairwise changes. The choice of baseline affects the magnitude and sign of change measures but not rank ordering.

---

## Output and Validation

### 14. Validate merge by reporting match rates per year
- **Decision:** After merging, report how many counties matched, how many are only in election data, and how many are only in census data, separately for each year.
- **Why:** Silent data loss is the most common source of errors in panel construction. Reporting match rates makes any problems visible immediately.

### 15. Assert no duplicate county-year observations
- **Decision:** After merging and balancing, assert that each county-year combination appears exactly once. Script halts if this fails.
- **Why:** Duplicates would mean the merge created a many-to-many join, which would invalidate all downstream analysis. This is a fatal error, not a warning.
