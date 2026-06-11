"""
Merge swiss_franc_survey.csv con respondent_demographics.csv por respondent_id.
Output: session_2/output/merged.csv
Ejecutar desde la raíz del proyecto: python session_2/scripts/merge_tables.py
"""

import pandas as pd
from pathlib import Path


def merge_tables():
    survey = pd.read_csv("session_2/data/swiss_franc_survey.csv")
    demographics = pd.read_csv("session_2/data/respondent_demographics.csv")

    merged = survey.merge(demographics, on="respondent_id", how="left")

    out_path = Path("session_2/output/merged.csv")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    merged.to_csv(out_path, index=False)
    print(f"Guardado: {out_path} — {len(merged)} filas, {len(merged.columns)} columnas")
    return merged


def validate_merge(survey, demographics, merged):
    print("\n--- Robustness checks ---")

    # 1. Row count: left join must preserve all survey rows
    assert len(merged) == len(survey), (
        f"ERROR: merged tiene {len(merged)} filas pero survey tiene {len(survey)}"
    )
    print(f"  Filas: {len(merged)} (correcto — igual que survey)")

    # 2. No duplicate respondent_ids in merged output
    dupes = merged["respondent_id"].duplicated().sum()
    if dupes:
        print(f"  WARNING: {dupes} respondent_ids duplicados en el resultado")
    else:
        print("  Sin duplicados en respondent_id")

    # 3. Match rate
    matched = merged["income_quintile"].notna().sum()
    unmatched = len(merged) - matched
    print(f"  Con datos demograficos: {matched}/{len(merged)} ({matched/len(merged):.1%})")
    print(f"  Sin match en demographics: {unmatched}")

    # 4. Unused rows in demographics
    unused = len(demographics) - matched
    print(f"  Filas de demographics sin usar: {unused}")

    # 5. Value ranges for demographic columns
    valid_quintiles = merged["income_quintile"].dropna()
    if not valid_quintiles.between(1, 5).all():
        print(f"  WARNING: income_quintile fuera del rango [1, 5]")
    else:
        print(f"  income_quintile: rango válido [1–5]")

    # 6. No missing values in survey-only columns
    survey_cols = ["respondent_id", "interview_date", "treatment", "supports_intervention"]
    for col in survey_cols:
        n_missing = merged[col].isna().sum()
        if n_missing:
            print(f"  WARNING: {n_missing} valores nulos en columna '{col}'")
        else:
            print(f"  {col}: sin nulos")

    print("--- Fin checks ---\n")


if __name__ == "__main__":
    survey = pd.read_csv("session_2/data/swiss_franc_survey.csv")
    demographics = pd.read_csv("session_2/data/respondent_demographics.csv")
    merged = merge_tables()
    validate_merge(survey, demographics, merged)
