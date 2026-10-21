"""
Layer 2: research tests on estimation.

Is the model the one that was intended (reference category, weights, estimation
sample), and do the numbers agree with a separately implemented estimator?
"""

import re

import numpy as np
import pandas as pd
import pytest

import helpers

# Prefix of each model's header line in solution_estimate.py's output
ESTIMATE_MODEL_HEADER = {
    "Treatment only": "Base model",
    "+ FX exposure": "+ FX exposure",
    "+ age, female, ed, urban": "+ demographics (no income",
    "+ income_quintile": "+ income_quintile",
    "+ left_right": "+ left_right",
    "+ both income & LR": "+ both income_quintile",
}


def oracle_parameter_name(pipeline_name):
    """Translate a patsy parameter name from the pipeline into the oracle's parameter name."""
    if pipeline_name.startswith("C(treatment"):
        return re.search(r"T\.(\w+)\]", pipeline_name).group(1)
    if pipeline_name.startswith("C(fx_status"):
        return "fx_" + re.search(r"T\.(\w+)\]", pipeline_name).group(1)
    return pipeline_name


def logit(probability):
    """Log-odds of a probability."""
    return float(np.log(probability / (1.0 - probability)))


# ── Reference category (R3) ──────────────────────────────────────────────
@pytest.mark.requirement("R3")
def test_control_is_the_treatment_reference_in_every_model(pipeline_run):
    """No model has a 'cntrl' coefficient, every formula names Treatment('cntrl'), and the arms are all present."""
    stdout = pipeline_run["runs"]["solution_estimate.py"].stdout
    assert "T.cntrl" not in stdout
    formulas = [line for line in stdout.splitlines() if line.startswith("Formula:")]
    assert len(formulas) == 7
    assert all("Treatment('cntrl')" in formula for formula in formulas)
    base = helpers.parse_estimate_coefficients(stdout, "Base model")
    arms = {oracle_parameter_name(name) for name in base} - {"Intercept"}
    assert arms == {"info", "history", "Hungary"}


@pytest.mark.requirement("R3")
def test_no_fx_loan_is_the_fx_reference_and_the_table_says_so(pipeline_run):
    """The FX reference is 'none' in every model that includes FX, and the robustness table footnote states both references."""
    stdout = pipeline_run["runs"]["solution_estimate.py"].stdout
    fx_formulas = [l for l in stdout.splitlines() if l.startswith("Formula:") and "fx_status" in l]
    assert len(fx_formulas) == 6 and all("Treatment('none')" in f for f in fx_formulas)
    table = (pipeline_run["workspace"] / "session_2/output/robustness_table.tex").read_text()
    assert "Reference: control group, no FX loan" in table


# ── Weights (R4) ─────────────────────────────────────────────────────────
@pytest.mark.requirement("R4")
def test_base_model_uses_weights_intercept_equals_weighted_control_share(pipeline_run, oracle_merged):
    """In a model saturated in treatment, each arm's fitted probability equals its weighted share of supporters.

    So the pipeline's intercept must equal logit(weighted control share), and intercept + arm coefficient
    must equal logit(weighted share in that arm), where the shares are computed straight from the raw data.
    The unweighted share would give a different intercept, so this check detects whether weights were applied.
    """
    stdout = pipeline_run["runs"]["solution_estimate.py"].stdout
    coefficients = helpers.parse_estimate_coefficients(stdout, "Base model")
    answered = oracle_merged.dropna(subset=["supports_intervention"])

    def weighted_share(arm):
        rows = answered[answered["treatment"] == arm]
        return float(np.average(rows["supports_intervention"], weights=rows["survey_weight"]))

    control_share = weighted_share("cntrl")
    pipeline_intercept = coefficients["Intercept"][0]
    helpers.assert_close_and_record(
        "base-model intercept vs logit(weighted control share)",
        pipeline_intercept, logit(control_share), 1e-5,
    )
    unweighted_control = answered.loc[answered["treatment"] == "cntrl", "supports_intervention"].mean()
    assert abs(pipeline_intercept - logit(unweighted_control)) > 1e-3, "intercept is indistinguishable from the unweighted one"

    for arm in ["info", "history", "Hungary"]:
        name = f"C(treatment, Treatment('cntrl'))[T.{arm}]"
        helpers.assert_close_and_record(
            f"base-model intercept + {arm} vs logit(weighted {arm} share)",
            pipeline_intercept + coefficients[name][0], logit(weighted_share(arm)), 1e-5,
        )


@pytest.mark.requirement("R4")
def test_weighting_changes_the_estimates(pipeline_run):
    """Specification (1) is weighted and (2) is not: their info coefficients must differ, not be copies."""
    rows = helpers.parse_robustness_info_rows(pipeline_run["runs"]["solution_robustness.py"].stdout)
    assert abs(rows["(1)"][1] - rows["(2)"][1]) > 0.005


# ── Independent numerical verification (R4) ──────────────────────────────
@pytest.mark.requirement("R4")
@pytest.mark.parametrize("model_label", list(ESTIMATE_MODEL_HEADER))
def test_every_coefficient_se_and_p_value_matches_independent_estimator(pipeline_run, oracle_merged, model_label):
    """Coefficient, standard error and p-value of every parameter agree with a hand-written IRLS (to the 6 printed decimals)."""
    stdout = pipeline_run["runs"]["solution_estimate.py"].stdout
    pipeline = helpers.parse_estimate_coefficients(stdout, ESTIMATE_MODEL_HEADER[model_label])
    oracle = helpers.fit_oracle_spec(oracle_merged, **helpers.ESTIMATE_ORACLE_MODELS[model_label])

    assert {oracle_parameter_name(n) for n in pipeline} == set(oracle.coefficients)
    largest_coef_gap = largest_se_gap = largest_p_gap = 0.0
    for name, (coef, se, _, p_value) in pipeline.items():
        key = oracle_parameter_name(name)
        largest_coef_gap = max(largest_coef_gap, abs(coef - oracle.coefficients[key]))
        largest_se_gap = max(largest_se_gap, abs(se - oracle.standard_errors[key]))
        largest_p_gap = max(largest_p_gap, abs(p_value - oracle.p_values[key]))
    helpers.assert_close_and_record(f"{model_label}: largest coefficient gap", largest_coef_gap, 0.0, 2e-6)
    helpers.assert_close_and_record(f"{model_label}: largest standard-error gap", largest_se_gap, 0.0, 2e-6)
    assert largest_p_gap <= 2e-6


@pytest.mark.requirement("R4")
@pytest.mark.parametrize("spec", [s for s in helpers.ROBUSTNESS_ORACLE_SPECS if s != "(5)"])
def test_robustness_treatment_effect_matches_independent_estimator(pipeline_run, oracle_merged, spec):
    """The info coefficient and p-value in each robustness specification match the independent fit (4 d.p.).

    Specification (5) pools the arms into 'any_info', so the stdout table has no info row for it;
    its coefficient is checked from the LaTeX table in test_07_output_tables.py.
    """
    oracle = helpers.fit_oracle_spec(oracle_merged, **helpers.ROBUSTNESS_ORACLE_SPECS[spec])
    stdout = pipeline_run["runs"]["solution_robustness.py"].stdout
    _, pipeline_coef, pipeline_p = helpers.parse_robustness_info_rows(stdout)[spec]
    helpers.assert_close_and_record(f"robustness {spec}: info coefficient", pipeline_coef, oracle.coefficients["info"], 6e-5)
    assert abs(pipeline_p - oracle.p_values["info"]) <= 6e-5


# ── Model diagnostics (R4) ───────────────────────────────────────────────
@pytest.mark.requirement("R4")
@pytest.mark.parametrize("script_name", ["solution_estimate.py", "solution_robustness.py"])
def test_estimation_emits_no_warnings_and_no_missing_coefficients(pipeline_run, script_name):
    """No convergence, separation or runtime warnings on stderr, and no NaN coefficients in the output."""
    completed = pipeline_run["runs"][script_name]
    assert completed.stderr.strip() == "", completed.stderr[:500]
    assert not re.search(r"\bnan\b", completed.stdout, flags=re.IGNORECASE)


# ── Planted answer (R9) ──────────────────────────────────────────────────
@pytest.mark.requirement("R9")
@pytest.mark.parametrize(
    "scenario, true_effects",
    [
        ("known effects", {"info": 0.30, "history": 0.12, "Hungary": 0.19}),
        ("no effects", {"info": 0.0, "history": 0.0, "Hungary": 0.0}),
    ],
)
def test_estimator_recovers_planted_treatment_effects(scenario, true_effects):
    """Simulate outcomes with known treatment effects; the pipeline's own fit_logit must recover them.

    The simulation draws a random arm and weight for 60,000 respondents, so the true values are
    known by construction. Weights are independent of the outcome, so a correct weighted logit is
    consistent. The tolerance (0.07) is about three standard errors at this sample size.
    """
    rng = np.random.default_rng(20261021)
    n = 60000
    arm = rng.choice(["cntrl", "info", "history", "Hungary"], size=n)
    true_intercept = -0.22
    log_odds = true_intercept + np.array([true_effects.get(a, 0.0) for a in arm])
    outcome = rng.binomial(1, 1.0 / (1.0 + np.exp(-log_odds)))
    weight = rng.uniform(0.5, 1.5, size=n)
    data = pd.DataFrame({"supports_intervention": outcome, "treatment": arm, "survey_weight": weight})

    fit_logit = helpers.load_functions_from_script(helpers.SCRIPTS_DIR / "solution_robustness.py", ["fit_logit"])["fit_logit"]
    model = fit_logit("supports_intervention ~ C(treatment, Treatment('cntrl'))", data, "survey_weight")

    assert abs(model.params["Intercept"] - true_intercept) < 0.07
    for name, true_value in true_effects.items():
        estimate = model.params[f"C(treatment, Treatment('cntrl'))[T.{name}]"]
        assert abs(estimate - true_value) < 0.07, (scenario, name, estimate, true_value)

    # The independent estimator must agree with the pipeline's estimator on the same simulated data
    design = np.column_stack(
        [np.ones(n)] + [(arm == a).astype(float) for a in ["info", "history", "Hungary"]]
    )
    beta, _ = helpers.weighted_logit_irls(design, outcome, weight)
    pipeline_beta = [model.params[k] for k in model.params.index]  # Intercept, info, history, Hungary order
    assert np.allclose(sorted(beta), sorted(pipeline_beta), atol=1e-6)
