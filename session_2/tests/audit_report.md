# Audit report: Session 2 verification suite

## Tests run

Command: `python3 -m pytest session_2/tests --audit-report session_2/tests/audit_report.md -q -p no:cacheprovider`

- passed: 126
- failed: 0
- skipped: 0
- known issues (xfail): 5
- unexpectedly passing known issues (xpass): 0

## Requirements

| Requirement | Description | Tests | Status |
|---|---|---|---|
| R0 | Raw inputs are valid (keys, types, ranges, codebook consistency) | 16 | passing |
| R1 | Merge keeps every respondent and attaches the right demographics | 7 | passing |
| R2 | Variables are built as defined | 2 | passing |
| R3 | Control is the reference arm | 2 | passing |
| R4 | Survey weights are used and the estimates are right | 16 | passing |
| R5 | N is explained for every model | 15 | passing |
| R6 | Every specification is reported, and tables match the data | 43 | passing, with known issues |
| R7 | Pipeline runs end to end and fails loudly on bad input | 6 | passing |
| R8 | Pipeline is reproducible from raw inputs | 10 | passing |
| R9 | The checks themselves can fail (fault injection, planted answer) | 14 | passing |

## Known issues (expected failures)

- `test_04_variables_and_summary.py::test_fx_dummies_in_summary_table_exclude_respondents_with_missing_fx_status`: Known issue in solution_estimate.py: (fx_status == 'current') is False for the 2 respondents with missing fx_status, so the FX dummies report N = 2,044 and silently code them as 'not exposed'.
- `test_04_variables_and_summary.py::test_summary_table_label_range_matches_the_reported_min_and_max[Education level (1--5)]`: Known issue in solution_estimate.py: the row label states a range that contradicts the table's own Min/Max columns and the codebook. ed_level is coded 1-4.
- `test_04_variables_and_summary.py::test_summary_table_label_range_matches_the_reported_min_and_max[Income quintile (1--5)]`: Known issue in solution_estimate.py: the row label states a range that contradicts the table's own Min/Max columns and the codebook. income_quintile is coded 0-5 (0 = no income).
- `test_04_variables_and_summary.py::test_summary_table_label_range_matches_the_reported_min_and_max[Left--right placement (0--10)]`: Known issue in solution_estimate.py: the row label states a range that contradicts the table's own Min/Max columns and the codebook. left_right is coded -3 to 3.
- `test_04_variables_and_summary.py::test_summary_table_label_range_matches_the_reported_min_and_max[Urban--rural (1--5)]`: Known issue in solution_estimate.py: the row label states a range that contradicts the table's own Min/Max columns and the codebook. urban_rural is coded 1-3.

## Not tested

- Only the Python solution pipeline is tested. The Stata (.do) and R versions in session_2/scripts are not exercised.
- Clean-environment installation: dependencies were not reinstalled from scratch.
- Manuscript-to-code traceability: there is no manuscript in this session.
- Performance and scaling: not relevant at 2,044 rows.
- Robustness to alternative specifications beyond the six in the table: that is a research design question.
- Treatment x FX interaction model: only its sample size is checked, not its coefficients.

## Numerical checks (pipeline value vs independent value)

| Check | Pipeline | Independent | Difference | Tolerance |
|---|---|---|---|---|
| base-model intercept vs logit(weighted control share) | -0.218726 | -0.218726 | 2.7e-07 | 1e-05 |
| base-model intercept + info vs logit(weighted info share) | 0.083480 | 0.083480 | 1.9e-07 | 1e-05 |
| base-model intercept + history vs logit(weighted history share) | -0.095658 | -0.095658 | 5.0e-07 | 1e-05 |
| base-model intercept + Hungary vs logit(weighted Hungary share) | -0.024596 | -0.024596 | 4.6e-07 | 1e-05 |
| Treatment only: info coefficient | 0.302206 | 0.302206 | 4.6e-07 | 2e-06 |
| + FX exposure: info coefficient | 0.303755 | 0.303755 | 7.3e-08 | 2e-06 |
| + age, female, ed, urban: info coefficient | 0.324333 | 0.324333 | 1.3e-07 | 2e-06 |
| + income_quintile: info coefficient | 0.245924 | 0.245924 | 4.5e-07 | 2e-06 |
| + left_right: info coefficient | 0.291469 | 0.291469 | 2.7e-07 | 2e-06 |
| + both income & LR: info coefficient | 0.266587 | 0.266587 | 3.2e-07 | 2e-06 |
| robustness (1): info coefficient | 0.302200 | 0.302206 | 5.5e-06 | 6e-05 |
| robustness (2): info coefficient | 0.290300 | 0.290308 | 8.2e-06 | 6e-05 |
| robustness (3): info coefficient | 0.324300 | 0.324333 | 3.3e-05 | 6e-05 |
| robustness (4): info coefficient | 0.266600 | 0.266587 | 1.3e-05 | 6e-05 |
| robustness (6): info coefficient | 0.325700 | 0.325715 | 1.5e-05 | 6e-05 |

## Needs your call

- Join type: a left join is the only one that keeps all 2,044 respondents without adding non-respondents. The tests check the pipeline matches that choice; they do not choose it.
- `govt_intervention = DK` (230 respondents) is coded 0 in `supports_intervention`, i.e. 'does not support', not missing. That is the codebook's definition, but it is a substantive choice.
- `income_quintile = 0` means 'no income' and is kept as a valid value (8 respondents). The tests check it is not turned into a missing value.
- Adding both income and left-right drops about 44% of respondents. The tests reconcile the drop; whether complete-case analysis is acceptable is a research decision.
- Weights are applied as frequency weights (`freq_weights`), so standard errors are not design-based. The independent estimator reproduces this choice; it does not validate it.

## Not covered

Passing tests, complete output, and reproducibility do not show that the research design is valid. In particular:

- Identification: the tests do not establish that randomization was implemented as described.
- Construct validity: whether `supports_intervention` measures support for intervention.
- Whether the specification answers the research question.

## Reproduction evidence

- Python 3.8.16, pandas 1.5.3, numpy 1.24.4, statsmodels 0.14.1
- swiss_franc_survey.csv SHA-256: 2829fcf338fb3ccd...
- respondent_demographics.csv SHA-256: 4fe116f5c2e9737d...
