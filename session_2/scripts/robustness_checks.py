"""
Robustness checks on session_2/output/merged.csv.
Run from project root: python session_2/scripts/robustness_checks.py
"""

import pandas as pd

EXPECTED_COLUMNS = [
    "respondent_id", "interview_date", "treatment", "govt_intervention",
    "supports_intervention", "fx_status", "age", "female", "ed_level",
    "urban_rural", "survey_weight", "income_quintile", "left_right",
]


def run_checks(df):
    print("=" * 50)
    print("ROBUSTNESS CHECKS — merged.csv")
    print("=" * 50)

    # 1. Structure
    print("\n[1] Structure")
    print(f"  Shape: {df.shape}")
    missing_cols = [c for c in EXPECTED_COLUMNS if c not in df.columns]
    if missing_cols:
        print(f"  WARNING: missing columns: {missing_cols}")
    else:
        print(f"  All {len(EXPECTED_COLUMNS)} expected columns present")

    # 2. ID uniqueness
    print("\n[2] ID uniqueness")
    dupes = df["respondent_id"].duplicated().sum()
    if dupes:
        print(f"  WARNING: {dupes} duplicate respondent_id values")
    else:
        print("  No duplicate respondent_id")

    # 3. Missing values
    print("\n[3] Missing values")
    for col in df.columns:
        n = df[col].isna().sum()
        pct = n / len(df)
        flag = "  WARNING" if pct > 0.10 else "        "
        print(f"  {flag} {col}: {n} missing ({pct:.1%})")

    # 4. Value ranges
    print("\n[4] Value ranges")
    checks = [
        ("age",             lambda s: s.between(18, 100),   "18–100"),
        ("female",          lambda s: s.isin([0, 1]),        "{0, 1}"),
        ("ed_level",        lambda s: s.between(1, 4),       "1–4"),
        ("urban_rural",     lambda s: s.between(1, 3),       "1–3"),
        ("income_quintile", lambda s: s.between(1, 5),       "1–5"),
        ("left_right",      lambda s: s.between(-3, 3),      "-3–3"),
        ("survey_weight",   lambda s: s > 0,                 "> 0"),
    ]
    for col, rule, label in checks:
        valid = rule(df[col].dropna())
        n_bad = (~valid).sum()
        if n_bad:
            print(f"  WARNING: {col} — {n_bad} values outside [{label}]")
        else:
            print(f"  {col}: all values in [{label}]")

    # 5. Treatment balance
    print("\n[5] Treatment balance")
    counts = df["treatment"].value_counts()
    max_n = counts.max()
    for arm, n in counts.items():
        flag = "  WARNING" if n < max_n * 0.80 else "        "
        print(f"  {flag} {arm}: {n}")

    # 6. Demographic coverage by treatment arm
    print("\n[6] Demographic coverage by treatment arm")
    coverage = df.groupby("treatment")["income_quintile"].apply(
        lambda s: s.notna().mean()
    )
    max_cov = coverage.max()
    min_cov = coverage.min()
    for arm, pct in coverage.items():
        flag = "  WARNING" if (max_cov - pct) > 0.10 else "        "
        print(f"  {flag} {arm}: {pct:.1%} matched")
    if (max_cov - min_cov) > 0.10:
        print(f"  WARNING: coverage varies {max_cov - min_cov:.1%} across arms — may bias analysis")
    else:
        print(f"  Coverage spread: {max_cov - min_cov:.1%} (within 10pp threshold)")

    print("\n" + "=" * 50)


if __name__ == "__main__":
    df = pd.read_csv("session_2/output/merged.csv")
    run_checks(df)
