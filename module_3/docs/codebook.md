# Codebook: Swiss Franc Shock and Polish Voter Attitudes

## Background

In January 2015, the Swiss National Bank unexpectedly removed its currency peg, causing the Swiss franc to surge against the Polish zloty. Many Polish households held mortgages denominated in Swiss francs and saw their monthly payments spike overnight. A nationally representative survey conducted in October 2015 asked respondents about their attitudes toward government intervention to help affected borrowers. The survey included a randomized information treatment: before being asked about government intervention, respondents were randomly assigned to receive different framings of the crisis.

Data source: Ahlquist, Copelovitch, and Walter, "The Political Consequences of External Economic Shocks," *American Journal of Political Science* (2020). Replication data available on Harvard Dataverse.

---

## File 1: `swiss_franc_survey.csv`

Survey of 2,044 Polish adults conducted October 7-21, 2015.

| Variable | Description | Values | Missing |
|----------|-------------|--------|---------|
| `respondent_id` | Unique respondent ID | integer (1-2044) | 0 |
| `interview_date` | Date of interview | YYYY-MM-DD (range: 2015-10-07 to 2015-10-21) | 0 |
| `treatment` | Randomly assigned information treatment | `cntrl` = no information (control); `info` = factual information about the CHF shock; `history` = historical context about FX lending; `Hungary` = information about Hungary's policy response | 0 |
| `govt_intervention` | Support for government intervention to help FX borrowers | `big` = big intervention; `some` = some intervention; `none` = no intervention; `DK` = don't know | 8 |
| `supports_intervention` | Binary: supports some or big intervention | 1 = supports (govt_intervention is "some" or "big"); 0 = does not support | 8 |
| `fx_status` | Respondent's foreign currency loan status | `current` = currently repaying an FX loan; `past` = had an FX loan, no longer repaying; `none` = never had an FX loan | 2 |
| `age` | Age in 2015 | integer (18-85) | 0 |
| `female` | Gender | 0 = male; 1 = female | 0 |
| `ed_level` | Education level | 1 = less than vocational; 2 = vocational; 3 = high school; 4 = university or above | 0 |
| `urban_rural` | Settlement size | 1 = rural; 2 = small urban; 3 = big urban | 0 |
| `survey_weight` | Survey weight | continuous, > 0 | 0 |

---

## File 2: `respondent_demographics.csv`

Additional demographic variables for survey respondents and other individuals. This file contains more rows than the survey — not all rows correspond to survey respondents.

| Variable | Description | Values | Missing |
|----------|-------------|--------|---------|
| `respondent_id` | Respondent ID (merge key) | integer | 0 |
| `income_quintile` | Household income quintile | 0 = no income; 1-5 = quintiles (1 = lowest, 5 = highest) | yes |
| `left_right` | Left-right ideological self-placement | integer, -3 (left) to 3 (right); 0 = center | yes |

### Notes on this file

- This file has more rows than the survey. You will need to decide what join type to use.
- `income_quintile`: the value 0 means "no income" and is a valid response, not a missing value.
- `left_right`: missing values are respondents who declined to place themselves on the scale.
- Not all survey respondents appear in this file. Some demographic data was not collected.
