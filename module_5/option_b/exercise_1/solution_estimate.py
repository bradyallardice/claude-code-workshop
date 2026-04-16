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

# ── Export summary statistics table ──────────────────────────────
summary_vars = {
    "supports_intervention": "Supports intervention (0/1)",
    "age": "Age (years)",
    "female": "Female (0/1)",
    "ed_level": "Education level (1--5)",
    "urban_rural": "Urban--rural (1--5)",
    "income_quintile": "Income quintile (1--5)",
    "left_right": "Left--right placement (0--10)",
}

df["fx_current"] = (df["fx_status"] == "current").astype(int)
df["fx_past"] = (df["fx_status"] == "past").astype(int)
summary_vars["fx_current"] = "FX exposed, current (0/1)"
summary_vars["fx_past"] = "FX exposed, past (0/1)"

summary_latex = r"""\begin{tabular}{lrrrrr}
\toprule
Variable & N & Mean & SD & Min & Max \\
\midrule
"""
for var, label in summary_vars.items():
    s = df[var].dropna()
    summary_latex += (
        f"{label} & {len(s)} & {s.mean():.2f} & {s.std():.2f} "
        f"& {s.min():.2f} & {s.max():.2f} \\\\\n"
    )
summary_latex += "\\bottomrule\n\\end{tabular}\n"

with open("module_5/option_b/exercise_2/tables/summary_stats.tex", "w") as f:
    f.write(summary_latex)
print("\n✓ Saved: module_5/option_b/exercise_2/tables/summary_stats.tex")

# ── Export main regression table ─────────────────────────────────
def stars(p):
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.10:
        return "*"
    return ""


# Two columns: treatment-only vs. with FX + demographics
main_latex = r"""\begin{tabular}{lcc}
\toprule
 & (1) & (2) \\
 & \textit{Baseline} & \textit{+ Controls} \\
\midrule
"""

treatment_params = {
    "C(treatment, Treatment('cntrl'))[T.info]": "Info treatment",
    "C(treatment, Treatment('cntrl'))[T.history]": "History treatment",
    "C(treatment, Treatment('cntrl'))[T.Hungary]": "Hungary treatment",
}
for param, label in treatment_params.items():
    c1, s1, p1 = m1.params.get(param, np.nan), m1.bse.get(param, np.nan), m1.pvalues.get(param, np.nan)
    c2, s2, p2 = m3a.params.get(param, np.nan), m3a.bse.get(param, np.nan), m3a.pvalues.get(param, np.nan)
    main_latex += f"{label} & ${c1:.3f}^{{{stars(p1)}}}$ & ${c2:.3f}^{{{stars(p2)}}}$ \\\\\n"
    main_latex += f" & $({s1:.3f})$ & $({s2:.3f})$ \\\\[0.3em]\n"

fx_params = {
    "C(fx_status, Treatment('none'))[T.current]": "FX exposed (current)",
    "C(fx_status, Treatment('none'))[T.past]": "FX exposed (past)",
}
for param, label in fx_params.items():
    if param in m3a.params:
        c, s, p = m3a.params[param], m3a.bse[param], m3a.pvalues[param]
        main_latex += f"{label} & & ${c:.3f}^{{{stars(p)}}}$ \\\\\n"
        main_latex += f" & & $({s:.3f})$ \\\\[0.3em]\n"

main_latex += (
    "\\midrule\n"
    "Demographic controls & No & Yes \\\\\n"
    "Survey weights & Yes & Yes \\\\\n"
    f"N & {int(m1.nobs)} & {int(m3a.nobs)} \\\\\n"
    "\\bottomrule\n"
    "\\multicolumn{3}{l}{\\scriptsize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.} \\\\\n"
    "\\end{tabular}\n"
)

with open("module_3/output/main_table.tex", "w") as f:
    f.write(main_latex)
print("✓ Saved: module_3/output/main_table.tex")
