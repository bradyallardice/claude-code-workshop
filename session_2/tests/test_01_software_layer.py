"""
Layer 1: software tests. Does the code run and behave as intended?

Covers: smoke, unit, integration, end-to-end, regression (in the software sense:
did a change alter verified results?), and negative / edge-case tests.
"""

import importlib

import pandas as pd
import pytest

import helpers

# Values verified against the instructor answer key (session_2/docs/instructor_answer_key.md),
# which was produced and checked separately from this suite. 3 decimal places in the key.
KEY_BASE_WEIGHTED = {
    "Intercept": -0.219,
    "C(treatment, Treatment('cntrl'))[T.info]": 0.302,
    "C(treatment, Treatment('cntrl'))[T.history]": 0.123,
    "C(treatment, Treatment('cntrl'))[T.Hungary]": 0.194,
}
KEY_ROBUSTNESS_INFO = {  # spec: (N, info coefficient, info p-value)
    "(1)": (2036, 0.302, 0.016),
    "(2)": (2036, 0.290, 0.021),
    "(3)": (2035, 0.324, 0.011),
    "(4)": (1151, 0.267, 0.118),
    "(5)": (2035, None, None),  # pooled treatment: no separate info coefficient
    "(6)": (1208, 0.326, 0.051),
}


# ── Smoke ────────────────────────────────────────────────────────────────
@pytest.mark.requirement("R7")
@pytest.mark.parametrize("package", ["pandas", "numpy", "statsmodels"])
def test_smoke_required_package_imports(package):
    """The packages the pipeline needs can be imported."""
    importlib.import_module(package)


@pytest.mark.requirement("R0")
def test_smoke_raw_files_load_with_codebook_columns():
    """Both raw files load and have exactly the columns the codebook documents."""
    survey_columns = set(helpers.read_csv_rows(helpers.SURVEY_CSV)[0])
    demographics_columns = set(helpers.read_csv_rows(helpers.DEMOGRAPHICS_CSV)[0])
    assert survey_columns == {
        "respondent_id", "interview_date", "treatment", "govt_intervention",
        "supports_intervention", "fx_status", "age", "female", "ed_level",
        "urban_rural", "survey_weight",
    }
    assert demographics_columns == {"respondent_id", "income_quintile", "left_right"}


# ── Unit ─────────────────────────────────────────────────────────────────
@pytest.mark.requirement("R6")
@pytest.mark.parametrize(
    "p_value, expected_stars",
    [(0.0, "***"), (0.0099, "***"), (0.01, "**"), (0.049, "**"),
     (0.05, "*"), (0.0999, "*"), (0.10, ""), (0.9, "")],
)
def test_unit_stars_follow_the_table_footnote_convention(p_value, expected_stars):
    """*** p<0.01, ** p<0.05, * p<0.1, per the footnote printed under each table."""
    stars = helpers.load_functions_from_script(
        helpers.SCRIPTS_DIR / "solution_estimate.py", ["stars"]
    )["stars"]
    assert stars(p_value) == expected_stars


class _StubModel:
    """Minimal stand-in for a fitted model: coefficient, SE and p by parameter name."""

    def __init__(self, coefficient, standard_error, p_value):
        names = ["C(treatment, Treatment('cntrl'))[T.info]"]
        self.params = pd.Series([coefficient], index=names)
        self.bse = pd.Series([standard_error], index=names)
        self.pvalues = pd.Series([p_value], index=names)


@pytest.mark.requirement("R6")
def test_unit_coef_str_formats_coefficient_se_and_stars():
    """A coefficient of 0.3022 (SE 0.1257, p 0.0162) prints as $0.302^{**}$ over $(0.126)$."""
    coef_str = helpers.load_functions_from_script(
        helpers.SCRIPTS_DIR / "solution_robustness.py", ["coef_str"]
    )["coef_str"]
    assert coef_str(_StubModel(0.3022, 0.1257, 0.0162), "T.info]") == ("$0.302^{**}$", "$(0.126)$")


@pytest.mark.requirement("R6")
def test_unit_coef_str_negative_coefficient_without_stars():
    """A negative, insignificant coefficient prints with its minus sign and no stars."""
    coef_str = helpers.load_functions_from_script(
        helpers.SCRIPTS_DIR / "solution_robustness.py", ["coef_str"]
    )["coef_str"]
    assert coef_str(_StubModel(-0.163, 0.289, 0.57), "T.info]") == ("$-0.163$", "$(0.289)$")


@pytest.mark.requirement("R6")
def test_edge_case_coef_str_missing_parameter_returns_empty_cells():
    """A parameter absent from a model (e.g. FX terms in a no-FX model) gives blank cells, not an error."""
    coef_str = helpers.load_functions_from_script(
        helpers.SCRIPTS_DIR / "solution_robustness.py", ["coef_str"]
    )["coef_str"]
    assert coef_str(_StubModel(0.3, 0.1, 0.01), "T.current]") == ("", "")


# ── Integration ──────────────────────────────────────────────────────────
@pytest.mark.requirement("R7")
def test_integration_merge_output_has_every_column_the_models_use(merged_output):
    """The merge step's output contains every variable the estimation scripts need."""
    needed = {
        "supports_intervention", "treatment", "fx_status", "age", "female",
        "ed_level", "urban_rural", "income_quintile", "left_right", "survey_weight",
    }
    assert needed <= set(merged_output.columns), needed - set(merged_output.columns)


# ── End to end ───────────────────────────────────────────────────────────
@pytest.mark.requirement("R7")
def test_end_to_end_all_scripts_exit_cleanly_and_write_outputs(pipeline_run):
    """Raw data to final tables from the three scripts in order: exit code 0 and every output written."""
    for script_name, completed in pipeline_run["runs"].items():
        assert completed.returncode == 0, f"{script_name} failed:\n{completed.stderr[-800:]}"
    for output_name in helpers.EXPECTED_OUTPUT_FILES:
        path = pipeline_run["workspace"] / "session_2/output" / output_name
        assert path.exists() and path.stat().st_size > 0, f"missing or empty: {output_name}"


# ── Negative ─────────────────────────────────────────────────────────────
@pytest.mark.requirement("R7")
def test_negative_estimation_without_merge_output_fails_loudly(tmp_path):
    """Running estimation before the merge must stop with an error, not silently use stale data."""
    workspace = helpers.build_workspace(tmp_path)
    completed = helpers.run_script(workspace, "solution_estimate.py")
    assert completed.returncode != 0
    assert "FileNotFoundError" in completed.stderr


# ── Regression (software sense) ──────────────────────────────────────────
@pytest.mark.requirement("R8")
def test_regression_base_model_matches_verified_coefficients(pipeline_run):
    """The base weighted model still reproduces the answer-key coefficients (to the key's 3 decimals)."""
    coefficients = helpers.parse_estimate_coefficients(
        pipeline_run["runs"]["solution_estimate.py"].stdout, "Base model"
    )
    for name, key_value in KEY_BASE_WEIGHTED.items():
        assert abs(coefficients[name][0] - key_value) <= 6e-4, (name, coefficients[name][0], key_value)


@pytest.mark.requirement("R8")
def test_regression_robustness_specifications_match_verified_table(pipeline_run):
    """N, info coefficient and p-value in each robustness specification still match the answer key."""
    stdout = pipeline_run["runs"]["solution_robustness.py"].stdout
    reported_n = helpers.parse_robustness_n(stdout)
    info_rows = helpers.parse_robustness_info_rows(stdout)
    for spec, (key_n, key_coef, key_p) in KEY_ROBUSTNESS_INFO.items():
        assert reported_n[spec] == key_n, (spec, reported_n[spec], key_n)
        if key_coef is not None:
            _, coef, p_value = info_rows[spec]
            assert abs(coef - key_coef) <= 6e-4, (spec, coef, key_coef)
            assert abs(p_value - key_p) <= 6e-4, (spec, p_value, key_p)
