"""
Layer 2: research tests on the raw inputs (data integrity).

Are keys unique, types and ranges valid, and the data consistent with its codebook
(session_2/docs/codebook.md)? Expected values are taken from the codebook, not from
the pipeline.
"""

import numpy as np
import pandas as pd
import pytest

import helpers


@pytest.mark.requirement("R0")
def test_survey_respondent_ids_are_unique(raw_survey):
    """respondent_id is a key in the survey: no repeats."""
    assert raw_survey["respondent_id"].is_unique


@pytest.mark.requirement("R0")
def test_demographics_respondent_ids_are_unique(raw_demographics):
    """respondent_id is a key in the demographics file: a repeat would multiply rows in a join."""
    assert raw_demographics["respondent_id"].is_unique


@pytest.mark.requirement("R0")
def test_survey_has_2044_respondents(raw_survey):
    """The codebook documents 2,044 respondents."""
    assert len(raw_survey) == 2044


@pytest.mark.requirement("R0")
@pytest.mark.parametrize(
    "column, allowed_values",
    [
        ("female", {0, 1}),
        ("ed_level", {1, 2, 3, 4}),
        ("urban_rural", {1, 2, 3}),
        ("supports_intervention", {0, 1}),
    ],
)
def test_coded_survey_variables_take_only_codebook_values(raw_survey, column, allowed_values):
    """Coded variables contain only the values the codebook lists (missing values excluded)."""
    observed = set(raw_survey[column].dropna().astype(int))
    assert observed <= allowed_values, observed - allowed_values


@pytest.mark.requirement("R0")
def test_age_is_within_codebook_range(raw_survey):
    """Age is an integer between 18 and 85."""
    assert raw_survey["age"].min() >= 18 and raw_survey["age"].max() <= 85
    assert (raw_survey["age"] % 1 == 0).all()


@pytest.mark.requirement("R0")
def test_survey_weights_are_strictly_positive(raw_survey):
    """A zero or negative weight would silently drop or invert an observation in a weighted model."""
    assert (raw_survey["survey_weight"] > 0).all()


@pytest.mark.requirement("R0")
def test_demographics_values_are_within_codebook_ranges(raw_demographics):
    """income_quintile is 0-5 (0 = no income, a valid value); left_right is -3 to 3."""
    income = raw_demographics["income_quintile"].dropna()
    left_right = raw_demographics["left_right"].dropna()
    assert set(income.astype(int)) <= {0, 1, 2, 3, 4, 5}
    assert set(left_right.astype(int)) <= {-3, -2, -1, 0, 1, 2, 3}


@pytest.mark.requirement("R0")
def test_categorical_variables_take_only_codebook_values(raw_survey):
    """treatment, fx_status and govt_intervention contain only documented categories."""
    assert set(raw_survey["treatment"]) == {"cntrl", "info", "history", "Hungary"}
    assert set(raw_survey["fx_status"].dropna()) == {"none", "current", "past"}
    assert set(raw_survey["govt_intervention"].dropna()) == {"big", "some", "none", "DK"}


@pytest.mark.requirement("R0")
def test_missing_value_counts_match_codebook(raw_survey):
    """The codebook documents 8 missing outcomes and 2 missing FX statuses, and none elsewhere."""
    missing = raw_survey.isna().sum()
    assert missing["govt_intervention"] == 8
    assert missing["supports_intervention"] == 8
    assert missing["fx_status"] == 2
    others = missing.drop(["govt_intervention", "supports_intervention", "fx_status"])
    assert (others == 0).all(), others[others > 0]


@pytest.mark.requirement("R0")
def test_treatment_arm_sizes(raw_survey):
    """Randomized arms: control 480, info 549, history 520, Hungary 495 (sum 2,044)."""
    sizes = raw_survey["treatment"].value_counts().to_dict()
    assert sizes == {"cntrl": 480, "info": 549, "history": 520, "Hungary": 495}


@pytest.mark.requirement("R0")
def test_interview_dates_parse_and_fall_in_the_fieldwork_window(raw_survey):
    """Interviews ran October 7-21, 2015; every date must parse."""
    dates = pd.to_datetime(raw_survey["interview_date"], format="%Y-%m-%d")
    assert dates.min() == pd.Timestamp("2015-10-07")
    assert dates.max() == pd.Timestamp("2015-10-21")


@pytest.mark.requirement("R0")
def test_demographics_overlap_with_survey_is_as_documented(raw_survey, raw_demographics):
    """The demographics file has 1,000 IDs that match no respondent, and omits 50 respondents."""
    survey_ids = set(raw_survey["respondent_id"])
    demographics_ids = set(raw_demographics["respondent_id"])
    assert len(demographics_ids - survey_ids) == 1000
    assert len(survey_ids - demographics_ids) == 50
    assert len(raw_demographics) == 2994
