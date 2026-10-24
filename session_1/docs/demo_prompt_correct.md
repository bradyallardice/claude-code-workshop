I have county-level presidential election data and IPUMS census microdata in `session_1/data/`. The election data is in `session_1/data/election/countypres_sample.csv` and the IPUMS files are in `session_1/data/ipums/` as `census_{year}_sample.csv.gz` for years 2012, 2016, 2020, and 2024.

Build a balanced county-year panel that merges election results with demographics. Specifically:

1. Load the election data, keep only mode == "TOTAL" rows, clean county FIPS codes, and compute two-party Democratic and Republican vote shares for each county-year.

2. For each IPUMS year, aggregate person-level records to county-level demographics using person weights (PERWT). Include: population, mean age, share with a college degree (EDUC >= 10), share white (RACE == 1), share Hispanic (HISPAN in [1,2,3,4], excluding 9 = Not Reported from both numerator and denominator), and mean wage among wage earners only (INCWAGE > 0 and < 999998; 999999 = N/A, 999998 = missing).

3. Merge election and census data on county FIPS and year. The datasets have different county coverage per year — not every county appears in every IPUMS file. After the inner merge, filter the panel to only counties that appear in all 4 years (balanced panel). Save the result to `session_1/output/county_panel.csv`.

4. Print a summary: panel shape, number of counties, years covered, mean vote shares by year, and how many counties were dropped during balancing.

5. Compute and print the 20 largest year-to-year swings in Democratic vote share (sorted by absolute value), and the 20 largest changes from the 2012 baseline (the county's biggest absolute shift in any later year).

6. Save two plots to `session_1/output/`:
   - Mean Democratic and Republican vote share over time
   - Mean demographic variables over time (one subplot per variable)

7. Using the balanced panel, regress the Democratic two-party vote share on county demographics. Outcome: `dem_2p_share`. Regressors of interest: `white_share` and `hispanic_share`. Controls: `college_share`, `mean_wage` (in thousands of dollars), and `mean_age`. Estimate four specifications, all with standard errors clustered by county: (1) pooled OLS, regressors of interest only; (2) pooled OLS with controls; (3) county fixed effects with controls; (4) county and year fixed effects with controls. Print a side-by-side table (coefficients, clustered SEs, N, R-squared, FE indicators) and save it to `session_1/output/regression_results.txt`.

8. Write a short LaTeX document at `session_1/output/results.tex` with three sections: Data (sources, sample, how the panel was built, number of counties and years), Method (the four specifications and the clustering choice), and Results (the regression table and a brief, plain-language reading that does not claim more than the design supports). Compile it to PDF with `pdflatex` and report any compilation errors.
