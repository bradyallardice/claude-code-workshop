"""
Session 2 Solution — Part 2: Specify and Estimate
Logistic regression of supports_intervention on treatment,
with progressive addition of controls to demonstrate the missing data trap.
"""

import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf

# ── Load merged data ─────────────────────────────────────────────
df = pd.read_csv("module_3/output/merged_survey.csv")

# ── Set reference categories explicitly ──────────────────────────
df["treatment"] = pd.Categorical(
    df["treatment"],
    categories=["cntrl", "info", "history", "Hungary"],
)
df["fx_status"] = pd.Categorical(
    df["fx_status"],
    categories=["none", "current", "past"],
)


def run_logit(formula, data, weights=None, label=""):
    """Run a logistic regression and print summary."""
    if weights is not None:
        model = smf.glm(
            formula, data=data, family=sm.families.Binomial(),
            freq_weights=data[weights],
        ).fit()
    else:
        model = smf.glm(
            formula, data=data, family=sm.families.Binomial(),
        ).fit()
    print(f"\n{'='*60}")
    print(f"MODEL: {label}")
    print(f"Formula: {formula}")
    print(f"N = {int(model.nobs)}")
    print(f"{'='*60}")
    print(model.summary2().tables[1].to_string())
    return model


# ── Step 4: Base model — treatment only, weighted ────────────────
m1 = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl'))",
    df,
    weights="survey_weight",
    label="Base model (treatment only, weighted)",
)

# ── Step 5: Add FX exposure ──────────────────────────────────────
m2 = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none'))",
    df,
    weights="survey_weight",
    label="+ FX exposure",
)

# ── Step 6: Add demographic controls ─────────────────────────────
# First WITHOUT income and left_right (no additional missingness)
m3a = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none')) + age + female + ed_level + urban_rural",
    df,
    weights="survey_weight",
    label="+ demographics (no income, no left-right)",
)

# Now WITH income_quintile (drops ~525)
m3b = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none')) + age + female + ed_level + urban_rural + income_quintile",
    df,
    weights="survey_weight",
    label="+ income_quintile (THE MISSING DATA TRAP)",
)

# Now WITH left_right (drops ~504)
m3c = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none')) + age + female + ed_level + urban_rural + left_right",
    df,
    weights="survey_weight",
    label="+ left_right",
)

# Now WITH both (drops ~859)
m3d = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) + C(fx_status, Treatment('none')) + age + female + ed_level + urban_rural + income_quintile + left_right",
    df,
    weights="survey_weight",
    label="+ both income_quintile and left_right",
)

# ── Step 7: Interaction — treatment x FX exposure ────────────────
m4 = run_logit(
    "supports_intervention ~ C(treatment, Treatment('cntrl')) * C(fx_status, Treatment('none')) + age + female + ed_level + urban_rural",
    df,
    weights="survey_weight",
    label="Treatment x FX exposure interaction",
)

# ── Summary of sample sizes ──────────────────────────────────────
print("\n" + "=" * 60)
print("SUMMARY: THE MISSING DATA TRAP")
print("=" * 60)
models = {
    "Treatment only": m1,
    "+ FX exposure": m2,
    "+ age, female, ed, urban": m3a,
    "+ income_quintile": m3b,
    "+ left_right": m3c,
    "+ both income & LR": m3d,
    "Treatment x FX interaction": m4,
}
for name, m in models.items():
    print(f"  {name:35s} N = {int(m.nobs)}")
