"""
Merge swiss franc survey responses with respondent demographics.

Joins swiss_franc_survey.csv (2,044 respondents) with respondent_demographics.csv
on respondent_id using a left join, preserving all survey rows.
Output: session_2/output/survey_merged.csv
Run from project root: python session_2/scripts/merge_survey_demographics.py
"""

import pandas as pd
from pathlib import Path


def merge_survey_demographics():
    survey_path = Path("session_2/data/swiss_franc_survey.csv")
    demo_path = Path("session_2/data/respondent_demographics.csv")

    for p in [survey_path, demo_path]:
        if not p.exists():
            raise FileNotFoundError(f"Input file not found: {p}")

    print("Loading survey data...")
    survey = pd.read_csv(survey_path)
    print(f"  {len(survey)} survey rows, {survey['respondent_id'].nunique()} unique respondents")

    print("Loading demographics data...")
    demographics = pd.read_csv(demo_path)
    print(f"  {len(demographics)} demographic rows")

    # Warn if key dtypes differ — a common silent join failure
    if survey["respondent_id"].dtype != demographics["respondent_id"].dtype:
        print(
            f"  WARNING: respondent_id dtype mismatch "
            f"(survey: {survey['respondent_id'].dtype}, "
            f"demographics: {demographics['respondent_id'].dtype}) — coercing to int"
        )
        survey["respondent_id"] = survey["respondent_id"].astype(int)
        demographics["respondent_id"] = demographics["respondent_id"].astype(int)

    # Drop duplicate demographic rows to avoid inflating merged row count
    dupes = demographics["respondent_id"].duplicated().sum()
    if dupes:
        print(f"  WARNING: {dupes} duplicate respondent_ids in demographics — dropping extras")
        demographics = demographics.drop_duplicates(subset="respondent_id")

    print("Merging on respondent_id (left join)...")
    merged = survey.merge(demographics, on="respondent_id", how="left")

    if len(merged) == 0:
        raise ValueError("Merge produced 0 rows — check that respondent_id types match")

    matched = merged["income_quintile"].notna().sum()
    unmatched = len(merged) - matched
    unused = len(demographics) - matched
    print(f"  Matched: {matched}/{len(merged)} respondents have demographic data")
    print(f"  Unmatched survey respondents: {unmatched}")
    print(f"  Unused demographic rows: {unused}")

    out_path = Path("session_2/output/survey_merged.csv")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    merged.to_csv(out_path, index=False)
    print(f"Saved to {out_path} — {len(merged)} rows, {len(merged.columns)} columns")
    return merged


if __name__ == "__main__":
    merged = merge_survey_demographics()
