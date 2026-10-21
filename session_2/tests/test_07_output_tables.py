"""
Layer 2: research tests on the deliverables (output manifest and table consistency).

Is every expected output produced, and does each table report what an independent
estimator says the models contain: the coefficients, standard errors, stars and N?
"""

import re

import pytest

import helpers
from conftest import read_output_text

ROBUSTNESS_SPEC_LABELS = {
    "(1)": "Base (weighted)",
    "(2)": "Base (unweighted)",
    "(3)": "+ Controls",
    "(4)": "Full controls",
    "(5)": "Pooled treatment",
    "(6)": "Urban only",
}
SPEC_KEYS = list(ROBUSTNESS_SPEC_LABELS)

# Row label in robustness_table.tex -> parameter name in the oracle
ROBUSTNESS_ROWS = {
    "Info treatment": "info",
    "History treatment": "history",
    "Hungary treatment": "Hungary",
    "Any information": "any_info",
    "FX exposed (current)": "fx_current",
    "FX exposed (past)": "fx_past",
}


def assert_cells_match_oracle(tex, row_label, oracle_fits, tolerance=0.0005 + 1e-9):
    """Compare one coefficient row (and the SE row under it) to oracle fits, one per column.

    A cell must be blank exactly where the model does not contain the term. Where present, the
    coefficient and SE must match to the table's 3 decimals and the stars must match the oracle p-value.
    """
    parameter = ROBUSTNESS_ROWS[row_label]
    coefficient_cells = helpers.latex_row_cells(tex, row_label)
    coefficient_numbers = helpers.latex_row_numbers(tex, row_label)
    standard_error_numbers = helpers.latex_row_numbers(tex, row_label, line_offset=1)
    assert len(coefficient_cells) == len(oracle_fits)
    for column, fit in enumerate(oracle_fits):
        if parameter not in fit.coefficients:
            assert coefficient_numbers[column] is None, f"{row_label}, column {column + 1}: should be blank"
            continue
        assert coefficient_numbers[column] is not None, f"{row_label}, column {column + 1}: missing"
        assert abs(coefficient_numbers[column] - fit.coefficients[parameter]) <= tolerance, (
            row_label, column + 1, coefficient_numbers[column], fit.coefficients[parameter])
        assert abs(standard_error_numbers[column] - fit.standard_errors[parameter]) <= tolerance, (
            row_label, column + 1, "SE", standard_error_numbers[column], fit.standard_errors[parameter])
        stars_in_cell = re.search(r"\^\{(\**)\}", coefficient_cells[column])
        expected_stars = helpers.stars_for_p_value(fit.p_values[parameter])
        assert (stars_in_cell.group(1) if stars_in_cell else "") == expected_stars, (
            row_label, column + 1, "stars", fit.p_values[parameter])


# ── Output manifest ──────────────────────────────────────────────────────
@pytest.mark.requirement("R6")
def test_output_manifest_every_expected_file_exists_and_nothing_else_is_written(pipeline_run):
    """The pipeline writes exactly the four expected outputs into an initially empty output folder."""
    written = {p.name for p in (pipeline_run["workspace"] / "session_2/output").iterdir()}
    assert written == set(helpers.EXPECTED_OUTPUT_FILES)


@pytest.mark.requirement("R6")
def test_robustness_table_reports_all_six_specifications_with_their_labels(pipeline_run):
    """Columns (1)-(6) are all present, each with its descriptive label."""
    tex = read_output_text(pipeline_run, "robustness_table.tex")
    header = next(line for line in tex.splitlines() if line.lstrip().startswith("& (1)"))
    assert [c.strip(" \\") for c in header.split("&")[1:]] == SPEC_KEYS
    for label in ROBUSTNESS_SPEC_LABELS.values():
        assert label in tex, label


# ── Robustness table against the independent estimator ───────────────────
@pytest.mark.requirement("R6")
def test_robustness_table_n_row_matches_independent_sample_sizes(pipeline_run, oracle_merged):
    """The N printed under each column equals the independently computed estimation-sample size."""
    tex = read_output_text(pipeline_run, "robustness_table.tex")
    printed = [int(n) for n in helpers.latex_row_numbers(tex, "N &")]
    expected = [helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS[s]).n for s in SPEC_KEYS]
    assert printed == expected


@pytest.mark.requirement("R6")
@pytest.mark.parametrize("row_label", list(ROBUSTNESS_ROWS))
def test_robustness_table_coefficients_standard_errors_and_stars_match_independent_fits(
    pipeline_run, oracle_merged, row_label
):
    """Every cell in the row equals the independent fit to 3 d.p.; blank cells appear exactly where the term is absent."""
    tex = read_output_text(pipeline_run, "robustness_table.tex")
    fits = [helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS[s]) for s in SPEC_KEYS]
    assert_cells_match_oracle(tex, row_label, fits)


@pytest.mark.requirement("R4")
def test_robustness_table_weights_row_matches_what_was_estimated(pipeline_run, oracle_merged):
    """The 'Survey weights' row says No exactly for the unweighted specification, and that column is the unweighted fit."""
    tex = read_output_text(pipeline_run, "robustness_table.tex")
    row = next(line for line in tex.splitlines() if line.startswith("Survey weights"))
    stated = [cell.strip(" \\") for cell in row.split("&")[1:]]
    assert stated == ["Yes", "No", "Yes", "Yes", "Yes", "Yes"]
    unweighted = helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS["(2)"])
    weighted = helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS["(1)"])
    column_2 = helpers.latex_row_numbers(tex, "Info treatment")[1]
    assert abs(column_2 - unweighted.coefficients["info"]) <= 0.0005 + 1e-9
    assert abs(column_2 - weighted.coefficients["info"]) > 0.005


@pytest.mark.requirement("R6")
def test_robustness_table_sample_row_marks_only_the_urban_specification(pipeline_run, oracle_merged):
    """Only column (6) is labelled 'Urban', and its N equals complete cases among urban_rural >= 2."""
    tex = read_output_text(pipeline_run, "robustness_table.tex")
    row = next(line for line in tex.splitlines() if line.startswith("Sample"))
    assert [c.strip(" \\") for c in row.split("&")[1:]] == ["Full"] * 5 + ["Urban"]
    urban = oracle_merged[oracle_merged["urban_rural"] >= 2]
    urban_complete = urban.dropna(subset=["supports_intervention", "fx_status", *helpers.DEMOGRAPHIC_CONTROLS])
    assert int(helpers.latex_row_numbers(tex, "N &")[5]) == len(urban_complete)


# ── Main table against the independent estimator ─────────────────────────
@pytest.mark.requirement("R6")
@pytest.mark.parametrize("row_label", ["Info treatment", "History treatment", "Hungary treatment",
                                       "FX exposed (current)", "FX exposed (past)"])
def test_main_table_cells_match_independent_fits(pipeline_run, oracle_merged, row_label):
    """Column 1 is the treatment-only model, column 2 adds FX and demographics; each cell matches to 3 d.p."""
    tex = read_output_text(pipeline_run, "main_table.tex")
    fits = [
        helpers.fit_oracle_spec(oracle_merged, **helpers.ESTIMATE_ORACLE_MODELS["Treatment only"]),
        helpers.fit_oracle_spec(oracle_merged, **helpers.ESTIMATE_ORACLE_MODELS["+ age, female, ed, urban"]),
    ]
    assert_cells_match_oracle(tex, row_label, fits)


@pytest.mark.requirement("R6")
def test_main_table_n_row_matches_the_models_in_the_estimate_log(pipeline_run):
    """The table's N (2,036 and 2,035) equals the N the estimation script reported for the same two models."""
    tex = read_output_text(pipeline_run, "main_table.tex")
    reported = helpers.parse_estimate_summary_n(pipeline_run["runs"]["solution_estimate.py"].stdout)
    assert [int(n) for n in helpers.latex_row_numbers(tex, "N &")] == [
        reported["Treatment only"], reported["+ age, female, ed, urban"]
    ]


# ── LaTeX hygiene ────────────────────────────────────────────────────────
@pytest.mark.requirement("R6")
@pytest.mark.parametrize("table_name", ["summary_stats.tex", "main_table.tex", "robustness_table.tex"])
def test_latex_tables_are_well_formed(pipeline_run, table_name):
    """Balanced environments, no NaN/inf text, and every table row has the number of columns declared."""
    tex = read_output_text(pipeline_run, table_name)
    for environment in ("tabular", "table"):
        assert tex.count(f"\\begin{{{environment}}}") == tex.count(f"\\end{{{environment}}}")
    assert not re.search(r"\b(nan|inf)\b", tex, flags=re.IGNORECASE)
    declared_columns = len(re.search(r"\\begin\{tabular\}\{([a-z]+)\}", tex).group(1))
    for line in tex.splitlines():
        if "&" in line and "\\multicolumn" not in line:
            assert line.count("&") == declared_columns - 1, f"{table_name}: wrong column count in: {line[:60]}"
