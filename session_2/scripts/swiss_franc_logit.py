"""
Swiss Franc Survey: Logistic Regression Analysis

Analyzes support for government FX intervention using a randomized treatment
(control, info, history, Hungary) with stepwise addition of FX exposure and
demographic controls. Uses survey weights for all models.

Reference categories: treatment='cntrl', fx_status='none'
"""

import pandas as pd
import numpy as np
from statsmodels.formula.api import logit
import warnings
warnings.filterwarnings('ignore')


def load_and_merge():
    """Load survey and demographics, left merge on respondent_id."""
    survey = pd.read_csv('session_2/data/swiss_franc_survey.csv')
    demographics = pd.read_csv('session_2/data/respondent_demographics.csv')

    # Left merge: keep all survey respondents
    df = survey.merge(
        demographics[['respondent_id', 'income_quintile', 'left_right']],
        on='respondent_id',
        how='left'
    )

    return df


def prepare_data(df):
    """
    Prepare data for regression. Drop missing outcome, encode categoricals
    with explicit reference categories.
    """
    # Drop rows with missing outcome
    df_clean = df[df['supports_intervention'].notna()].copy()

    # Ensure reference categories are set explicitly
    # treatment: cntrl is reference (omitted in dummy encoding)
    # fx_status: none is reference
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


def model_summary(model_fit, model_name, n_obs):
    """Print summary of fitted model with N and AIC."""
    print(f"\n{'='*70}")
    print(f"{model_name}")
    print(f"{'='*70}")
    print(f"N = {n_obs}")
    print(f"AIC = {model_fit.aic:.2f}")
    print(model_fit.summary())


def main():
    # Load and prepare
    df = load_and_merge()
    df = prepare_data(df)

    print("Data loaded and merged.")
    print(f"Survey respondents: {len(df)}")
    print(f"Missing outcome: {df['supports_intervention'].isna().sum()}")
    print(f"Missing fx_status: {df['fx_status'].isna().sum()}")
    print(f"Missing income_quintile: {df['income_quintile'].isna().sum()}")
    print(f"Missing left_right: {df['left_right'].isna().sum()}")

    # MODEL 1: Treatment only
    print("\n" + "="*70)
    print("MODEL 1: Treatment only (weighted)")
    print("="*70)
    model1 = logit(
        'supports_intervention ~ C(treatment, Treatment(ref="cntrl"))',
        data=df,
        weights=df['survey_weight']
    ).fit(disp=0)
    model_summary(model1, "Model 1: Treatment", len(df) - df['supports_intervention'].isna().sum())

    # MODEL 2: Treatment + FX status
    print("\n" + "="*70)
    print("MODEL 2: Treatment + FX Status (weighted)")
    print("="*70)
    df_model2 = df[df['fx_status'].notna()].copy()
    model2 = logit(
        'supports_intervention ~ C(treatment, Treatment(ref="cntrl")) + C(fx_status, Treatment(ref="none"))',
        data=df_model2,
        weights=df_model2['survey_weight']
    ).fit(disp=0)
    model_summary(model2, "Model 2: Treatment + FX Status", len(df_model2))

    # MODEL 3: Add demographic controls (with N prediction)
    print("\n" + "="*70)
    print("MODEL 3 PREDICTION: Treatment + FX Status + Demographics")
    print("="*70)
    df_model3_candidate = df_model2[
        df_model2['age'].notna() &
        df_model3_candidate['female'].notna() &
        df_model3_candidate['ed_level'].notna() &
        df_model3_candidate['urban_rural'].notna() &
        df_model3_candidate['income_quintile'].notna() &
        df_model3_candidate['left_right'].notna()
    ].copy()

    predicted_n = len(df_model3_candidate)
    print(f"Predicted N (all controls non-missing): {predicted_n}")
    print(f"  This excludes {len(df_model2) - predicted_n} obs with missing controls")

    # Fit Model 3
    print("\n" + "="*70)
    print("MODEL 3: Treatment + FX Status + Demographics (weighted)")
    print("="*70)
    model3 = logit(
        'supports_intervention ~ C(treatment, Treatment(ref="cntrl")) + '
        'C(fx_status, Treatment(ref="none")) + '
        'age + C(female) + C(ed_level) + C(urban_rural) + '
        'C(income_quintile) + left_right',
        data=df_model3_candidate,
        weights=df_model3_candidate['survey_weight']
    ).fit(disp=0)
    model_summary(model3, "Model 3: Full Demographic Controls", len(df_model3_candidate))

    actual_n = len(df_model3_candidate)
    print(f"\nPredicted N: {predicted_n} | Actual N: {actual_n}")
    if predicted_n == actual_n:
        print("✓ Prediction was correct.")
    else:
        print(f"✗ Prediction was off by {actual_n - predicted_n} obs.")

    # MODEL 4: Add treatment × FX status interaction
    print("\n" + "="*70)
    print("MODEL 4: Treatment × FX Status Interaction (weighted)")
    print("="*70)
    model4 = logit(
        'supports_intervention ~ C(treatment, Treatment(ref="cntrl")) * '
        'C(fx_status, Treatment(ref="none")) + '
        'age + C(female) + C(ed_level) + C(urban_rural) + '
        'C(income_quintile) + left_right',
        data=df_model3_candidate,
        weights=df_model3_candidate['survey_weight']
    ).fit(disp=0)
    model_summary(model4, "Model 4: Treatment × FX Status Interaction", len(df_model3_candidate))

    print("\n" + "="*70)
    print("Analysis complete.")
    print("="*70)


if __name__ == '__main__':
    main()
