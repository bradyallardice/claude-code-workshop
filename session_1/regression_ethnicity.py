"""
Regress county ethnic composition on Democratic 2-party presidential vote share.

Four specifications (all with county-clustered SEs):
  1. Pooled OLS — ethnicity only
  2. Pooled OLS — ethnicity + demographic controls
  3. County FE  — ethnicity + controls
  4. Two-way FE (county + year) — ethnicity + controls

Run from project root: python session_1/regression_ethnicity.py
"""

import pandas as pd
import numpy as np
from linearmodels import PooledOLS, PanelOLS

OUTCOME = "dem_2p_share"
ETHNICITY = ["pct_white_nonhisp", "pct_hispanic", "pct_black_nonhisp"]
CONTROLS  = ["pct_college", "mean_incwage", "pct_age65plus"]


# ── Functions ─────────────────────────────────────────────────────────────────

def load_panel():
    """Load county-year panel and set MultiIndex required by linearmodels."""
    df = pd.read_csv("session_1/output/county_panel.csv")
    df = df.dropna(subset=[OUTCOME] + ETHNICITY + CONTROLS)
    df = df.set_index(["county_fips", "year"])
    return df


def build_exog(df, include_controls):
    """Assemble regressor matrix with a constant."""
    cols = ETHNICITY + (CONTROLS if include_controls else [])
    exog = df[cols].copy()
    exog.insert(0, "const", 1.0)
    return exog


def fit_pooled(endog, exog):
    """Pooled OLS with county-clustered SEs."""
    mod = PooledOLS(endog, exog)
    return mod.fit(cov_type="clustered", cluster_entity=True)


def fit_panel(endog, exog, entity_effects, time_effects):
    """Panel OLS (county FE and/or year FE) with county-clustered SEs."""
    mod = PanelOLS(
        endog, exog,
        entity_effects=entity_effects,
        time_effects=time_effects,
    )
    return mod.fit(cov_type="clustered", cluster_entity=True)


def build_comparison_table(results, labels):
    """
    Assemble a side-by-side coefficient table.
    Returns a list of formatted strings.
    """
    # Collect all variables that appear in any model
    all_vars = []
    for res in results:
        for v in res.params.index:
            if v not in all_vars:
                all_vars.append(v)

    col_w = 18
    lines = []

    header = f"{'':25s}" + "".join(f"{lbl:>{col_w}}" for lbl in labels)
    lines.append(header)
    lines.append("-" * (25 + col_w * len(results)))

    for var in all_vars:
        if var == "const":
            continue
        coef_row  = f"{var:<25s}"
        se_row    = f"{'':25s}"
        star_map  = {0.01: "***", 0.05: "**", 0.10: "*"}
        for res in results:
            if var in res.params.index:
                coef = res.params[var]
                se   = res.std_errors[var]
                pval = res.pvalues[var]
                stars = next((s for t, s in star_map.items() if pval < t), "")
                coef_row += f"{coef:>+{col_w-3}.4f}{stars:3s}"
                se_row   += f"{'(' + f'{se:.4f}' + ')':>{col_w}}"
            else:
                coef_row += f"{'':>{col_w}}"
                se_row   += f"{'':>{col_w}}"
        lines.append(coef_row)
        lines.append(se_row)

    lines.append("-" * (25 + col_w * len(results)))

    # Footer: N, R², FE indicators
    n_row   = f"{'N':25s}" + "".join(f"{int(res.nobs):>{col_w},}" for res in results)
    r2_row  = f"{'R²':25s}" + "".join(f"{res.rsquared:>{col_w}.4f}" for res in results)
    fe_labels = ["County FE", "Year FE"]
    fe_flags  = [
        [False, False],  # pooled no controls
        [False, False],  # pooled with controls
        [True,  False],  # county FE
        [True,  True ],  # two-way FE
    ]
    lines.append(n_row)
    lines.append(r2_row)
    for label, flags in zip(fe_labels, zip(*fe_flags)):
        row = f"{label:<25s}" + "".join(f"{'Yes' if f else 'No':>{col_w}}" for f in flags)
        lines.append(row)

    lines.append("")
    lines.append("Clustered SEs (by county) in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    lines.append(f"Outcome: {OUTCOME}")
    return lines


def print_comparison(lines):
    for line in lines:
        print(line)


def save_results(lines, path="session_1/output/regression_results.txt"):
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"\nSaved {path}")


# ── Execution ─────────────────────────────────────────────────────────────────

df = load_panel()
endog = df[OUTCOME]

res1 = fit_pooled(endog, build_exog(df, include_controls=False))
res2 = fit_pooled(endog, build_exog(df, include_controls=True))
res3 = fit_panel(endog, build_exog(df, include_controls=True),
                 entity_effects=True,  time_effects=False)
res4 = fit_panel(endog, build_exog(df, include_controls=True),
                 entity_effects=True,  time_effects=True)

labels = [
    "(1) Pooled OLS",
    "(2) Pooled + controls",
    "(3) County FE",
    "(4) Two-way FE",
]

lines = build_comparison_table([res1, res2, res3, res4], labels)
print_comparison(lines)
save_results(lines)
