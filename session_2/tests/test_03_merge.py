"""
Layer 2: research tests on the merge (merge integrity).

The expected merge is rebuilt independently (csv module + dictionary lookup) and the
pipeline's merged_survey.csv is compared to it cell by cell.
"""

import numpy as np
import pytest

import helpers


@pytest.mark.requirement("R1")
def test_merged_row_count_is_2044(merged_output):
    """A left join of 2,044 respondents onto demographics must have exactly 2,044 rows."""
    assert len(merged_output) == 2044


@pytest.mark.requirement("R1")
def test_merged_respondent_ids_are_unique(merged_output):
    """No respondent appears twice after the merge (a repeated key would multiply rows)."""
    assert merged_output["respondent_id"].is_unique


@pytest.mark.requirement("R1")
def test_row_count_is_the_left_join_count_and_not_another_joins(merged_output, raw_survey, raw_demographics):
    """Only a left join gives 2,044: inner would give 1,994, right 2,994, outer 3,044."""
    survey_ids = set(raw_survey["respondent_id"])
    demographics_ids = set(raw_demographics["respondent_id"])
    other_joins = {
        "inner": len(survey_ids & demographics_ids),
        "right": len(raw_demographics),
        "outer": len(survey_ids | demographics_ids),
    }
    assert other_joins == {"inner": 1994, "right": 2994, "outer": 3044}
    assert len(merged_output) not in other_joins.values()


@pytest.mark.requirement("R1")
def test_merged_data_equals_independent_left_join_in_every_cell(merged_output, oracle_merged):
    """Every survey value is preserved and every demographics value is attached to the right respondent."""
    helpers.check_merged_matches_oracle(merged_output, oracle_merged)


@pytest.mark.requirement("R1")
def test_respondents_absent_from_demographics_are_kept_with_missing_demographics(
    merged_output, raw_survey, raw_demographics
):
    """The 50 survey respondents with no demographics row stay in the data, with NaN income and left_right."""
    unmatched_ids = set(raw_survey["respondent_id"]) - set(raw_demographics["respondent_id"])
    unmatched_rows = merged_output[merged_output["respondent_id"].isin(unmatched_ids)]
    assert len(unmatched_rows) == 50
    assert unmatched_rows["income_quintile"].isna().all()
    assert unmatched_rows["left_right"].isna().all()


@pytest.mark.requirement("R1")
def test_income_quintile_zero_is_kept_as_a_valid_value(merged_output, raw_survey, raw_demographics):
    """'No income' is coded 0. It must survive the merge as 0, not become missing."""
    survey_ids = set(raw_survey["respondent_id"])
    expected_zero_ids = set(
        raw_demographics.loc[
            (raw_demographics["income_quintile"] == 0)
            & raw_demographics["respondent_id"].isin(survey_ids),
            "respondent_id",
        ]
    )
    merged_zero_ids = set(merged_output.loc[merged_output["income_quintile"] == 0, "respondent_id"])
    assert len(expected_zero_ids) == 8
    assert merged_zero_ids == expected_zero_ids


@pytest.mark.requirement("R1")
def test_trace_three_respondents_from_raw_files_to_merged_data(merged_output, oracle_merged):
    """Follow one typical, one missing-outcome and one no-demographics respondent through the merge.

    The three records are chosen by rule from the raw files, not by looking at the pipeline output:
    respondent 9; the lowest respondent_id with a missing outcome; the lowest id absent from the
    demographics file.
    """
    missing_outcome_id = int(oracle_merged.loc[oracle_merged["supports_intervention"].isna(), "respondent_id"].min())
    no_demographics_id = int(oracle_merged.loc[oracle_merged["income_quintile"].isna()
                                               & oracle_merged["left_right"].isna(),
                                               "respondent_id"].min())
    for respondent_id in (9, missing_outcome_id, no_demographics_id):
        pipeline_row = merged_output[merged_output["respondent_id"] == respondent_id]
        oracle_row = oracle_merged[oracle_merged["respondent_id"] == respondent_id]
        assert len(pipeline_row) == 1, f"respondent {respondent_id} appears {len(pipeline_row)} times"
        helpers.check_merged_matches_oracle(pipeline_row, oracle_row)

    # Specific, hand-checkable facts about those records
    row_9 = merged_output[merged_output["respondent_id"] == 9].iloc[0]
    assert row_9["treatment"] == "cntrl" and row_9["fx_status"] == "none"
    missing_row = merged_output[merged_output["respondent_id"] == missing_outcome_id].iloc[0]
    assert np.isnan(missing_row["supports_intervention"]), "a missing outcome must stay missing, not become 0"
