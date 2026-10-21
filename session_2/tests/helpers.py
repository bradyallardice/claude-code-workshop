"""
Independent oracles and utilities for the Session 2 test suite.

Nothing in this module imports or calls the solution scripts' analysis code.
Expected values are rebuilt from the raw CSV files by a different route:

    - the merge is a dictionary lookup using the csv module (not pandas.merge)
    - the logistic regression is a hand-written IRLS in numpy (not statsmodels)

so a bug in the pipeline cannot also be a bug in the expectation.

All paths are relative to the project root (AIAgentsCourse/). Run pytest from there:

    python3 -m pytest session_2/tests
"""

import ast
import csv
import hashlib
import math
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

# ── Paths (relative to the project root) ─────────────────────────────────
SURVEY_CSV = Path("session_2/data/swiss_franc_survey.csv")
DEMOGRAPHICS_CSV = Path("session_2/data/respondent_demographics.csv")
SCRIPTS_DIR = Path("session_2/scripts")
COMMITTED_OUTPUT_DIR = Path("session_2/output")

PIPELINE_SCRIPTS = ["solution_merge.py", "solution_estimate.py", "solution_robustness.py"]
EXPECTED_OUTPUT_FILES = [
    "merged_survey.csv",
    "summary_stats.tex",
    "main_table.tex",
    "robustness_table.tex",
]

# ── Numerical checks recorded for the audit report ───────────────────────
NUMERIC_CHECKS = []


def assert_close_and_record(name, pipeline_value, independent_value, tolerance):
    """Record a pipeline-vs-independent comparison for the audit report, then assert it.

    The comparison is recorded BEFORE the assertion so that a failing check still
    appears in the report with both values.
    """
    difference = abs(pipeline_value - independent_value)
    NUMERIC_CHECKS.append(
        {
            "name": name,
            "pipeline": pipeline_value,
            "independent": independent_value,
            "difference": difference,
            "tolerance": tolerance,
        }
    )
    assert difference <= tolerance, (
        f"{name}: pipeline {pipeline_value:.6f} vs independent {independent_value:.6f} "
        f"(difference {difference:.2e} > tolerance {tolerance:.0e})"
    )


# ── Raw data readers (csv module; no pandas parsing) ─────────────────────
def read_csv_rows(path):
    """Return the rows of a CSV file as a list of {column: text} dictionaries."""
    with open(path, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def to_float(text):
    """Convert CSV text to float; an empty field becomes NaN."""
    return float("nan") if text == "" else float(text)


def sha256_of_file(path):
    """Return the SHA-256 hex digest of a file, for before/after comparisons."""
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


# ── Independent merge oracle ─────────────────────────────────────────────
SURVEY_NUMERIC_COLUMNS = [
    "respondent_id", "supports_intervention", "age", "female",
    "ed_level", "urban_rural", "survey_weight",
]
DEMOGRAPHICS_NUMERIC_COLUMNS = ["income_quintile", "left_right"]


def expected_merged_frame(survey_path=SURVEY_CSV, demographics_path=DEMOGRAPHICS_CSV):
    """Rebuild the left join of survey onto demographics without pandas.merge.

    Semantics match a SQL / pandas left join: every survey row is kept, a survey row
    with no match gets empty demographics, and a survey row with k matches is
    repeated k times (so duplicate keys in the demographics file multiply rows).
    """
    survey_rows = read_csv_rows(survey_path)
    demographics_rows = read_csv_rows(demographics_path)

    demographics_by_id = defaultdict(list)
    for demographics_row in demographics_rows:
        demographics_by_id[demographics_row["respondent_id"]].append(demographics_row)

    joined_rows = []
    for survey_row in survey_rows:
        matches = demographics_by_id.get(survey_row["respondent_id"], [None])
        for match in matches:
            joined = dict(survey_row)
            for column in DEMOGRAPHICS_NUMERIC_COLUMNS:
                joined[column] = match[column] if match is not None else ""
            joined_rows.append(joined)

    frame = pd.DataFrame(joined_rows)
    for column in SURVEY_NUMERIC_COLUMNS + DEMOGRAPHICS_NUMERIC_COLUMNS:
        frame[column] = frame[column].map(to_float)
    # Text columns: empty string means missing, as in the raw files
    for column in ["govt_intervention", "fx_status"]:
        frame[column] = frame[column].replace("", np.nan)
    return frame


def check_merged_matches_oracle(merged, expected):
    """Raise AssertionError if `merged` differs from the oracle join in any cell.

    Compares row count, column set, and every cell (numeric columns within 1e-9,
    because a CSV round trip can change the last bit of a float). Rows are matched
    by position after sorting on respondent_id, so a reordering alone is not an error.
    """
    assert len(merged) == len(expected), (
        f"row count: pipeline {len(merged)} vs oracle {len(expected)}"
    )
    assert set(merged.columns) == set(expected.columns), (
        f"column sets differ: {set(merged.columns) ^ set(expected.columns)}"
    )

    sort_key = ["respondent_id"]
    left = merged.sort_values(sort_key, kind="mergesort").reset_index(drop=True)
    right = expected.sort_values(sort_key, kind="mergesort").reset_index(drop=True)

    for column in sorted(expected.columns):
        left_values, right_values = left[column], right[column]
        if column in SURVEY_NUMERIC_COLUMNS + DEMOGRAPHICS_NUMERIC_COLUMNS:
            agree = np.isclose(
                left_values.astype(float), right_values.astype(float),
                rtol=0, atol=1e-9, equal_nan=True,
            )
        else:
            agree = (left_values.fillna("<NA>") == right_values.fillna("<NA>")).to_numpy()
        if not agree.all():
            bad_ids = left.loc[~agree, "respondent_id"].astype(int).tolist()[:5]
            raise AssertionError(
                f"column '{column}' differs from the oracle in {int((~agree).sum())} "
                f"cells (first respondent_ids: {bad_ids})"
            )


# ── Independent estimator: weighted logistic regression by IRLS ──────────
@dataclass
class OracleFit:
    """Result of an oracle regression: the estimation sample size and named results."""

    n: int
    coefficients: dict
    standard_errors: dict
    p_values: dict


def weighted_logit_irls(design, outcome, weights, tolerance=1e-10, max_iterations=100):
    """Fit a weighted logistic regression by iteratively reweighted least squares.

    The weights are treated as frequency weights, which is what the pipeline's
    statsmodels call does (freq_weights): the score equations are
    sum_i w_i * (y_i - mu_i) * x_i = 0 and the covariance is inv(X' W V X) with
    V = mu * (1 - mu). Returns (coefficients, standard_errors).
    """
    X = np.asarray(design, dtype=float)
    y = np.asarray(outcome, dtype=float)
    w = np.asarray(weights, dtype=float)

    beta = np.zeros(X.shape[1])
    for _ in range(max_iterations):
        eta = X @ beta
        mu = 1.0 / (1.0 + np.exp(-eta))
        variance = mu * (1.0 - mu)
        working_weight = w * variance
        working_response = eta + (y - mu) / variance
        information = X.T @ (working_weight[:, None] * X)
        updated = np.linalg.solve(information, X.T @ (working_weight * working_response))
        converged = np.max(np.abs(updated - beta)) < tolerance
        beta = updated
        if converged:
            break
    else:
        raise RuntimeError("IRLS did not converge")

    mu = 1.0 / (1.0 + np.exp(-(X @ beta)))
    information = X.T @ ((w * mu * (1.0 - mu))[:, None] * X)
    standard_errors = np.sqrt(np.diag(np.linalg.inv(information)))
    return beta, standard_errors


def two_sided_normal_p(z_statistic):
    """Two-sided p-value from a standard normal z statistic."""
    return math.erfc(abs(z_statistic) / math.sqrt(2.0))


def fit_oracle_spec(frame, *, pooled_treatment=False, fx=True, controls=(),
                    weighted=True, row_filter=None):
    """Fit one specification independently, from a merged data frame.

    Parameters mirror the pipeline's specifications:
        pooled_treatment: one 'any information' dummy instead of three arm dummies
        fx: include current/past FX-loan dummies (reference: no FX loan)
        controls: numeric control columns, entered linearly
        weighted: use survey_weight (frequency-weight semantics) or all ones
        row_filter: optional function frame -> boolean mask, applied BEFORE the
                    complete-case restriction

    The estimation sample is the complete cases on every variable in the model.
    """
    data = frame if row_filter is None else frame[row_filter(frame)]

    needed = ["supports_intervention", "survey_weight", "treatment"]
    if fx:
        needed.append("fx_status")
    needed.extend(controls)
    complete = data.dropna(subset=needed)

    columns = {"Intercept": np.ones(len(complete))}
    if pooled_treatment:
        columns["any_info"] = (complete["treatment"] != "cntrl").astype(float).to_numpy()
    else:
        for arm in ["info", "history", "Hungary"]:
            columns[arm] = (complete["treatment"] == arm).astype(float).to_numpy()
    if fx:
        columns["fx_current"] = (complete["fx_status"] == "current").astype(float).to_numpy()
        columns["fx_past"] = (complete["fx_status"] == "past").astype(float).to_numpy()
    for control in controls:
        columns[control] = complete[control].astype(float).to_numpy()

    names = list(columns)
    design = np.column_stack([columns[name] for name in names])
    weights = (complete["survey_weight"].to_numpy(dtype=float) if weighted
               else np.ones(len(complete)))
    beta, standard_errors = weighted_logit_irls(
        design, complete["supports_intervention"].to_numpy(dtype=float), weights
    )
    return OracleFit(
        n=len(complete),
        coefficients=dict(zip(names, beta)),
        standard_errors=dict(zip(names, standard_errors)),
        p_values={n: two_sided_normal_p(b / s) for n, b, s in zip(names, beta, standard_errors)},
    )


DEMOGRAPHIC_CONTROLS = ("age", "female", "ed_level", "urban_rural")
ALL_CONTROLS = DEMOGRAPHIC_CONTROLS + ("income_quintile", "left_right")

# Specifications of solution_robustness.py, defined independently of that script
ROBUSTNESS_ORACLE_SPECS = {
    "(1)": dict(fx=False, weighted=True),
    "(2)": dict(fx=False, weighted=False),
    "(3)": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS),
    "(4)": dict(fx=True, controls=ALL_CONTROLS),
    "(5)": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS, pooled_treatment=True),
    "(6)": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS, row_filter=lambda f: f["urban_rural"] >= 2),
}

# Models of solution_estimate.py (label as printed in its summary), same independence
ESTIMATE_ORACLE_MODELS = {
    "Treatment only": dict(fx=False),
    "+ FX exposure": dict(fx=True),
    "+ age, female, ed, urban": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS),
    "+ income_quintile": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS + ("income_quintile",)),
    "+ left_right": dict(fx=True, controls=DEMOGRAPHIC_CONTROLS + ("left_right",)),
    "+ both income & LR": dict(fx=True, controls=ALL_CONTROLS),
}

# ── Running the pipeline in an isolated workspace ────────────────────────
def build_workspace(destination, survey_csv=SURVEY_CSV, demographics_csv=DEMOGRAPHICS_CSV):
    """Create <destination>/session_2/{data,scripts,output} and return `destination`.

    The solution scripts use hardcoded relative paths ('session_2/...'), so they are
    run with `destination` as the working directory. This keeps the committed
    session_2/output files untouched. The data files can be swapped for modified
    copies (fault injection); the originals are never edited.
    """
    destination = Path(destination)
    data_dir = destination / "session_2" / "data"
    scripts_dir = destination / "session_2" / "scripts"
    output_dir = destination / "session_2" / "output"
    for directory in (data_dir, scripts_dir, output_dir):
        directory.mkdir(parents=True, exist_ok=True)

    shutil.copy(survey_csv, data_dir / "swiss_franc_survey.csv")
    shutil.copy(demographics_csv, data_dir / "respondent_demographics.csv")
    shutil.copy(Path("session_2/data/PLN_CHF_EUR_FXdata.csv"), data_dir / "PLN_CHF_EUR_FXdata.csv")
    for script_name in PIPELINE_SCRIPTS:
        shutil.copy(SCRIPTS_DIR / script_name, scripts_dir / script_name)
    return destination


def run_script(workspace, script_name):
    """Run one pipeline script with the workspace as working directory."""
    return subprocess.run(
        [sys.executable, f"session_2/scripts/{script_name}"],
        cwd=workspace, capture_output=True, text=True, timeout=300,
    )


def run_pipeline(workspace):
    """Run merge, estimate, robustness in order; return {script_name: CompletedProcess}."""
    return {name: run_script(workspace, name) for name in PIPELINE_SCRIPTS}


# ── Loading functions from a script without executing the script ─────────
def load_functions_from_script(script_path, function_names):
    """Return the named top-level functions of a script, without running the script.

    The solution scripts execute at import (they read data and write files), so
    they cannot be imported. This parses the file, keeps only the requested
    function definitions, and executes just those.
    """
    import statsmodels.api as sm
    import statsmodels.formula.api as smf

    tree = ast.parse(Path(script_path).read_text(encoding="utf-8"))
    selected = [
        node for node in tree.body
        if isinstance(node, ast.FunctionDef) and node.name in function_names
    ]
    found = {node.name for node in selected}
    assert found == set(function_names), f"functions not found in {script_path}: {set(function_names) - found}"
    namespace = {"np": np, "pd": pd, "sm": sm, "smf": smf}
    exec(compile(ast.Module(body=selected, type_ignores=[]), str(script_path), "exec"), namespace)
    return {name: namespace[name] for name in function_names}


# ── Parsers for pipeline stdout and LaTeX output ─────────────────────────
def parse_estimate_summary_n(stdout):
    """Return {model label: N} from the SUMMARY block of solution_estimate.py."""
    block = stdout.split("SUMMARY: THE MISSING DATA TRAP", 1)[1]
    pairs = re.findall(r"^\s{2}(\S.*?)\s+N = (\d+)\s*$", block, flags=re.MULTILINE)
    return {label: int(n) for label, n in pairs}


def parse_estimate_coefficients(stdout, model_label_prefix):
    """Return {parameter name: (coef, se, z, p)} for the model whose header starts with the prefix."""
    segments = stdout.split("MODEL: ")[1:]
    matching = [s for s in segments if s.startswith(model_label_prefix)]
    assert len(matching) == 1, f"expected one model block starting '{model_label_prefix}', found {len(matching)}"
    row = re.compile(
        r"^(\S.*?)\s+(-?\d+\.\d+)\s+(\d+\.\d+)\s+(-?\d+\.\d+)\s+(\d+\.\d+)\s+-?\d+\.\d+\s+-?\d+\.\d+\s*$",
        flags=re.MULTILINE,
    )
    return {
        name.strip(): (float(c), float(se), float(z), float(p))
        for name, c, se, z, p in row.findall(matching[0])
    }


def parse_robustness_n(stdout):
    """Return {'(1)': N, ...} from the 'N=' lines printed by solution_robustness.py."""
    pairs = re.findall(r"^(\(\d\)) .+?\s+N=(\d+)\s*$", stdout, flags=re.MULTILINE)
    return {key: int(n) for key, n in pairs}


def parse_robustness_info_rows(stdout):
    """Return {'(1)': (N, info_coef, info_p)} from the treatment-effects table (specs with an info term)."""
    rows = re.findall(
        r"^(\(\d\))\s+.+?\s+(\d+)\s+(-?\d+\.\d+)\s+(\d+\.\d+)\s*$", stdout, flags=re.MULTILINE
    )
    return {key: (int(n), float(c), float(p)) for key, n, c, p in rows}


def latex_row_cells(tex, row_label, line_offset=0):
    """Return the raw text of each data cell (everything after the first '&') of a LaTeX row.

    The row is the line starting with row_label. line_offset=1 reads the line below it
    (the standard-error row under a coefficient row).
    """
    lines = tex.splitlines()
    index = next(i for i, line in enumerate(lines) if line.lstrip().startswith(row_label))
    return lines[index + line_offset].split("&")[1:]


def latex_row_numbers(tex, row_label, line_offset=0):
    """Return the first number in each data cell of a LaTeX row (None for an empty cell)."""
    numbers = []
    for cell in latex_row_cells(tex, row_label, line_offset):
        match = re.search(r"-?\d+(?:\.\d+)?", cell)
        numbers.append(float(match.group()) if match else None)
    return numbers


def stars_for_p_value(p_value):
    """Significance stars by the convention printed in the table footnotes."""
    return "***" if p_value < 0.01 else "**" if p_value < 0.05 else "*" if p_value < 0.1 else ""
