# session_1 — County Election-Demographics Panel

## Session Goal
Build a county-year panel dataset by merging MIT Election Lab presidential returns with IPUMS Census microdata, then run demographic regressions on voting outcomes.

## Data Sources

| File | Description |
|------|-------------|
| `data/election/countypres_sample.csv` | County-level presidential returns (2012–2024). Filter `mode == "TOTAL"` before use. |
| `data/ipums/census_YYYY_sample.csv.gz` | IPUMS Census microdata per election year (gzip-compressed). One row per person with survey weights. |

## Key Columns

**Election data** (after pivoting): `county_fips`, `year`, `state`, `county_name`, `dem_votes`, `rep_votes`, `dem_share`, `rep_share`, `turnout`

**IPUMS data** (raw): `STATEFIP`, `COUNTYFIP`, `PERWT` (survey weight), `AGE`, `EDUC`, `RACE`, `HISPAN`, `INCWAGE`

**Panel output** (`output/county_panel.csv`): all election columns merged with aggregated census columns — `population`, `mean_age`, `share_college`, `share_white`, `share_hispanic`, `mean_wage`

## Exercise Task
`scripts/exercise_build_panel.py` produces correct output but lacks validation, logging, and edge-case handling. Students ask Claude Code to improve it — adding input checks, progress logging, and handling of missing FIPS codes or empty merge results.

## Known Gotchas
- **FIPS codes**: must be zero-padded 5-digit strings (e.g., `"01003"`). Election data uses floats; IPUMS splits into `STATEFIP` + `COUNTYFIP`. Both need conversion before merging.
- **College threshold**: `EDUC >= 10` in IPUMS codes corresponds to "some college or more" — not a standard cutoff, intentional for this exercise.
- **COUNTYFIP == 0**: rows where `COUNTYFIP` is 0 are unidentified counties and must be dropped before aggregation.
- **Compression**: IPUMS files are `.csv.gz`; use `pd.read_csv(..., compression="gzip")`.
- **Weights**: all demographic aggregations must use `PERWT` as the survey weight (via `np.average`).
