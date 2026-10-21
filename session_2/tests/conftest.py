"""
Shared fixtures and the audit-report generator for the Session 2 test suite.

Run from the project root (AIAgentsCourse/):

    python3 -m pytest session_2/tests
    python3 -m pytest session_2/tests --audit-report session_2/tests/audit_report.md

The pipeline is run in temporary copies of the project, so the committed files in
session_2/output are never overwritten.
"""

import sys
from collections import defaultdict
from pathlib import Path

import pytest

import helpers

# Registered requirement IDs: what the project must do. Every test is tagged with one.
# These mirror the requirements-to-tests matrix slide.
REQUIREMENTS = {
    "R0": "Raw inputs are valid (keys, types, ranges, codebook consistency)",
    "R1": "Merge keeps every respondent and attaches the right demographics",
    "R2": "Variables are built as defined",
    "R3": "Control is the reference arm",
    "R4": "Survey weights are used and the estimates are right",
    "R5": "N is explained for every model",
    "R6": "Every specification is reported, and tables match the data",
    "R7": "Pipeline runs end to end and fails loudly on bad input",
    "R8": "Pipeline is reproducible from raw inputs",
    "R9": "The checks themselves can fail (fault injection, planted answer)",
}

# Judgments the tests cannot settle. These go in the report, not in assertions.
NEEDS_YOUR_CALL = [
    "Join type: a left join is the only one that keeps all 2,044 respondents without adding "
    "non-respondents. The tests check the pipeline matches that choice; they do not choose it.",
    "`govt_intervention = DK` (230 respondents) is coded 0 in `supports_intervention`, i.e. "
    "'does not support', not missing. That is the codebook's definition, but it is a substantive choice.",
    "`income_quintile = 0` means 'no income' and is kept as a valid value (8 respondents). "
    "The tests check it is not turned into a missing value.",
    "Adding both income and left-right drops about 44% of respondents. The tests reconcile "
    "the drop; whether complete-case analysis is acceptable is a research decision.",
    "Weights are applied as frequency weights (`freq_weights`), so standard errors are not "
    "design-based. The independent estimator reproduces this choice; it does not validate it.",
]

NOT_TESTED = [
    "Only the Python solution pipeline is tested. The Stata (.do) and R versions in "
    "session_2/scripts are not exercised.",
    "Clean-environment installation: dependencies were not reinstalled from scratch.",
    "Manuscript-to-code traceability: there is no manuscript in this session.",
    "Performance and scaling: not relevant at 2,044 rows.",
    "Robustness to alternative specifications beyond the six in the table: that is a research design question.",
    "Treatment x FX interaction model: only its sample size is checked, not its coefficients.",
]

NOT_COVERED = [
    "Identification: the tests do not establish that randomization was implemented as described.",
    "Construct validity: whether `supports_intervention` measures support for intervention.",
    "Whether the specification answers the research question.",
]

# ── Collected during the run, used by the audit report ───────────────────
_requirement_of_test = {}
_outcome_of_test = {}
_xfail_reasons = {}


def pytest_addoption(parser):
    parser.addoption(
        "--audit-report", action="store", default=None,
        help="Write a Markdown audit report to this path after the run.",
    )


def pytest_configure(config):
    config.addinivalue_line("markers", "requirement(id): the project requirement a test supports (R0..R9)")
    if not helpers.SURVEY_CSV.exists():
        raise pytest.UsageError(
            "Run pytest from the project root (AIAgentsCourse/): "
            f"could not find {helpers.SURVEY_CSV}"
        )


def pytest_collection_modifyitems(items):
    """Require every test to carry a registered requirement tag, and remember it."""
    for item in items:
        marker = item.get_closest_marker("requirement")
        if marker is None or marker.args[0] not in REQUIREMENTS:
            raise pytest.UsageError(f"{item.nodeid} needs @pytest.mark.requirement('R0'..'R9')")
        _requirement_of_test[item.nodeid] = marker.args[0]


def pytest_runtest_logreport(report):
    """Record one outcome per test: passed / failed / skipped / xfailed / xpassed."""
    if report.when == "call":
        if hasattr(report, "wasxfail"):
            outcome = "xfailed" if report.skipped else "xpassed"
            _xfail_reasons[report.nodeid] = report.wasxfail
        else:
            outcome = report.outcome
        _outcome_of_test[report.nodeid] = outcome
    elif report.outcome in ("failed", "skipped") and report.when in ("setup", "teardown"):
        _outcome_of_test.setdefault(report.nodeid, "failed" if report.outcome == "failed" else "skipped")


# ── Fixtures ─────────────────────────────────────────────────────────────
@pytest.fixture(scope="session")
def raw_survey():
    """Raw survey rows as a frame, built by the csv-module oracle (merge not applied)."""
    return helpers.expected_merged_frame()[
        ["respondent_id", "interview_date", "treatment", "govt_intervention",
         "supports_intervention", "fx_status", "age", "female", "ed_level",
         "urban_rural", "survey_weight"]
    ]


@pytest.fixture(scope="session")
def oracle_merged():
    """The independently rebuilt left join of survey and demographics."""
    return helpers.expected_merged_frame()


@pytest.fixture(scope="session")
def raw_demographics():
    """Raw demographics file as a frame (csv module, no merge)."""
    import pandas as pd

    frame = pd.DataFrame(helpers.read_csv_rows(helpers.DEMOGRAPHICS_CSV))
    for column in ["respondent_id", "income_quintile", "left_right"]:
        frame[column] = frame[column].map(helpers.to_float)
    return frame


@pytest.fixture(scope="session")
def pipeline_run(tmp_path_factory):
    """Run the three solution scripts once, in an empty temporary workspace.

    Because the workspace starts with only the raw data and the scripts, this is
    also the 'complete rebuild' check: every output must be regenerated from inputs.
    """
    workspace = helpers.build_workspace(tmp_path_factory.mktemp("clean_rebuild"))
    runs = helpers.run_pipeline(workspace)
    return {"workspace": workspace, "runs": runs}


@pytest.fixture(scope="session")
def pipeline_run_repeat(tmp_path_factory):
    """A second, independent run of the pipeline, for the repeatability test."""
    workspace = helpers.build_workspace(tmp_path_factory.mktemp("repeat_run"))
    return {"workspace": workspace, "runs": helpers.run_pipeline(workspace)}


@pytest.fixture(scope="session")
def merged_output(pipeline_run):
    """The merged_survey.csv written by the pipeline's merge step."""
    import pandas as pd

    return pd.read_csv(pipeline_run["workspace"] / "session_2/output/merged_survey.csv")


def read_output_text(pipeline_run, name):
    """Read one of the pipeline's text outputs (e.g. a .tex table)."""
    return (pipeline_run["workspace"] / "session_2/output" / name).read_text(encoding="utf-8")


# ── Audit report ─────────────────────────────────────────────────────────
def pytest_sessionfinish(session, exitstatus):
    report_path = session.config.getoption("--audit-report")
    if report_path:
        Path(report_path).write_text(build_audit_report(session.config), encoding="utf-8")


def build_audit_report(config):
    """Assemble the audit report in the format taught on the audit-report slide."""
    counts = defaultdict(int)
    for outcome in _outcome_of_test.values():
        counts[outcome] += 1

    tests_by_requirement = defaultdict(list)
    for nodeid, requirement in _requirement_of_test.items():
        tests_by_requirement[requirement].append(nodeid)

    lines = ["# Audit report: Session 2 verification suite", ""]

    lines += ["## Tests run", "",
              f"Command: `python3 -m pytest {' '.join(config.invocation_params.args)}`", "",
              f"- passed: {counts['passed']}",
              f"- failed: {counts['failed']}",
              f"- skipped: {counts['skipped']}",
              f"- known issues (xfail): {counts['xfailed']}",
              f"- unexpectedly passing known issues (xpass): {counts['xpassed']}", ""]

    lines += ["## Requirements", "",
              "| Requirement | Description | Tests | Status |", "|---|---|---|---|"]
    for requirement, description in REQUIREMENTS.items():
        nodeids = tests_by_requirement.get(requirement, [])
        outcomes = {_outcome_of_test.get(n, "not run") for n in nodeids}
        if not nodeids:
            status = "NO TEST"
        elif outcomes & {"failed", "xpassed"}:
            status = "FAILING"
        elif "xfailed" in outcomes:
            status = "passing, with known issues"
        elif outcomes == {"passed"}:
            status = "passing"
        else:
            status = ", ".join(sorted(outcomes))
        lines.append(f"| {requirement} | {description} | {len(nodeids)} | {status} |")
    lines.append("")

    lines += ["## Known issues (expected failures)", ""]
    known = {n: r for n, r in _xfail_reasons.items() if _outcome_of_test.get(n) == "xfailed"}
    if known:
        for nodeid, reason in sorted(known.items()):
            lines.append(f"- `{nodeid.split('/')[-1]}`: {reason}")
    else:
        lines.append("None.")
    lines.append("")

    lines += ["## Not tested", ""] + [f"- {item}" for item in NOT_TESTED] + [""]

    lines += ["## Numerical checks (pipeline value vs independent value)", ""]
    if helpers.NUMERIC_CHECKS:
        lines += ["| Check | Pipeline | Independent | Difference | Tolerance |", "|---|---|---|---|---|"]
        for check in helpers.NUMERIC_CHECKS:
            lines.append(
                f"| {check['name']} | {check['pipeline']:.6f} | {check['independent']:.6f} "
                f"| {check['difference']:.1e} | {check['tolerance']:.0e} |"
            )
    else:
        lines.append("None recorded.")
    lines.append("")

    lines += ["## Needs your call", ""] + [f"- {item}" for item in NEEDS_YOUR_CALL] + [""]
    lines += ["## Not covered", "",
              "Passing tests, complete output, and reproducibility do not show that the "
              "research design is valid. In particular:", ""] + [f"- {item}" for item in NOT_COVERED] + [""]
    lines += reproduction_evidence_lines()
    return "\n".join(lines)


def reproduction_evidence_lines():
    """Software versions and input hashes, so the run can be reproduced and compared later."""
    import numpy
    import pandas
    import statsmodels

    return [
        "## Reproduction evidence", "",
        f"- Python {sys.version.split()[0]}, pandas {pandas.__version__}, "
        f"numpy {numpy.__version__}, statsmodels {statsmodels.__version__}",
        f"- {helpers.SURVEY_CSV.name} SHA-256: {helpers.sha256_of_file(helpers.SURVEY_CSV)[:16]}...",
        f"- {helpers.DEMOGRAPHICS_CSV.name} SHA-256: {helpers.sha256_of_file(helpers.DEMOGRAPHICS_CSV)[:16]}...",
        "",
    ]
