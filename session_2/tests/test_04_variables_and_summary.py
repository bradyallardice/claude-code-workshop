"""
Layer 2: research tests on variable construction and the summary-statistics table.

Do variables match their definitions, and does summary_stats.tex report what the
data actually contain?
"""

import re

import numpy as np
import pytest

from conftest import read_output_text

# Row label in summary_stats.tex -> column in the merged data
SUMMARY_ROW_TO_COLUMN = {
    "Supports intervention (0/1)": "supports_intervention",
    "Age (years)": "age",
    "Female (0/1)": "female",
    "Education level (1--5)": "ed_level",
    "Urban--rural (1--5)": "urban_rural",
    "Income quintile (1--5)": "income_quintile",
    "Left--right placement (0--10)": "left_right",
}


def parse_summary_rows(tex):
    """Return {label: (N, mean, sd, min, max)} from the rows of summary_stats.tex."""
    rows = {}
    for line in tex.splitlines():
        cells = [cell.strip().rstrip("\\").strip() for cell in line.split("&")]
        if len(cells) == 6 and cells[1].isdigit():
            rows[cells[0]] = (int(cells[1]), *[float(value) for value in cells[2:]])
    return rows


# ── Variable construction ────────────────────────────────────────────────
@pytest.mark.requirement("R2")
def test_supports_intervention_is_one_exactly_for_some_or_big(merged_output):
    """supports_intervention = 1 for 'some'/'big', 0 for 'none'/'DK', and missing only where the answer is missing."""
    answer = merged_output["govt_intervention"]
    supports = merged_output["supports_intervention"]
    assert (supports[answer.isin(["some", "big"])] == 1).all()
    assert (supports[answer.isin(["none", "DK"])] == 0).all()
    assert supports[answer.isna()].isna().all()
    assert answer[supports.isna()].isna().all()


@pytest.mark.requirement("R2")
def test_dont_know_answers_are_coded_as_not_supporting_not_missing(merged_output):
    """230 'DK' answers are counted as 0 (codebook definition). This pins the choice so a change is visible."""
    assert (merged_output["govt_intervention"] == "DK").sum() == 230
    assert merged_output.loc[merged_output["govt_intervention"] == "DK", "supports_intervention"].notna().all()


# ── Summary table against the data ───────────────────────────────────────
@pytest.mark.requirement("R6")
@pytest.mark.parametrize("label, column", list(SUMMARY_ROW_TO_COLUMN.items()))
def test_summary_table_statistics_match_independent_calculation(pipeline_run, oracle_merged, label, column):
    """N, mean, SD, min and max in summary_stats.tex equal values recomputed from the raw files (2 d.p.)."""
    rows = parse_summary_rows(read_output_text(pipeline_run, "summary_stats.tex"))
    values = oracle_merged[column].dropna().to_numpy(dtype=float)
    expected = (len(values), values.mean(), values.std(ddof=1), values.min(), values.max())
    reported = rows[label]
    assert reported[0] == expected[0], f"N: table {reported[0]} vs data {expected[0]}"
    for table_value, data_value, name in zip(reported[1:], expected[1:], ["mean", "sd", "min", "max"]):
        assert abs(table_value - data_value) <= 0.005 + 1e-9, f"{name}: table {table_value} vs data {data_value:.4f}"


@pytest.mark.requirement("R6")
def test_summary_table_label_ranges_are_found_so_the_label_checks_are_not_vacuous(pipeline_run):
    """Exactly four row labels state a range like '(1--5)'. If this changes, update the label tests below."""
    labels = parse_summary_rows(read_output_text(pipeline_run, "summary_stats.tex"))
    labelled = [label for label in labels if re.search(r"\(-?\d+--\d+\)", label) and "0/1" not in label]
    assert len(labelled) == 4, labelled


LABEL_RANGE_BUG = (
    "Known issue in solution_estimate.py: the row label states a range that contradicts the "
    "table's own Min/Max columns and the codebook."
)


@pytest.mark.requirement("R6")
@pytest.mark.parametrize(
    "label",
    [
        pytest.param("Education level (1--5)", marks=pytest.mark.xfail(strict=True, reason=LABEL_RANGE_BUG + " ed_level is coded 1-4.")),
        pytest.param("Urban--rural (1--5)", marks=pytest.mark.xfail(strict=True, reason=LABEL_RANGE_BUG + " urban_rural is coded 1-3.")),
        pytest.param("Income quintile (1--5)", marks=pytest.mark.xfail(strict=True, reason=LABEL_RANGE_BUG + " income_quintile is coded 0-5 (0 = no income).")),
        pytest.param("Left--right placement (0--10)", marks=pytest.mark.xfail(strict=True, reason=LABEL_RANGE_BUG + " left_right is coded -3 to 3.")),
    ],
)
def test_summary_table_label_range_matches_the_reported_min_and_max(pipeline_run, label):
    """The range written in a row label must equal that row's own Min and Max columns."""
    rows = parse_summary_rows(read_output_text(pipeline_run, "summary_stats.tex"))
    stated_low, stated_high = map(int, re.search(r"\((-?\d+)--(-?\d+)\)", label).groups())
    _, _, _, reported_min, reported_max = rows[label]
    assert (stated_low, stated_high) == (reported_min, reported_max)


@pytest.mark.requirement("R6")
@pytest.mark.xfail(
    strict=True,
    reason="Known issue in solution_estimate.py: (fx_status == 'current') is False for the 2 respondents "
           "with missing fx_status, so the FX dummies report N = 2,044 and silently code them as 'not exposed'.",
)
def test_fx_dummies_in_summary_table_exclude_respondents_with_missing_fx_status(pipeline_run, oracle_merged):
    """FX exposure is unknown for 2 respondents; the dummy rows should report N = 2,042, not 2,044."""
    rows = parse_summary_rows(read_output_text(pipeline_run, "summary_stats.tex"))
    expected_n = int(oracle_merged["fx_status"].notna().sum())
    assert expected_n == 2042
    assert rows["FX exposed, current (0/1)"][0] == expected_n
    assert rows["FX exposed, past (0/1)"][0] == expected_n
