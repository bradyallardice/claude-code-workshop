"""
Session 2 Solution — Part 3: Robustness Checks and LaTeX Table
Generates specification variants and outputs a publication-style LaTeX table.
"""

import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf

# ── Load merged data ─────────────────────────────────────────────
df = pd.read_csv("session_5/option_b/output/merged_survey.csv")

# Set reference categories
df["treatment"] = pd.Categorical(
    df["treatment"],
    categories=["cntrl", "info", "history", "Hungary"],
)
df["fx_status"] = pd.Categorical(
    df["fx_status"],
    categories=["none", "current", "past"],
)

# Create derived variables
df["any_info"] = (df["treatment"] != "cntrl").astype(int)

# Complete cases subset (constant N across all specifications)
complete_cols = [
    "supports_intervention", "treatment", "fx_status",
    "age", "female", "ed_level", "urban_rural",
    "income_quintile", "left_right", "survey_weight",
]
df_complete = df.dropna(subset=complete_cols).copy()
print(f"Complete cases: {len(df_complete)}")


# ── Helper ───────────────────────────────────────────────────────
def fit_logit(formula, data, weights=None):
    """Fit logistic regression, return model object."""
    kwargs = {"family": sm.families.Binomial()}
    if weights:
        kwargs["freq_weights"] = data[weights]
    return smf.glm(formula, data=data, **kwargs).fit()


# ── Define specifications ────────────────────────────────────────
treat = "C(treatment, Treatment('cntrl'))"
fx3 = "C(fx_status, Treatment('none'))"
demog = "age + female + ed_level + urban_rural"
full = "age + female + ed_level + urban_rural + income_quintile + left_right"

specs = {
    "(1)": {
        "formula": f"supports_intervention ~ {treat}",
        "data": df, "weights": "survey_weight",
        "label": "Base (weighted)",
    },
    "(2)": {
        "formula": f"supports_intervention ~ {treat}",
        "data": df, "weights": None,
        "label": "Base (unweighted)",
    },
    "(3)": {
        "formula": f"supports_intervention ~ {treat} + {fx3} + {demog}",
        "data": df, "weights": "survey_weight",
        "label": "+ Controls",
    },
    "(4)": {
        "formula": f"supports_intervention ~ {treat} + {fx3} + {full}",
        "data": df, "weights": "survey_weight",
        "label": "Full controls",
    },
    "(5)": {
        "formula": "supports_intervention ~ any_info + {fx3} + {demog}".format(fx3=fx3, demog=demog),
        "data": df, "weights": "survey_weight",
        "label": "Pooled treatment",
    },
    "(6)": {
        "formula": f"supports_intervention ~ {treat} + {fx3} + {demog}",
        "data": df[df["urban_rural"] >= 2], "weights": "survey_weight",
        "label": "Urban only",
    },
}

# ── Fit all models ───────────────────────────────────────────────
models = {}
for name, spec in specs.items():
    m = fit_logit(spec["formula"], spec["data"], spec["weights"])
    models[name] = m
    print(f"{name} {spec['label']:20s} N={int(m.nobs)}")

# ── Key coefficients for comparison ──────────────────────────────
print("\n=== TREATMENT EFFECTS ACROSS SPECIFICATIONS ===")
print(f"{'Spec':6s} {'Label':20s} {'N':>6s}  {'Info coef':>10s} {'Info p':>8s}")
print("-" * 60)

for name, spec in specs.items():
    m = models[name]
    info_key = [k for k in m.params.index if "info" in k.lower()]
    if info_key:
        coef = m.params[info_key[0]]
        p = m.pvalues[info_key[0]]
        print(f"{name:6s} {spec['label']:20s} {int(m.nobs):6d}  {coef:10.4f} {p:8.4f}")
    else:
        print(f"{name:6s} {spec['label']:20s} {int(m.nobs):6d}  {'N/A':>10s}")


# ── Generate LaTeX table ─────────────────────────────────────────
def coef_str(model, param_substr):
    """Extract coefficient and SE as formatted strings with significance stars."""
    for key in model.params.index:
        if param_substr in key:
            coef = model.params[key]
            se = model.bse[key]
            p = model.pvalues[key]
            stars = "***" if p < 0.01 else "**" if p < 0.05 else "*" if p < 0.1 else ""
            return f"${coef:.3f}{stars}$", f"$({se:.3f})$"
    return "", ""


# Row definitions: (label, param substring, [include per column])
#                                                  (1)    (2)    (3)    (4)    (5)    (6)
rows = [
    ("Info treatment",         "T.info]",         [True,  True,  True,  True,  False, True]),
    ("History treatment",      "T.history]",      [True,  True,  True,  True,  False, True]),
    ("Hungary treatment",      "T.Hungary]",      [True,  True,  True,  True,  False, True]),
    ("Any information",        "any_info",        [False, False, False, False, True,  False]),
    ("FX exposed (current)",   "T.current]",      [False, False, True,  True,  True,  True]),
    ("FX exposed (past)",      "T.past]",         [False, False, True,  True,  True,  True]),
]

model_keys = ["(1)", "(2)", "(3)", "(4)", "(5)", "(6)"]

latex_lines = []
latex_lines.append(r"\begin{table}[htbp]")
latex_lines.append(r"\centering")
latex_lines.append(r"\caption{Logistic Regression: Support for Government Intervention}")
latex_lines.append(r"\label{tab:robustness}")
latex_lines.append(r"\small")
latex_lines.append(r"\begin{tabular}{l" + "c" * len(model_keys) + "}")
latex_lines.append(r"\toprule")

# Header
header = " & ".join(model_keys)
latex_lines.append(f" & {header} \\\\")

# Sub-header with labels
sublabels = [specs[k]["label"] for k in model_keys]
subheader = " & ".join([f"\\scriptsize {l}" for l in sublabels])
latex_lines.append(f" & {subheader} \\\\")
latex_lines.append(r"\midrule")

# Coefficient rows
for row_label, param_key, include_flags in rows:
    coef_cells = []
    se_cells = []
    for i, mk in enumerate(model_keys):
        if include_flags[i]:
            c, s = coef_str(models[mk], param_key)
            coef_cells.append(c)
            se_cells.append(s)
        else:
            coef_cells.append("")
            se_cells.append("")
    latex_lines.append(f"{row_label} & " + " & ".join(coef_cells) + r" \\")
    latex_lines.append(f" & " + " & ".join(se_cells) + r" \\[0.3em]")

latex_lines.append(r"\midrule")

# Controls row
controls_row = ["No", "No", "Yes", "Yes", "Yes", "Yes"]
latex_lines.append("Demographic controls & " + " & ".join(controls_row) + r" \\")

# Weights row
weights_row = ["Yes", "No", "Yes", "Yes", "Yes", "Yes"]
latex_lines.append("Survey weights & " + " & ".join(weights_row) + r" \\")

# Sample row
sample_row = ["Full", "Full", "Full", "Full", "Full", "Urban"]
latex_lines.append("Sample & " + " & ".join(sample_row) + r" \\")

# N row
n_row = [str(int(models[k].nobs)) for k in model_keys]
latex_lines.append("N & " + " & ".join(n_row) + r" \\")

latex_lines.append(r"\bottomrule")
latex_lines.append(r"\multicolumn{" + str(len(model_keys) + 1) + r"}{l}{\scriptsize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$. Reference: control group, no FX loan.} \\")
latex_lines.append(r"\end{tabular}")
latex_lines.append(r"\end{table}")

latex_output = "\n".join(latex_lines)

# Save LaTeX table
with open("session_5/option_b/exercise_2/tables/robustness_table.tex", "w") as f:
    f.write(latex_output)

print("\n\nLaTeX table saved to session_5/option_b/exercise_2/tables/robustness_table.tex")
print("\n" + latex_output)
