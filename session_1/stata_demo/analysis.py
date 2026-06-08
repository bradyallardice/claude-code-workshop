"""analysis.py -- county-panel regressions, ported from analysis.do.

Faithful Python/pandas/statsmodels port of session_1/stata_demo/analysis.do.
It estimates Democratic two-party vote share on a few demographic predictors
under three increasingly demanding specifications:

    Model 1 : pooled OLS, heteroskedasticity-robust SEs
    Model 2 : + year fixed effects
    Model 3 : county + year fixed effects, SEs clustered by county

Run from the project root (AIAgentsCourse/):
    python session_1/stata_demo/analysis.py
or step through it interactively in VS Code (Shift+Enter, block by block).

NOTE: several translation choices are flagged below with `# DECISION:`.
See the chat for the open questions; the defaults here are provisional.
"""

import pandas as pd
import statsmodels.formula.api as smf

# --- Paths (hardcoded relative to the project root, per project convention) ---
PANEL_CSV = "session_1/output/county_panel.csv"
TABLE_OUT = "session_1/output/regression_dem_share.txt"


# ──────────────────────────────────────────────────────────────────────────
#  Function definitions (kept separate from execution so they can be tested
#  interactively / imported without side effects)
# ──────────────────────────────────────────────────────────────────────────

def load_panel(path=PANEL_CSV):
    """Load the county-year panel and reconcile column names with the .do file.

    The .do referenced variable names produced by build_county_panel.py, but the
    CSV on disk uses different names (and is missing two columns). We rename the
    ones that exist; the missing ones are handled in build_predictors().
    """
    df = pd.read_csv(path, dtype={"county_fips": str})  # keep leading zero in FIPS

    # Stata `encode county_fips, gen(county_id)` + `xtset county_id year`:
    # we just keep the string FIPS as the panel id. statsmodels groups on it
    # directly, so no integer encoding is needed.
    df = df.rename(columns={
        "dem_2p_share": "dem_share_2p",   # .do expected dem_share_2p
        "college_share": "share_college",  # .do expected share_college
    })
    return df


def build_predictors(df):
    """Rescale predictors for coefficient readability (mirrors the .do `gen`s)."""
    df = df.copy()
    df["college_pct"] = df["share_college"] * 100  # share -> percentage points

    # DECISION 1: the .do used median_wage; the CSV only has mean_wage.
    # Provisional default: substitute mean_wage. (mean != median.)
    df["wage_k"] = df["mean_wage"] / 1000  # dollars -> thousands

    # DECISION 2: the .do used share_age_65_plus; that column does not exist in
    # the CSV (only mean_age). No faithful substitute exists, so senior_pct is
    # omitted from the models below until you decide how to handle it.
    # df["senior_pct"] = df["share_age_65_plus"] * 100   # <- not available

    return df


def fit_models(df):
    """Estimate the three specifications and return them in a dict."""
    # Stata `robust` == HC1 heteroskedasticity-robust SEs in statsmodels.
    # DECISION 3: senior_pct dropped (see build_predictors); add it back here
    # once DECISION 2 is resolved.
    base_rhs = "college_pct + wage_k"

    # Model 1: pooled OLS, robust SEs
    m1 = smf.ols(f"dem_share_2p ~ {base_rhs}", data=df).fit(cov_type="HC1")

    # Model 2: + year fixed effects (Stata i.year -> C(year))
    m2 = smf.ols(f"dem_share_2p ~ {base_rhs} + C(year)", data=df).fit(cov_type="HC1")

    # Model 3: county + year FE (LSDV is numerically identical to xtreg, fe for
    # the slope coefficients), SEs clustered by county.
    # DECISION 4: clustered SEs match Stata's xtreg, fe closely but not to the
    # last digit -- Stata applies a small-sample (G/(G-1))*((N-1)/(N-K)) finite-
    # sample correction that statsmodels' 'cluster' handles slightly differently.
    m3 = smf.ols(f"dem_share_2p ~ {base_rhs} + C(county_fips) + C(year)", data=df).fit(
        cov_type="cluster", cov_kwds={"groups": df["county_fips"]}
    )
    return {"Model 1: pooled OLS": m1,
            "Model 2: + year FE": m2,
            "Model 3: county + year FE": m3}


def export_table(models, path=TABLE_OUT):
    """Write a plain-text results table (the outreg2 replacement).

    DECISION 5: outreg2 has no Python equivalent. This writes statsmodels'
    native summaries. For a publication-quality table, the repo's
    latex-regression-table skill renders a booktabs .tex/.png from a CSV.
    """
    keep = ["college_pct", "wage_k"]  # hide the FE dummy rows
    with open(path, "w") as f:
        for name, res in models.items():
            f.write(f"=== {name} ===\n")
            tbl = res.summary2().tables[1]
            f.write(tbl.loc[tbl.index.intersection(keep)].to_string())
            f.write(f"\n  N = {int(res.nobs)}   R2 = {res.rsquared:.4f}\n\n")
    print(f"Wrote {path}")


# ──────────────────────────────────────────────────────────────────────────
#  Execution (top-level so it runs line-by-line in VS Code; guarded for import)
# ──────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    panel = load_panel()
    panel = build_predictors(panel)
    models = fit_models(panel)

    for name, res in models.items():
        print(f"\n{'=' * 70}\n{name}\n{'=' * 70}")
        print(res.summary())

    export_table(models)
