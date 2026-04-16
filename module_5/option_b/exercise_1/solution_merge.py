"""
Session 2 Solution — Part 1: Merge and Explore
Merges the survey data with the demographics file using a left join.
"""

import pandas as pd
import numpy as np

# ── Load data ────────────────────────────────────────────────────
survey = pd.read_csv("module_5/option_b/data/swiss_franc_survey.csv")
demog = pd.read_csv("module_5/option_b/data/respondent_demographics.csv")

print("Survey shape:", survey.shape)
print("Demographics shape:", demog.shape)
print(f"Survey unique IDs: {survey['respondent_id'].nunique()}")
print(f"Demographics unique IDs: {demog['respondent_id'].nunique()}")

# ── Merge: left join on respondent_id ────────────────────────────
merged = survey.merge(demog, on="respondent_id", how="left")

# ── Verify the merge ─────────────────────────────────────────────
print("\n=== MERGE VERIFICATION ===")
print(f"Merged shape: {merged.shape}")
assert merged.shape[0] == 2044, f"Expected 2044 rows, got {merged.shape[0]}"
print("Row count: 2,044 (no rows lost or gained)")

assert merged["respondent_id"].nunique() == 2044, "Duplicate respondent IDs!"
print("No duplicate respondent IDs")

# ── Explore the data ─────────────────────────────────────────────
print("\n=== TREATMENT GROUPS ===")
print(merged["treatment"].value_counts().sort_index())

print("\n=== OUTCOME DISTRIBUTION ===")
print(merged["supports_intervention"].value_counts(dropna=False))
print(f"\nUnweighted proportion supporting: {merged['supports_intervention'].mean():.4f}")

weighted_prop = np.average(
    merged["supports_intervention"].dropna(),
    weights=merged.loc[merged["supports_intervention"].notna(), "survey_weight"],
)
print(f"Weighted proportion supporting: {weighted_prop:.4f}")

print("\n=== FX EXPOSURE ===")
print(merged["fx_status"].value_counts(dropna=False))

print("\n=== MISSING DATA ===")
for col in merged.columns:
    n_miss = merged[col].isna().sum()
    if n_miss > 0:
        print(f"  {col}: {n_miss} missing ({n_miss/len(merged)*100:.1f}%)")

print("\n=== INCOME QUINTILE = 0 ===")
print(f"Respondents with income_quintile = 0: {(merged['income_quintile'] == 0).sum()}")

# ── Save ─────────────────────────────────────────────────────────
merged.to_csv("module_3/output/merged_survey.csv", index=False)
print("\nSaved merged data to module_3/output/merged_survey.csv")
