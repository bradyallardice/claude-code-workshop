"""
Mutation check for the Session 2 verification suite ("test the tests").

Injects ONE known bug at a time into a scratch copy of the solution scripts and runs the
suite against it. Every bug must make at least one test fail; a bug that no test notices
means the suite has a gap.

The two 'committed output' tests are ignored when counting failures: the scratch copy has no
committed outputs, so those tests would fail for an unrelated reason.

Run from the project root (AIAgentsCourse/):

    python3 session_2/tests/mutation_check.py

Exit code 0 if every bug was caught, 1 otherwise. The repository is never modified.
"""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# name -> (script, text to replace, replacement)
MUTANTS = {
    "inner join instead of left join": (
        "solution_merge.py", 'how="left"', 'how="inner"'),
    "base model fitted without weights": (
        "solution_estimate.py", 'weights="survey_weight",\n    label="Base model', 'weights=None,\n    label="Base model'),
    "wrong reference category (info instead of cntrl)": (
        "solution_estimate.py", "C(treatment, Treatment('cntrl'))\"", "C(treatment, Treatment('info'))\""),
    "main-table N taken from the wrong model": (
        "solution_estimate.py", "int(m3a.nobs)", "int(m3b.nobs)"),
    "significance stars use the wrong threshold": (
        "solution_estimate.py", "if p < 0.01:\n        return \"***\"", "if p < 0.05:\n        return \"***\""),
    "urban filter off by one (>= 3 instead of >= 2)": (
        "solution_robustness.py", 'df["urban_rural"] >= 2', 'df["urban_rural"] >= 3'),
    "income = 0 silently treated as missing": (
        "solution_merge.py", "merged.to_csv(",
        'merged["income_quintile"] = merged["income_quintile"].replace(0, float("nan"))\nmerged.to_csv('),
    "'any information' dummy defined as treatment == info": (
        "solution_robustness.py", '(df["treatment"] != "cntrl").astype(int)', '(df["treatment"] == "info").astype(int)'),
}


def run_suite_on_mutant(scratch_root, script_name, old, new):
    """Copy session_2 to scratch_root, inject one bug, run the suite; return the failing test names."""
    if scratch_root.exists():
        shutil.rmtree(scratch_root)
    shutil.copytree(
        Path("session_2"), scratch_root / "session_2",
        ignore=shutil.ignore_patterns("__pycache__", ".pytest_cache", "docs", "output", "audit_report.md"),
    )
    (scratch_root / "session_2" / "output").mkdir()

    script = scratch_root / "session_2" / "scripts" / script_name
    text = script.read_text(encoding="utf-8")
    assert old in text, f"bug pattern not found in {script_name}: {old!r}"
    script.write_text(text.replace(old, new, 1), encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "-m", "pytest", "session_2/tests", "-q", "-p", "no:cacheprovider", "--no-header", "-rfE"],
        cwd=scratch_root, capture_output=True, text=True,
    )
    failing = re.findall(r"^(?:FAILED|ERROR) .*?::(test_\w+)", result.stdout, flags=re.MULTILINE)
    return sorted({name for name in failing if "committed" not in name})


def main():
    if not Path("session_2/tests/helpers.py").exists():
        sys.exit("Run this from the project root (AIAgentsCourse/).")
    missed = []
    with tempfile.TemporaryDirectory() as scratch:
        for name, (script_name, old, new) in MUTANTS.items():
            failing = run_suite_on_mutant(Path(scratch) / "mutant", script_name, old, new)
            verdict = "caught" if failing else "MISSED"
            print(f"{verdict:7s} {name}  ({len(failing)} tests fail)")
            if not failing:
                missed.append(name)
    print(f"\n{len(MUTANTS) - len(missed)} of {len(MUTANTS)} injected bugs caught.")
    sys.exit(1 if missed else 0)


if __name__ == "__main__":
    main()
