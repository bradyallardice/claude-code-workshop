"""
Layer 2: research tests on sample accounting.

Where did every row go? For each model the number of observations used must equal
the rows in, minus the rows dropped for each missing variable, and must equal what
the pipeline reports.
"""

import re

import pytest

import helpers

TOTAL_RESPONDENTS = 2044

# Variables each estimate-script model needs, in the order they are checked for missingness
ESTIMATE_MODEL_VARIABLES = {
    "Treatment only": ["supports_intervention", "treatment"],
    "+ FX exposure": ["supports_intervention", "treatment", "fx_status"],
    "+ age, female, ed, urban": ["supports_intervention", "treatment", "fx_status", *helpers.DEMOGRAPHIC_CONTROLS],
    "+ income_quintile": ["supports_intervention", "treatment", "fx_status", *helpers.DEMOGRAPHIC_CONTROLS, "income_quintile"],
    "+ left_right": ["supports_intervention", "treatment", "fx_status", *helpers.DEMOGRAPHIC_CONTROLS, "left_right"],
    "+ both income & LR": ["supports_intervention", "treatment", "fx_status", *helpers.ALL_CONTROLS],
}


def reconcile(frame, variables):
    """Drop rows for each missing variable in turn.

    Returns (drops_by_reason, rows_remaining) where drops_by_reason counts the rows
    newly lost at each variable, so that rows_in - sum(drops) == rows_remaining.
    """
    remaining = frame
    drops_by_reason = {}
    for variable in variables:
        missing = remaining[variable].isna()
        drops_by_reason[variable] = int(missing.sum())
        remaining = remaining[~missing]
    return drops_by_reason, len(remaining)


@pytest.mark.requirement("R5")
@pytest.mark.parametrize("model_label", list(ESTIMATE_MODEL_VARIABLES))
def test_estimate_model_n_reconciles_to_rows_in_minus_drops(pipeline_run, oracle_merged, model_label):
    """rows in (2,044) - rows dropped (by reason) = N used = N the pipeline reports."""
    drops_by_reason, expected_n = reconcile(oracle_merged, ESTIMATE_MODEL_VARIABLES[model_label])
    assert TOTAL_RESPONDENTS - sum(drops_by_reason.values()) == expected_n
    reported = helpers.parse_estimate_summary_n(pipeline_run["runs"]["solution_estimate.py"].stdout)
    assert reported[model_label] == expected_n, (
        f"{model_label}: pipeline N {reported[model_label]} vs reconciled {expected_n} (drops: {drops_by_reason})"
    )


@pytest.mark.requirement("R5")
def test_interaction_model_uses_the_same_sample_as_the_demographics_model(pipeline_run):
    """The interaction adds terms, not variables with missing values: N must equal the controls model's N."""
    reported = helpers.parse_estimate_summary_n(pipeline_run["runs"]["solution_estimate.py"].stdout)
    assert reported["Treatment x FX interaction"] == reported["+ age, female, ed, urban"] == 2035


@pytest.mark.requirement("R5")
@pytest.mark.parametrize("spec", list(helpers.ROBUSTNESS_ORACLE_SPECS))
def test_robustness_spec_n_matches_independent_complete_case_count(pipeline_run, oracle_merged, spec):
    """Each robustness specification's N equals the independently computed estimation-sample size."""
    expected_n = helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS[spec]).n
    reported = helpers.parse_robustness_n(pipeline_run["runs"]["solution_robustness.py"].stdout)
    assert reported[spec] == expected_n


@pytest.mark.requirement("R5")
def test_missing_data_trap_drops_are_explained_by_income_and_left_right(oracle_merged):
    """Adding income and left-right loses 565 and 542 respondents (overlapping); both together lose ~44%."""
    base_n = reconcile(oracle_merged, ESTIMATE_MODEL_VARIABLES["+ age, female, ed, urban"])[1]
    assert oracle_merged["income_quintile"].isna().sum() == 565
    assert oracle_merged["left_right"].isna().sum() == 542
    full_n = reconcile(oracle_merged, ESTIMATE_MODEL_VARIABLES["+ both income & LR"])[1]
    assert full_n == 1151
    share_lost = 1 - full_n / TOTAL_RESPONDENTS
    assert 0.43 < share_lost < 0.445, f"share lost {share_lost:.3f}"
    assert base_n - full_n == 884  # rows lost relative to the model without income and left-right


@pytest.mark.requirement("R5")
def test_complete_case_sample_printed_by_robustness_script_is_correct(pipeline_run, oracle_merged):
    """The 'Complete cases' count the script prints equals complete cases on all ten model variables."""
    printed = int(re.search(r"Complete cases: (\d+)", pipeline_run["runs"]["solution_robustness.py"].stdout).group(1))
    variables = ["supports_intervention", "treatment", "fx_status", *helpers.ALL_CONTROLS, "survey_weight"]
    assert printed == int(oracle_merged.dropna(subset=variables).shape[0]) == 1151
