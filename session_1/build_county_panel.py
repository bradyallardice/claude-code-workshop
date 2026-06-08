"""Build a balanced county-year panel merging presidential election results with
IPUMS census demographics for 2012, 2016, 2020, and 2024.

The script:
  1. Loads county-level presidential returns, keeps TOTAL-mode rows, cleans FIPS,
     and computes two-party Democratic/Republican vote shares per county-year.
  2. Aggregates IPUMS person-level microdata to county-level demographics using
     person weights (PERWT).
  3. Inner-merges the two sources on county FIPS and year, then restricts to the
     set of counties observed in all four years (a balanced panel).
  4. Prints diagnostic summaries and the largest swings in Democratic vote share.
  5. Saves the panel and two summary plots.

Runnable top to bottom, or interactively in VS Code (Shift+Enter), assuming the
working directory is the project root (AIAgentsCourse/).
"""

import pandas as pd
import numpy as np
import matplotlib

matplotlib.use("Agent" if False else "Agg")  # headless backend for batch runs
import matplotlib.pyplot as plt

YEARS = [2012, 2016, 2020, 2024]
ELECTION_PATH = "session_1/data/election/countypres_sample.csv"
IPUMS_TEMPLATE = "session_1/data/ipums/census_{year}_sample.csv.gz"
OUTPUT_DIR = "session_1/output"


# ---------------------------------------------------------------------------
# 1. Election data: two-party vote shares
# ---------------------------------------------------------------------------
def load_election(path):
    """Load county presidential returns, keep TOTAL mode, return two-party shares.

    Returns one row per (county_fips, year) with columns:
      county_fips, year, dem_2p_share, rep_2p_share.
    """
    df = pd.read_csv(path, dtype={"county_fips": str})

    # Keep only the TOTAL-mode rows (avoids double-counting per-method tallies).
    df = df[df["mode"] == "TOTAL"].copy()

    # Clean FIPS: strip whitespace, drop missing, zero-pad to 5 digits.
    df["county_fips"] = df["county_fips"].str.strip()
    df = df[df["county_fips"].notna() & (df["county_fips"] != "")]
    df["county_fips"] = df["county_fips"].str.zfill(5)

    # Sum candidate votes by party within county-year (handles multiple
    # candidate rows mapping to the same party, e.g. fusion tickets).
    party_votes = (
        df[df["party"].isin(["DEMOCRAT", "REPUBLICAN"])]
        .groupby(["county_fips", "year", "party"])["candidatevotes"]
        .sum()
        .unstack("party")
        .reset_index()
    )
    party_votes = party_votes.rename(
        columns={"DEMOCRAT": "dem_votes", "REPUBLICAN": "rep_votes"}
    )

    # Two-party shares: denominator is Dem + Rep votes only.
    two_party = party_votes["dem_votes"].fillna(0) + party_votes["rep_votes"].fillna(0)
    party_votes["dem_2p_share"] = party_votes["dem_votes"] / two_party
    party_votes["rep_2p_share"] = party_votes["rep_votes"] / two_party

    # Drop county-years with no two-party votes (undefined share).
    party_votes = party_votes[two_party > 0]

    return party_votes[["county_fips", "year", "dem_2p_share", "rep_2p_share"]]


# ---------------------------------------------------------------------------
# 2. IPUMS demographics: weighted county-level aggregation
# ---------------------------------------------------------------------------
def aggregate_ipums_year(year):
    """Aggregate one IPUMS year to county-level, weighted by PERWT.

    Returns one row per county with FIPS, year, and demographic means/shares.
    """
    df = pd.read_csv(IPUMS_TEMPLATE.format(year=year))

    # Build 5-digit county FIPS from state + county codes. COUNTYFIP == 0 marks
    # IPUMS-unidentified counties, which cannot be matched and are dropped.
    df = df[df["COUNTYFIP"] != 0].copy()
    df["county_fips"] = (
        df["STATEFIP"].astype(int) * 1000 + df["COUNTYFIP"].astype(int)
    ).astype(str).str.zfill(5)

    w = df["PERWT"]

    # Indicator variables.
    college = (df["EDUC"] >= 10).astype(float)
    white = (df["RACE"] == 1).astype(float)

    # Hispanic: numerator = HISPAN in 1-4; denominator excludes 9 (Not Reported)
    # from both numerator and denominator.
    hisp_known = df["HISPAN"] != 9
    hispanic = df["HISPAN"].isin([1, 2, 3, 4]).astype(float)

    # Wage earners only: positive, non-missing INCWAGE
    # (999999 = N/A, 999998 = missing).
    wage_earner = (df["INCWAGE"] > 0) & (df["INCWAGE"] < 999998)

    df = df.assign(
        _w=w,
        _wage_w=w.where(wage_earner, 0.0),
        _hisp_w=w.where(hisp_known, 0.0),
        _pop=w,
        _age_w=w * df["AGE"],
        _college_w=w * college,
        _white_w=w * white,
        _hisp_num_w=w.where(hisp_known, 0.0) * hispanic,
        _wage_num_w=w.where(wage_earner, 0.0) * df["INCWAGE"],
    )

    g = df.groupby("county_fips")
    agg = pd.DataFrame(
        {
            "population": g["_pop"].sum(),
            "mean_age": g["_age_w"].sum() / g["_w"].sum(),
            "college_share": g["_college_w"].sum() / g["_w"].sum(),
            "white_share": g["_white_w"].sum() / g["_w"].sum(),
            # Hispanic share uses the Not-Reported-excluded denominator.
            "hispanic_share": g["_hisp_num_w"].sum() / g["_hisp_w"].sum(),
            # Mean wage uses the wage-earner-only denominator.
            "mean_wage": g["_wage_num_w"].sum() / g["_wage_w"].sum(),
        }
    ).reset_index()

    agg["year"] = year
    return agg


def load_all_ipums(years):
    """Aggregate and stack all IPUMS years."""
    return pd.concat([aggregate_ipums_year(y) for y in years], ignore_index=True)


# ---------------------------------------------------------------------------
# 3. Merge + balance
# ---------------------------------------------------------------------------
def build_panel(election, census, years):
    """Inner-merge election and census, then restrict to a balanced panel.

    Returns (balanced_panel, n_counties_before, n_counties_dropped).
    """
    merged = election.merge(census, on=["county_fips", "year"], how="inner")

    n_counties_before = merged["county_fips"].nunique()

    # A county qualifies for the balanced panel only if it appears in every year.
    years_per_county = merged.groupby("county_fips")["year"].nunique()
    balanced_fips = years_per_county[years_per_county == len(years)].index

    balanced = merged[merged["county_fips"].isin(balanced_fips)].copy()
    balanced = balanced.sort_values(["county_fips", "year"]).reset_index(drop=True)

    n_dropped = n_counties_before - balanced["county_fips"].nunique()
    return balanced, n_counties_before, n_dropped


# ---------------------------------------------------------------------------
# 4. Swing diagnostics
# ---------------------------------------------------------------------------
def largest_yearly_swings(panel, n=20):
    """Top-n largest year-to-year swings in Democratic vote share (by |swing|)."""
    p = panel.sort_values(["county_fips", "year"]).copy()
    p["dem_swing"] = p.groupby("county_fips")["dem_2p_share"].diff()
    swings = p.dropna(subset=["dem_swing"]).copy()
    swings["abs_swing"] = swings["dem_swing"].abs()
    cols = ["county_fips", "year", "dem_2p_share", "dem_swing"]
    return swings.sort_values("abs_swing", ascending=False).head(n)[cols]


def largest_baseline_shifts(panel, baseline_year=2012, n=20):
    """For each county, the biggest absolute shift in Dem share from its baseline
    year in any later year. Returns the top-n counties by that maximum shift."""
    base = panel[panel["year"] == baseline_year][["county_fips", "dem_2p_share"]]
    base = base.rename(columns={"dem_2p_share": "dem_baseline"})

    later = panel[panel["year"] > baseline_year].merge(base, on="county_fips")
    later["shift"] = later["dem_2p_share"] - later["dem_baseline"]
    later["abs_shift"] = later["shift"].abs()

    # Keep the single largest-magnitude later-year shift per county.
    idx = later.groupby("county_fips")["abs_shift"].idxmax()
    biggest = later.loc[idx]
    cols = ["county_fips", "year", "dem_baseline", "dem_2p_share", "shift"]
    return biggest.sort_values("abs_shift", ascending=False).head(n)[cols]


# ---------------------------------------------------------------------------
# 5. Plots
# ---------------------------------------------------------------------------
def plot_vote_shares(panel, path):
    """Mean Democratic and Republican two-party vote share over time."""
    means = panel.groupby("year")[["dem_2p_share", "rep_2p_share"]].mean()
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.plot(means.index, means["dem_2p_share"], marker="o", color="tab:blue",
            label="Democratic")
    ax.plot(means.index, means["rep_2p_share"], marker="o", color="tab:red",
            label="Republican")
    ax.set_xlabel("Year")
    ax.set_ylabel("Mean two-party vote share")
    ax.set_title("Mean two-party vote share over time (balanced panel)")
    ax.set_xticks(panel["year"].unique())
    ax.legend()
    fig.tight_layout()
    fig.savefig(path, dpi=150)
    plt.close(fig)


def plot_demographics(panel, path):
    """Mean of each demographic variable over time, one subplot per variable."""
    demo_vars = [
        ("population", "Mean county population"),
        ("mean_age", "Mean age"),
        ("college_share", "College share (EDUC >= 10)"),
        ("white_share", "White share (RACE == 1)"),
        ("hispanic_share", "Hispanic share"),
        ("mean_wage", "Mean wage (earners only)"),
    ]
    means = panel.groupby("year")[[v for v, _ in demo_vars]].mean()

    fig, axes = plt.subplots(2, 3, figsize=(14, 8))
    for ax, (var, title) in zip(axes.ravel(), demo_vars):
        ax.plot(means.index, means[var], marker="o", color="tab:green")
        ax.set_title(title)
        ax.set_xlabel("Year")
        ax.set_xticks(means.index)
    fig.suptitle("Mean demographic variables over time (balanced panel)")
    fig.tight_layout()
    fig.savefig(path, dpi=150)
    plt.close(fig)


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------
election = load_election(ELECTION_PATH)
census = load_all_ipums(YEARS)
panel, n_before, n_dropped = build_panel(election, census, YEARS)

panel.to_csv(f"{OUTPUT_DIR}/county_panel.csv", index=False)

# --- Summary ---------------------------------------------------------------
print("=" * 60)
print("PANEL SUMMARY")
print("=" * 60)
print(f"Panel shape:        {panel.shape}")
print(f"Number of counties: {panel['county_fips'].nunique()}")
print(f"Years covered:      {sorted(panel['year'].unique())}")
print(f"Counties after inner merge (any year): {n_before}")
print(f"Counties dropped during balancing:     {n_dropped}")
print()
print("Mean two-party vote shares by year:")
print(
    panel.groupby("year")[["dem_2p_share", "rep_2p_share"]]
    .mean()
    .round(4)
    .to_string()
)

print()
print("=" * 60)
print("20 LARGEST YEAR-TO-YEAR SWINGS IN DEM VOTE SHARE")
print("=" * 60)
print(largest_yearly_swings(panel, 20).round(4).to_string(index=False))

print()
print("=" * 60)
print("20 LARGEST SHIFTS FROM 2012 BASELINE (biggest later-year shift)")
print("=" * 60)
print(largest_baseline_shifts(panel, 2012, 20).round(4).to_string(index=False))

# --- Plots -----------------------------------------------------------------
plot_vote_shares(panel, f"{OUTPUT_DIR}/vote_share_2p_over_time.png")
plot_demographics(panel, f"{OUTPUT_DIR}/demographics_over_time.png")

print()
print(f"Saved panel -> {OUTPUT_DIR}/county_panel.csv")
print(f"Saved plots -> {OUTPUT_DIR}/vote_share_2p_over_time.png, "
      f"{OUTPUT_DIR}/demographics_over_time.png")
