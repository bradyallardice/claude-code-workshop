# CLAUDE.md — County Panel

## Project

Build a county-year panel for the presidential elections of 2012, 2016, 2020 and
2024 that joins county election returns with county demographics computed from
IPUMS census microdata. One row per county per year.

## Where things are

All paths are relative to this folder (`county_panel/`). Run everything from here.

| Path | Contents |
|---|---|
| `data/election/countypres_sample.csv` | County presidential returns (MIT Election Data + Science Lab), sample of counties |
| `data/election/County Presidential Returns 2000-2024.md` | Codebook for the election file |
| `data/ipums/census_YYYY_sample.csv.gz` | IPUMS USA person-level microdata, four files (2012, 2016, 2020, 2024). The name is not always the survey year: see "Know your files" |
| `data/ipums/codebooks/census_YYYY_raw.xml` | IPUMS codebook for each file (XML) |
| `scripts/` | Scripts go here (create the folder if it does not exist) |
| `output/` | The panel and any figures go here (create the folder if it does not exist) |

## Know your files

- **Survey years in the IPUMS files.** `census_2012_sample.csv.gz` and
  `census_2020_sample.csv.gz` each contain one survey year. `census_2016_sample.csv.gz`
  contains survey years 2014, 2015 and 2016, and `census_2024_sample.csv.gz` contains
  2021, 2022, 2023 and 2024. The `YEAR` column says which year each row is from.
- **The `mode` column in the election file.** In 2012 and 2016 every row has `mode`
  "TOTAL". In 2020 and 2024 it does not: some rows have other modes (for example
  "ELECTION DAY" or "ABSENTEE"), and in 2024 some rows have a blank `mode`. Check what
  `mode` takes in each year before filtering.
- **Stata and `.gz` files.** Stata's `import delimited` cannot read `.gz` files. Stata
  users should have uncompressed copies written to `output/`, never into `data/`.

## Rules

1. **Never modify anything in `data/`.** Read it; write results to `output/`.
2. **Look up every code in the codebooks before using it.** Do not guess what a
   value means. The XML codebooks are long: search them for the variable you need
   (for example `EDUC`) instead of reading them top to bottom, and quote the codes
   you found in the plan.
3. **Variable definitions are the user's decisions.** Which vote share, what counts
   as college, how to treat "not reported" codes, which rows to filter, and how to
   join are choices for the user to make. If the user has not specified one, list
   it in the plan as an open decision with the options, and wait. Do not pick one
   silently.
4. **Report row counts.** For every filter and every merge, print the row count
   before and after, and for merges the number of unmatched rows on each side.
5. **No silent drops.** Every step that removes rows says how many and why.

## Conventions

- Python with pandas, unless the user asks for R or Stata.
- Start each script with a docstring: what it reads, what it writes, and the
  variable definitions the user agreed to.
- Keep function definitions separate from the code that runs them, so each piece
  can be run line by line (Shift+Enter in VS Code).
