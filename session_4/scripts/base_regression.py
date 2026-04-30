"""
Module 4: Base Regression Analysis
Estimating treatment effects on government intervention support.

Two models:
1. Weighted logit: supports_intervention ~ treatment (reference='cntrl')
2. Weighted logit with moderation: supports_intervention ~ treatment * fx_status

Includes step-by-step data validation, sample size reporting, and model summaries.
"""

import os

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

# ── Additional specs for the main results table ──────────────────────
# Spec 1 = m1 (pooled, weighted)
# Spec 2: weighted with additive fx_status controls (not the interaction in m2)
m_spec2 = run_logit(
    formula="supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none'))",
    data=df,
    weights="survey_weight",
    label="Spec 2: Treatment + fx_status controls (weighted)",
    description="Weighted logit with additive fx_status controls.",
)

# Spec 3: unweighted pooled
m_spec3 = run_logit(
    formula="supports_intervention ~ C(treatment, Treatment('cntrl'))",
    data=df,
    weights=None,
    label="Spec 3: Treatment effect (unweighted)",
    description="Unweighted baseline logit.",
)

# ── Summary of sample sizes ──────────────────────────────────────────
print("\n" + "=" * 65)
print("SUMMARY: SAMPLE SIZES ACROSS MODELS")
print("=" * 65)
models = {
    "Model 1 (treatment only, weighted)": m1,
    "Model 2 (treatment × fx_status)": m2,
    "Spec 2 (treatment + fx_status, weighted)": m_spec2,
    "Spec 3 (treatment only, unweighted)": m_spec3,
}
for name, m in models.items():
    print(f"  {name:42s} N = {int(m.nobs):,}")
print("=" * 65)


# ── Long-format CSV for the latex-regression-table skill ─────────────
# Reports the treatment[Hungary] coefficient across three specs.
HUNGARY_COEF = "C(treatment, Treatment('cntrl'))[T.Hungary]"

# True row counts (model.nobs with freq_weights returns sum of weights, not N).
n_pooled = len(df.dropna(subset=["supports_intervention", "treatment"]))
n_with_fx = len(df.dropna(subset=["supports_intervention", "treatment", "fx_status"]))

specs = [
    # (spec_id, label, model, weighted?, has_fx_controls?, n)
    ("pooled",     "Pooled (weighted)",       m1,      True,  False, n_pooled),
    ("with_fx",    "Weighted + FX Controls",  m_spec2, True,  True,  n_with_fx),
    ("unweighted", "Unweighted",              m_spec3, False, False, n_pooled),
]

rows = []

# spec_label rows
for i, (spec, label, *_rest) in enumerate(specs, start=1):
    rows.append({"row_type": "spec_label", "display_order": i, "spec": spec,
                 "value_str": label})

# fe_label rows (used here for non-FE indicators: weights + controls)
rows.append({"row_type": "fe_label", "display_order": 1,
             "value_str": "Survey Weights", "fe_name": "weights"})
rows.append({"row_type": "fe_label", "display_order": 2,
             "value_str": "FX Status Controls", "fe_name": "fx_controls"})

# coefficient rows
for spec, _label, model, *_rest in specs:
    rows.append({
        "row_type": "coefficient", "display_order": 1, "spec": spec,
        "dv": "supports_intervention", "dv_label": "Supports Intervention",
        "coef_type": "hungary",
        "coef": float(model.params[HUNGARY_COEF]),
        "se": float(model.bse[HUNGARY_COEF]),
        "pvalue": float(model.pvalues[HUNGARY_COEF]),
    })

# fe_indicator rows
for spec, _label, _model, weighted, fx, _n in specs:
    rows.append({"row_type": "fe_indicator", "display_order": 1, "spec": spec,
                 "value_str": "yes" if weighted else "no", "fe_name": "weights"})
    rows.append({"row_type": "fe_indicator", "display_order": 2, "spec": spec,
                 "value_str": "yes" if fx else "no", "fe_name": "fx_controls"})

# n rows
for i, (spec, *_mid, n) in enumerate(specs, start=1):
    rows.append({"row_type": "n", "display_order": i, "spec": spec,
                 "value_num": n})

# years rows (required by the skill — temporal coverage of the sample)
years_min = pd.to_datetime(df["interview_date"]).dt.year.min()
years_max = pd.to_datetime(df["interview_date"]).dt.year.max()
years_str = f"{years_min}" if years_min == years_max else f"{years_min}–{years_max}"
for i, (spec, *_rest) in enumerate(specs, start=1):
    rows.append({"row_type": "years", "display_order": i, "spec": spec,
                 "value_str": years_str})

# note row
rows.append({
    "row_type": "note", "display_order": 1,
    "value_str": ("Logit coefficients on the Hungary treatment indicator "
                  "(reference: control). Standard errors in parentheses."),
})

CSV_COLUMNS = ["row_type", "display_order", "spec", "dv", "dv_label",
               "coef_type", "coef", "se", "pvalue", "value_num",
               "value_str", "fe_name"]
tab = pd.DataFrame(rows).reindex(columns=CSV_COLUMNS)

os.makedirs("session_4/demo_output", exist_ok=True)
out_csv = "session_4/demo_output/tab_main.csv"
tab.to_csv(out_csv, index=False)
print(f"\nWrote table CSV to {out_csv}")
