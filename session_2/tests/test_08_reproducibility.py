"""
End-to-end reproducibility and completeness tests.

Can the whole project be rebuilt from the raw inputs alone, with the same result every
time, without touching the raw data, and does a change in an input propagate to the
outputs? (The first of these is also exercised by the `pipeline_run` fixture, which runs
in an empty workspace.)
"""

import csv

import numpy as np
import pandas as pd
import pytest

import helpers
from conftest import read_output_text


def write_csv(rows, path):
    """Write a list of {column: text} rows to a CSV file."""
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


# ── Complete rebuild ─────────────────────────────────────────────────────
@pytest.mark.requirement("R8")
def test_complete_rebuild_from_raw_inputs_alone(pipeline_run):
    """In a workspace holding only raw data and scripts, every output is regenerated and every script succeeds."""
    output_dir = pipeline_run["workspace"] / "session_2/output"
    assert {p.name for p in output_dir.iterdir()} == set(helpers.EXPECTED_OUTPUT_FILES)
    assert all(run.returncode == 0 for run in pipeline_run["runs"].values())


@pytest.mark.requirement("R8")
def test_pipeline_does_not_modify_the_raw_data(pipeline_run):
    """The raw inputs are byte-for-byte unchanged after a full run."""
    for file_name in ["swiss_franc_survey.csv", "respondent_demographics.csv"]:
        before = helpers.sha256_of_file(f"session_2/data/{file_name}")
        after = helpers.sha256_of_file(pipeline_run["workspace"] / "session_2/data" / file_name)
        assert before == after, file_name


# ── Repeatability ────────────────────────────────────────────────────────
@pytest.mark.requirement("R8")
def test_repeated_runs_give_byte_identical_outputs_and_logs(pipeline_run, pipeline_run_repeat):
    """Two independent runs produce identical output files and identical printed logs (no hidden randomness)."""
    for output_name in helpers.EXPECTED_OUTPUT_FILES:
        first = helpers.sha256_of_file(pipeline_run["workspace"] / "session_2/output" / output_name)
        second = helpers.sha256_of_file(pipeline_run_repeat["workspace"] / "session_2/output" / output_name)
        assert first == second, output_name
    for script_name in helpers.PIPELINE_SCRIPTS:
        assert pipeline_run["runs"][script_name].stdout == pipeline_run_repeat["runs"][script_name].stdout


# ── Committed outputs are current ────────────────────────────────────────
@pytest.mark.requirement("R8")
def test_committed_merged_data_equals_a_fresh_rebuild(pipeline_run, merged_output):
    """session_2/output/merged_survey.csv in the repository equals what the pipeline now produces.

    Numeric columns are compared within 1e-9: a CSV round trip can change the last bit of a float.
    """
    committed = pd.read_csv(helpers.COMMITTED_OUTPUT_DIR / "merged_survey.csv")
    assert list(committed.columns) == list(merged_output.columns)
    for column in committed.columns:
        if committed[column].dtype.kind in "fi":
            assert np.allclose(committed[column], merged_output[column], rtol=0, atol=1e-9, equal_nan=True), column
        else:
            assert committed[column].fillna("<NA>").equals(merged_output[column].fillna("<NA>")), column


@pytest.mark.requirement("R8")
@pytest.mark.parametrize("table_name", ["summary_stats.tex", "main_table.tex", "robustness_table.tex"])
def test_committed_tables_equal_a_fresh_rebuild(pipeline_run, table_name):
    """The LaTeX tables in the repository are not stale: they equal what the scripts write now."""
    committed = (helpers.COMMITTED_OUTPUT_DIR / table_name).read_text(encoding="utf-8")
    assert committed == read_output_text(pipeline_run, table_name)


# ── Dependency: an upstream change must reach the outputs ────────────────
@pytest.mark.requirement("R8")
def test_changing_an_upstream_input_changes_the_downstream_outputs(tmp_path, oracle_merged, pipeline_run):
    """Blank the income of 25 otherwise-complete respondents; specification (4)'s N must fall from 1,151 to 1,126.

    The expected N comes from the independent oracle run on the modified file, not from the baseline.
    """
    complete = oracle_merged.dropna(subset=["supports_intervention", "fx_status", *helpers.ALL_CONTROLS])
    affected_ids = {str(int(i)) for i in sorted(complete["respondent_id"])[:25]}

    modified_rows = helpers.read_csv_rows(helpers.DEMOGRAPHICS_CSV)
    for row in modified_rows:
        if row["respondent_id"] in affected_ids:
            row["income_quintile"] = ""
    modified_csv = tmp_path / "demographics_modified.csv"
    write_csv(modified_rows, modified_csv)

    workspace = helpers.build_workspace(tmp_path / "workspace", demographics_csv=modified_csv)
    runs = helpers.run_pipeline(workspace)
    assert all(run.returncode == 0 for run in runs.values()), [r.stderr[-300:] for r in runs.values()]

    expected_n = helpers.fit_oracle_spec(
        helpers.expected_merged_frame(demographics_path=modified_csv),
        **helpers.ROBUSTNESS_ORACLE_SPECS["(4)"],
    ).n
    assert expected_n == 1151 - 25
    assert helpers.parse_robustness_n(runs["solution_robustness.py"].stdout)["(4)"] == expected_n
    assert (workspace / "session_2/output/summary_stats.tex").read_text() != read_output_text(pipeline_run, "summary_stats.tex")
