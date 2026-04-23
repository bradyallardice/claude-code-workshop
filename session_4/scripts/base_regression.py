"""
Module 4: Base Regression Analysis
Estimating treatment effects on government intervention support.

Two models:
1. Weighted logit: supports_intervention ~ treatment (reference='cntrl')
2. Weighted logit with moderation: supports_intervention ~ treatment * fx_status

Includes step-by-step data validation, sample size reporting, and model summaries.
"""

import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf


# ── Load data ────────────────────────────────────────────────────────
df = pd.read_csv("session_3/output/merged_survey.csv")

# ── Data validation block ────────────────────────────────────────────
print("\n" + "=" * 65)
print("DATA VALIDATION")
print("=" * 65)
print(f"Total rows loaded: {len(df):,}")

print("\nOutcome variable (supports_intervention):")
print(df["supports_intervention"].value_counts(dropna=False))

print("\nTreatment variable:")
print(df["treatment"].value_counts(dropna=False))

print("\nFX status variable:")
print(df["fx_status"].value_counts(dropna=False))

print("\nSurvey weight (descriptive statistics):")
print(f"  Min: {df['survey_weight'].min():.3f}")
print(f"  Mean: {df['survey_weight'].mean():.3f}")
print(f"  Max: {df['survey_weight'].max():.3f}")
print("=" * 65)

# ── Set reference categories explicitly ──────────────────────────────
df["treatment"] = pd.Categorical(
    df["treatment"],
    categories=["cntrl", "info", "history", "Hungary"],
)
df["fx_status"] = pd.Categorical(
    df["fx_status"],
    categories=["none", "current", "past"],
)


def run_logit(formula, data, weights=None, label="", description=""):
    """
    Run a weighted logistic regression with full pre-run validation printing.

    Parameters
    ----------
    formula : str
        Patsy formula string for the model
    data : pd.DataFrame
        Data frame containing all variables
    weights : str, optional
        Column name for frequency weights. If None, model is unweighted.
    label : str, optional
        Model label for printing
    description : str, optional
        Extended description of the model

    Returns
    -------
    statsmodels.GLMResults
        Fitted logit model
    """
    # ── Pre-run: announce model ──────────────────────────────────────
    print(f"\n{'=' * 65}")
    print(f"MODEL: {label}")
    if description:
        print(f"Description: {description}")
    print(f"Formula: {formula}")
    print(f"Weight variable: {weights if weights else 'None (unweighted)'}")

    # ── Pre-run: compute eligible N ──────────────────────────────────
    # Extract variables from formula and data to find eligible cases
    # (rows with non-missing on outcome and all predictors)
    outcome_col = formula.split("~")[0].strip()
    eligible = data.dropna(subset=[outcome_col])
    print(f"Eligible N (non-missing outcome): {len(eligible):,}")

    # ── Estimate model ───────────────────────────────────────────────
    if weights is not None:
        model = smf.glm(
            formula,
            data=data,
            family=sm.families.Binomial(),
            freq_weights=data[weights],
        ).fit()
    else:
        model = smf.glm(
            formula,
            data=data,
            family=sm.families.Binomial(),
        ).fit()

    # ── Post-estimation reporting ────────────────────────────────────
    print(f"Actual N used in estimation: {int(model.nobs):,}")
    print(f"Log-likelihood: {model.llf:.4f}")
    print(f"AIC: {model.aic:.4f}")
    print("=" * 65)
    print(model.summary2().tables[1].to_string())

    return model


# ── Model 1: Treatment effect only (weighted) ────────────────────────
m1 = run_logit(
    formula="supports_intervention ~ C(treatment, Treatment('cntrl'))",
    data=df,
    weights="survey_weight",
    label="Model 1: Treatment effect on support for intervention",
    description="Baseline weighted logit. Reference: treatment='cntrl'.",
)

# ── Model 2: Treatment x FX status interaction (weighted) ─────────────
m2 = run_logit(
    formula="supports_intervention ~ C(treatment, Treatment('cntrl')) * C(fx_status, Treatment('none'))",
    data=df,
    weights="survey_weight",
    label="Model 2: Treatment × FX status interaction",
    description="Moderation model. fx_status moderates the treatment effect. "
                "Reference: treatment='cntrl', fx_status='none'.",
)

# ── Summary of sample sizes ──────────────────────────────────────────
print("\n" + "=" * 65)
print("SUMMARY: SAMPLE SIZES ACROSS MODELS")
print("=" * 65)
models = {
    "Model 1 (treatment only)": m1,
    "Model 2 (treatment × fx_status)": m2,
}
for name, m in models.items():
    print(f"  {name:40s} N = {int(m.nobs):,}")
print("=" * 65)
