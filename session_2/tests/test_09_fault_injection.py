"""
Test the tests: fault injection and mutation checks.

A check that cannot fail is not a check. Here a known error is injected (always into a
COPY of the data or of the pipeline's output, never the raw files) and the suite's
checks must catch it.

Two kinds of test:
  - the pipeline's own assertions, run on faulty inputs
  - the suite's oracle comparison, run on deliberately corrupted merged output
"""

import csv

import numpy as np
import pandas as pd
import pytest

import helpers


def write_csv(rows, path):
    """Write a list of {column: text} rows to a CSV file."""
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def run_merge_on(tmp_path, *, survey_rows=None, demographics_rows=None):
    """Run only the merge script on (possibly modified) copies of the data; return (process, workspace)."""
    survey_csv, demographics_csv = helpers.SURVEY_CSV, helpers.DEMOGRAPHICS_CSV
    if survey_rows is not None:
        survey_csv = tmp_path / "survey_modified.csv"
        write_csv(survey_rows, survey_csv)
    if demographics_rows is not None:
        demographics_csv = tmp_path / "demographics_modified.csv"
        write_csv(demographics_rows, demographics_csv)
    workspace = helpers.build_workspace(tmp_path / "workspace", survey_csv=survey_csv, demographics_csv=demographics_csv)
    return helpers.run_script(workspace, "solution_merge.py"), workspace


def survey_ids():
    """Set of respondent_id strings in the raw survey file."""
    return {row["respondent_id"] for row in helpers.read_csv_rows(helpers.SURVEY_CSV)}


# ── Faults the pipeline's own assertions must catch ──────────────────────
@pytest.mark.requirement("R9")
def test_duplicated_demographics_row_for_a_survey_respondent_stops_the_merge(tmp_path):
    """Duplicate one survey respondent's demographics row: the left join yields 2,045 rows and the script must stop."""
    rows = helpers.read_csv_rows(helpers.DEMOGRAPHICS_CSV)
    victim = next(row for row in rows if row["respondent_id"] in survey_ids())
    completed, _ = run_merge_on(tmp_path, demographics_rows=rows + [dict(victim)])
    assert completed.returncode != 0
    assert "Expected 2044 rows, got 2045" in completed.stderr


@pytest.mark.requirement("R9")
def test_a_missing_survey_respondent_stops_the_merge(tmp_path):
    """Remove one respondent from the survey: the merge would have 2,043 rows and the script must stop."""
    rows = helpers.read_csv_rows(helpers.SURVEY_CSV)
    completed, _ = run_merge_on(tmp_path, survey_rows=rows[1:])
    assert completed.returncode != 0
    assert "Expected 2044 rows, got 2043" in completed.stderr


@pytest.mark.requirement("R9")
def test_duplicated_row_for_a_non_survey_id_is_harmless_to_a_left_join(tmp_path):
    """Duplicating the row of an ID that is NOT a survey respondent changes nothing: the merge still passes.

    This is correct behaviour, and the reason the exercise says to duplicate a *survey* respondent:
    a fault only fails a test if it touches what the test checks.
    """
    rows = helpers.read_csv_rows(helpers.DEMOGRAPHICS_CSV)
    stranger = next(row for row in rows if row["respondent_id"] not in survey_ids())
    completed, workspace = run_merge_on(tmp_path, demographics_rows=rows + [dict(stranger)])
    assert completed.returncode == 0
    merged = pd.read_csv(workspace / "session_2/output/merged_survey.csv")
    assert len(merged) == 2044


# ── A fault the pipeline's own assertions do NOT catch, but the suite must ─
@pytest.mark.requirement("R9")
def test_corrupted_treatment_label_passes_the_pipeline_but_fails_the_oracle_comparison(tmp_path, oracle_merged):
    """Relabel one control respondent as 'info'. The merge script's asserts pass; the suite's cell-by-cell check must fail.

    This is the case for independent expected values: the pipeline's row-count and key checks are blind
    to a wrong label, so only a test with outside knowledge can catch it.
    """
    rows = helpers.read_csv_rows(helpers.SURVEY_CSV)
    victim_index = next(i for i, row in enumerate(rows) if row["treatment"] == "cntrl")
    rows[victim_index]["treatment"] = "info"
    completed, workspace = run_merge_on(tmp_path, survey_rows=rows)
    assert completed.returncode == 0, "the pipeline's own asserts do not look at treatment labels"

    corrupted_output = pd.read_csv(workspace / "session_2/output/merged_survey.csv")
    with pytest.raises(AssertionError, match="column 'treatment'"):
        helpers.check_merged_matches_oracle(corrupted_output, oracle_merged)


# ── Mutation tests on the suite's own comparison ─────────────────────────
def change_one_treatment_label(frame):
    out = frame.copy()
    first = out.index[0]
    out.loc[first, "treatment"] = "Hungary" if out.loc[first, "treatment"] != "Hungary" else "info"
    return out


def drop_one_row(frame):
    return frame.iloc[1:]


def duplicate_one_row(frame):
    return pd.concat([frame, frame.iloc[[0]]])


def turn_an_income_zero_into_missing(frame):
    out = frame.copy()
    out.loc[out.index[out["income_quintile"] == 0][0], "income_quintile"] = np.nan
    return out


def nudge_one_survey_weight(frame):
    out = frame.copy()
    out.loc[out.index[0], "survey_weight"] += 0.01
    return out


def misalign_left_right_by_one_row(frame):
    out = frame.copy()
    out["left_right"] = out["left_right"].shift(1)
    return out


def drop_respondents_without_demographics(frame):
    return frame[frame["income_quintile"].notna() | frame["left_right"].notna()]


MUTATIONS = {
    "change one treatment label": change_one_treatment_label,
    "drop one row": drop_one_row,
    "duplicate one row": duplicate_one_row,
    "turn an income of 0 into missing": turn_an_income_zero_into_missing,
    "nudge one survey weight by 0.01": nudge_one_survey_weight,
    "misalign left_right by one row": misalign_left_right_by_one_row,
    "drop respondents without demographics (inner-join-like)": drop_respondents_without_demographics,
}


@pytest.mark.requirement("R9")
def test_unmutated_merged_output_passes_the_oracle_comparison(merged_output, oracle_merged):
    """Control for the mutation tests: the unmodified output passes, so a failure below is caused by the mutation."""
    helpers.check_merged_matches_oracle(merged_output, oracle_merged)


@pytest.mark.requirement("R9")
@pytest.mark.parametrize("mutation_name", list(MUTATIONS))
def test_oracle_comparison_catches_each_injected_corruption(merged_output, oracle_merged, mutation_name):
    """Each deliberately corrupted copy of the merged output must make the cell-by-cell comparison fail."""
    corrupted = MUTATIONS[mutation_name](merged_output)
    with pytest.raises(AssertionError):
        helpers.check_merged_matches_oracle(corrupted, oracle_merged)
