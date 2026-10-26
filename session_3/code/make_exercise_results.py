"""
Build the results table used by the Session 3 "results -> paper" exercise.

Teacher-only. Reads the Session 2 raw data and writes
session_3/results_to_paper/results/regression_results.csv in the long format
that session_3/results_to_paper/scripts/render_regression_table.py reads.

Why this file exists: session_2/output/tab_swiss_franc_logit.csv was produced with
statsmodels' formula Logit(..., weights=...), which silently ignores `weights`, so
its "weighted" columns are unweighted. Here the weighted models are fitted with
GLM(Binomial, freq_weights=...) and model-based standard errors. Point estimates under freq_weights equal the
survey-weighted MLE. The standard errors treat weights as frequency counts, as
the answer key does; a design-based variance would differ. Base-model numbers are checked against
session_2/docs/instructor_answer_key.md at the bottom of the run.

Run from the project root: python session_3/code/make_exercise_results.py
"""

import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

SURVEY_PATH = "session_2/data/swiss_franc_survey.csv"
DEMOGRAPHICS_PATH = "session_2/data/respondent_demographics.csv"
OUTPUT_PATH = "session_3/results_to_paper/results/regression_results.csv"

# female is 0/1; ed_level, urban_rural, and income_quintile enter linearly (ordinal codes).
# This coding reproduces the reference table in session_2/docs/instructor_answer_key.md.
BASIC_CONTROLS = "C(fx_status) + age + female + ed_level + urban_rural"
CONTROLS = BASIC_CONTROLS + " + income_quintile + left_right"


def load_merged():
    """Left-join demographics onto the survey (all 2,044 respondents kept)."""
    survey = pd.read_csv(SURVEY_PATH)
    demographics = pd.read_csv(DEMOGRAPHICS_PATH)
    merged = survey.merge(demographics, on="respondent_id", how="left", validate="1:1")
    assert len(merged) == len(survey) == 2044
    return merged


def fit_logit(formula, data, weighted):
    """Fit a logit by GLM on the rows with no missing values in the formula's variables.

    Returns the fitted model, the number of rows used, and the McFadden pseudo R^2
    (1 - deviance / null deviance, using the same weights as the fit).
    """
    weights = "survey_weight" if weighted else None
    model = smf.glm(formula, data=data, family=sm.families.Binomial(),
                    freq_weights=data[weights] if weighted else None,
                    missing="drop")
    result = model.fit()
    pseudo_r2 = 1 - result.deviance / result.null_deviance
    return result, int(result.nobs), pseudo_r2


def main():
    df = load_merged()
    df["treatment"] = pd.Categorical(df["treatment"],
                                     categories=["cntrl", "info", "history", "Hungary"])
    df["any_info"] = (df["treatment"] != "cntrl").astype(float)
    df.loc[df["treatment"].isna(), "any_info"] = np.nan
    outcome = "supports_intervention ~ "

    # Columns of the table: (key, label, formula, data, weighted)
    specs = [
        ("c1", "(1) Base", outcome + "C(treatment)", df, True),
        ("c2", "(2) Unwtd.", outcome + "C(treatment)", df, False),
        ("c3", "(3) Basic", outcome + "C(treatment) + " + BASIC_CONTROLS, df, True),
        ("c4", "(4) Full", outcome + "C(treatment) + " + CONTROLS, df, True),
        ("c5", "(5) Any", outcome + "any_info + " + BASIC_CONTROLS, df, True),
        ("c6", "(6) Urban", outcome + "C(treatment) + " + BASIC_CONTROLS,
         df[df["urban_rural"] >= 2], True),
    ]
    coef_map = {
        "C(treatment)[T.info]": "info",
        "C(treatment)[T.history]": "history",
        "C(treatment)[T.Hungary]": "hungary",
        "any_info": "any_info",
    }

    rows = []
    summary = {}
    for order, (key, label, formula, data, weighted) in enumerate(specs):
        result, n_used, pseudo_r2 = fit_logit(formula, data, weighted)
        summary[key] = (n_used, result)
        rows.append(dict(row_type="spec_label", display_order=order, spec=key, value_str=label))
        rows.append(dict(row_type="n", display_order=0, spec=key, value_num=n_used))
        rows.append(dict(row_type="r2", display_order=0, spec=key, value_num=pseudo_r2))
        for term, coef_type in coef_map.items():
            if term in result.params.index:
                rows.append(dict(row_type="coefficient", display_order=list(coef_map.values()).index(coef_type),
                                 spec=key, dv="supports_intervention",
                                 dv_label="Supports intervention", coef_type=coef_type,
                                 coef=result.params[term], se=result.bse[term],
                                 pvalue=result.pvalues[term]))
    rows.append(dict(row_type="note", display_order=0, value_str=(
        "Logit coefficients (log-odds), model-based standard errors in parentheses. "
        "Reference arm: control. Columns (1) and (3)--(6) use survey weights; column (2) does not. "
        "Columns (3)--(6) control for FX status, age, female, education, and settlement size; "
        "column (4) adds income quintile and left-right, which restricts the sample to "
        "respondents with both. Column (5) replaces the three arms with a single any-information "
        "indicator. Column (6) keeps respondents in small or big urban areas only.")))

    columns = ["row_type", "display_order", "spec", "dv", "dv_label", "coef_type",
               "coef", "se", "pvalue", "value_num", "value_str", "fe_name"]
    table = pd.DataFrame(rows).reindex(columns=columns)
    table.to_csv(OUTPUT_PATH, index=False, na_rep="NA")
    print(f"wrote {OUTPUT_PATH} ({len(table)} rows)")

    # ---- checks against session_2/docs/instructor_answer_key.md ----
    def coef(key, term):
        return summary[key][1].params[term], summary[key][1].pvalues[term]

    n1, r1 = summary["c1"]
    intercept = r1.params["Intercept"]
    control = df[(df["treatment"] == "cntrl") & df["supports_intervention"].notna()]
    weighted_control_share = np.average(control["supports_intervention"], weights=control["survey_weight"])
    print("Ns:", {k: v[0] for k, v in summary.items()})
    print("intercept", round(intercept, 3), "expit", round(1 / (1 + np.exp(-intercept)), 4),
          "weighted control share", round(weighted_control_share, 4))
    for key, term in [("c1", "C(treatment)[T.info]"), ("c2", "C(treatment)[T.info]"),
                      ("c3", "C(treatment)[T.info]"), ("c4", "C(treatment)[T.info]"),
                      ("c5", "any_info"), ("c6", "C(treatment)[T.info]")]:
        b, p = coef(key, term)
        print(key, term, "coef", round(b, 3), "p", round(p, 3))
    return summary


if __name__ == "__main__":
    main()
