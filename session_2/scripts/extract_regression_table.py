"""
Extract regression results from Swiss Franc survey analysis and format as CSV
for LaTeX regression table. Produces tab_swiss_franc_logit.csv ready for rendering.
"""

import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf
import warnings
warnings.filterwarnings('ignore')


def fit_logit(formula, data, weighted):
    """Logit via GLM. statsmodels' formula logit() silently ignores a weights= argument,
    so weighted fits use GLM with freq_weights (point estimates equal the survey-weighted
    MLE; standard errors treat weights as frequency counts). Adds .prsquared (McFadden)."""
    model = smf.glm(formula, data=data, family=sm.families.Binomial(),
                    freq_weights=data['survey_weight'] if weighted else None, missing='drop')
    result = model.fit()
    result.prsquared = 1 - result.deviance / result.null_deviance
    return result


def load_and_merge():
    """Load survey and demographics, left merge on respondent_id."""
    survey = pd.read_csv('session_2/data/swiss_franc_survey.csv')
    demographics = pd.read_csv('session_2/data/respondent_demographics.csv')
    df = survey.merge(
        demographics[['respondent_id', 'income_quintile', 'left_right']],
        on='respondent_id',
        how='left'
    )
    return df


def prepare_data(df):
    """Prepare data for regression."""
    df_clean = df[df['supports_intervention'].notna()].copy()
    df_clean['treatment'] = pd.Categorical(
        df_clean['treatment'],
        categories=['cntrl', 'info', 'history', 'Hungary'],
        ordered=False
    )
    df_clean['fx_status'] = pd.Categorical(
        df_clean['fx_status'],
        categories=['none', 'current', 'past'],
        ordered=False
    )
    return df_clean


def extract_coef(model, param_name):
    """Extract coefficient, SE, and p-value for a parameter."""
    if param_name not in model.params.index:
        return np.nan, np.nan, np.nan
    coef = model.params[param_name]
    se = model.bse[param_name]
    pval = model.pvalues[param_name]
    return coef, se, pval


def main():
    # Load and prepare data
    df = load_and_merge()
    df = prepare_data(df)

    # Get complete-case dataset for RC models
    df_model2 = df[df['fx_status'].notna()].copy()
    df_complete = df_model2[
        df_model2['age'].notna() &
        df_model2['female'].notna() &
        df_model2['ed_level'].notna() &
        df_model2['urban_rural'].notna() &
        df_model2['income_quintile'].notna() &
        df_model2['left_right'].notna()
    ].copy()

    # Fit all models
    print("Fitting all models...")

    # Model 1: Treatment only (all data)
    m1 = fit_logit('supports_intervention ~ C(treatment)', df, weighted=True)

    # Model 2: + FX status
    m2 = fit_logit('supports_intervention ~ C(treatment) + C(fx_status)', df_model2, weighted=True)

    # RC2-A: Treatment only on complete cases
    rc2a = fit_logit('supports_intervention ~ C(treatment)', df_complete, weighted=True)

    # RC2-B: + FX status on complete cases
    rc2b = fit_logit('supports_intervention ~ C(treatment) + C(fx_status)', df_complete, weighted=True)

    # RC2-C: + Basic demo on complete cases
    rc2c = fit_logit('supports_intervention ~ C(treatment) + C(fx_status) + age + C(female) + C(ed_level) + C(urban_rural)', df_complete, weighted=True)

    # RC2-D: Full controls (main model)
    rc2d = fit_logit('supports_intervention ~ C(treatment) + C(fx_status) + age + C(female) + C(ed_level) + C(urban_rural) + C(income_quintile) + left_right', df_complete, weighted=True)

    # RC1: Unweighted
    rc1_unw = fit_logit('supports_intervention ~ C(treatment) + C(fx_status) + age + C(female) + C(ed_level) + C(urban_rural) + C(income_quintile) + left_right', df_complete, weighted=False)

    # RC3: Collapsed treatment (any info)
    df_collapsed = df_complete.copy()
    df_collapsed['any_info'] = (df_collapsed['treatment'] != 'cntrl').astype(int)
    rc3 = fit_logit('supports_intervention ~ any_info + C(fx_status) + age + C(female) + C(ed_level) + C(urban_rural) + C(income_quintile) + left_right', df_collapsed, weighted=True)

    # Build CSV rows
    rows = []

    # Spec labels
    specs = [
        ('m1', 'Model 1'),
        ('m2', 'Model 2'),
        ('rc2a', 'RC2-A'),
        ('rc2b', 'RC2-B'),
        ('rc2c', 'RC2-C'),
        ('rc2d', 'Model 3'),
        ('rc1_unw', 'RC1 Unw.'),
        ('rc3', 'RC3')
    ]

    for i, (spec_id, spec_label) in enumerate(specs):
        rows.append({
            'row_type': 'spec_label',
            'display_order': i,
            'spec': spec_id,
            'dv': np.nan,
            'dv_label': np.nan,
            'coef_type': np.nan,
            'coef': np.nan,
            'se': np.nan,
            'pvalue': np.nan,
            'value_num': np.nan,
            'value_str': spec_label,
            'fe_name': np.nan
        })

    # Coefficients: treatment info
    models = [m1, m2, rc2a, rc2b, rc2c, rc2d, rc1_unw, rc3]
    treatment_params = [
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'C(treatment)[T.info]',
        'any_info'
    ]

    treatment_labels = ['Info treatment', 'Info treatment', 'Info treatment', 'Info treatment',
                        'Info treatment', 'Info treatment', 'Info treatment', 'Any info']

    for i, (spec_id, spec_label) in enumerate(specs):
        model = models[i]
        param = treatment_params[i]
        label = treatment_labels[i]
        coef, se, pval = extract_coef(model, param)
        rows.append({
            'row_type': 'coefficient',
            'display_order': 0,
            'spec': spec_id,
            'dv': 'intervention_support',
            'dv_label': 'Support for FX Intervention',
            'coef_type': 'treatment',
            'coef': coef,
            'se': se,
            'pvalue': pval,
            'value_num': np.nan,
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # FX status: current (only for models that have it)
    fx_specs = [('m2', 1), ('rc2a', 2), ('rc2b', 3), ('rc2c', 4), ('rc2d', 5), ('rc1_unw', 6), ('rc3', 7)]
    for spec_id, model_idx in fx_specs:
        coef, se, pval = extract_coef(models[model_idx], 'C(fx_status)[T.current]')
        rows.append({
            'row_type': 'coefficient',
            'display_order': 1,
            'spec': spec_id,
            'dv': 'intervention_support',
            'dv_label': 'Support for FX Intervention',
            'coef_type': 'fx_current',
            'coef': coef,
            'se': se,
            'pvalue': pval,
            'value_num': np.nan,
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # Female coefficient (only for models that have full controls)
    female_specs = [('rc2c', 4), ('rc2d', 5), ('rc1_unw', 6), ('rc3', 7)]
    for spec_id, model_idx in female_specs:
        coef, se, pval = extract_coef(models[model_idx], 'C(female)[T.1]')
        rows.append({
            'row_type': 'coefficient',
            'display_order': 2,
            'spec': spec_id,
            'dv': 'intervention_support',
            'dv_label': 'Support for FX Intervention',
            'coef_type': 'female',
            'coef': coef,
            'se': se,
            'pvalue': pval,
            'value_num': np.nan,
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # Income coefficient (only for full controls)
    income_specs = [('rc2d', 5), ('rc1_unw', 6), ('rc3', 7)]
    for spec_id, model_idx in income_specs:
        coef, se, pval = extract_coef(models[model_idx], 'C(income_quintile)[T.5.0]')
        rows.append({
            'row_type': 'coefficient',
            'display_order': 3,
            'spec': spec_id,
            'dv': 'intervention_support',
            'dv_label': 'Support for FX Intervention',
            'coef_type': 'income_q5',
            'coef': coef,
            'se': se,
            'pvalue': pval,
            'value_num': np.nan,
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # N rows
    ns = [len(df), len(df_model2), len(df_complete), len(df_complete), len(df_complete),
          len(df_complete), len(df_complete), len(df_complete)]
    for i, (spec_id, spec_label) in enumerate(specs):
        rows.append({
            'row_type': 'n',
            'display_order': 0,
            'spec': spec_id,
            'dv': np.nan,
            'dv_label': np.nan,
            'coef_type': np.nan,
            'coef': np.nan,
            'se': np.nan,
            'pvalue': np.nan,
            'value_num': ns[i],
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # Pseudo R2 rows
    r2s = [m1.prsquared, m2.prsquared, rc2a.prsquared, rc2b.prsquared, rc2c.prsquared,
           rc2d.prsquared, rc1_unw.prsquared, rc3.prsquared]
    for i, (spec_id, spec_label) in enumerate(specs):
        rows.append({
            'row_type': 'r2',
            'display_order': 0,
            'spec': spec_id,
            'dv': np.nan,
            'dv_label': np.nan,
            'coef_type': np.nan,
            'coef': np.nan,
            'se': np.nan,
            'pvalue': np.nan,
            'value_num': r2s[i],
            'value_str': np.nan,
            'fe_name': np.nan
        })

    # Notes
    rows.append({
        'row_type': 'note',
        'display_order': 0,
        'spec': np.nan,
        'dv': np.nan,
        'dv_label': np.nan,
        'coef_type': np.nan,
        'coef': np.nan,
        'se': np.nan,
        'pvalue': np.nan,
        'value_num': np.nan,
        'value_str': 'Models 1–2 use all respondents with non-missing outcome (N shown). RC2-A–C and RC3 use complete-case sample (N=1,151). RC1 Unw. is unweighted version of full controls model. All models use survey weights except RC1 Unw. FX Status current effect shown. Female, Income Q5, and other controls estimated on full control specifications only.',
        'fe_name': np.nan
    })

    # Convert to DataFrame
    df_results = pd.DataFrame(rows)

    # Save CSV
    output_path = 'session_2/output/tab_swiss_franc_logit.csv'
    df_results.to_csv(output_path, index=False, na_rep='NA')
    print(f"Results saved to {output_path}")
    print(f"\nCSV shape: {df_results.shape}")
    print(f"Unique specs: {df_results['spec'].nunique()}")
    print(f"Coefficients: {(df_results['row_type'] == 'coefficient').sum()}")


if __name__ == '__main__':
    main()
