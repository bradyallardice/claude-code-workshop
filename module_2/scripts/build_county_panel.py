"""Build a county-level panel joining presidential vote shares with IPUMS demographics.

Reads:
  - module_1/data/election/countypres_sample.csv (MIT Election Data + Science Lab)
  - module_1/data/ipums/census_{year}_sample.csv.gz (IPUMS USA microdata)

Outputs:
  - module_1/output/county_panel.csv
  - module_1/output/vote_share_over_time.png
  - module_1/output/demographics_over_time.png

Variable coding (from IPUMS codebooks):
  EDUC: 0=N/A or no schooling, 1=nursery-grade 4, 2=grade 5-8, 3=grade 9,
        4=grade 10, 5=grade 11, 6=grade 12, 7=1yr college, 8=2yr college,
        9=3yr college, 10=4yr college (bachelor's), 11=5+ years (graduate)
  INCWAGE: 0=no wage income, 999998=missing, 999999=N/A
  RACE: 1=White, 2=Black/African American, 3=AIAN, 4=Chinese, 5=Japanese,
        6=Other Asian/PI, 7=Other, 8=Two major races, 9=Three+ major races
  HISPAN: 0=Not Hispanic, 1=Mexican, 2=Puerto Rican, 3=Cuban, 4=Other,
          9=Not Reported
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

DATA_DIR = os.path.join("module_1", "data")


def _weighted_median(values, weights):
    """Compute the weighted median of an array."""
    sorted_idx = np.argsort(values)
    sorted_values = values[sorted_idx]
    sorted_weights = weights[sorted_idx]
    cumulative = np.cumsum(sorted_weights)
    cutoff = cumulative[-1] / 2.0
    return sorted_values[cumulative >= cutoff][0]


OUTPUT_DIR = os.path.join("module_1", "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

ELECTION_TO_IPUMS = {
    2012: "census_2012_sample.csv.gz",
    2016: "census_2016_sample.csv.gz",
    2020: "census_2020_sample.csv.gz",
    2024: "census_2024_sample.csv.gz",
}


def load_election_data():
    """Load and reshape presidential election data to county-year level vote shares."""
    df = pd.read_csv(os.path.join(DATA_DIR, "election", "countypres_sample.csv"))
    n_raw = len(df)

    # Keep only TOTAL mode rows (excludes absentee/provisional breakdowns in 2020)
    df = df[df["mode"] == "TOTAL"].copy()
    print(f"  Kept {len(df)} of {n_raw} rows (mode == TOTAL)")

    # Drop rows with missing FIPS
    n_before = len(df)
    df = df.dropna(subset=["county_fips"])
    n_dropped = n_before - len(df)
    if n_dropped > 0:
        print(f"  WARNING: Dropped {n_dropped} rows with missing county_fips")

    # Build clean 5-digit FIPS
    df["county_fips"] = df["county_fips"].astype(float).astype(int).astype(str).str.zfill(5)

    # Pivot to get dem/rep votes per county-year
    major = df[df["party"].isin(["DEMOCRAT", "REPUBLICAN"])].copy()
    votes = major.pivot_table(
        index=["county_fips", "year", "state", "county_name", "totalvotes"],
        columns="party",
        values="candidatevotes",
        aggfunc="sum",
    ).reset_index()

    votes.columns.name = None
    votes = votes.rename(columns={"DEMOCRAT": "dem_votes", "REPUBLICAN": "rep_votes"})

    # Check for missing vote counts (counties with only one party reporting)
    missing_dem = votes["dem_votes"].isna().sum()
    missing_rep = votes["rep_votes"].isna().sum()
    if missing_dem > 0 or missing_rep > 0:
        print(f"  WARNING: {missing_dem} counties missing Dem votes, {missing_rep} missing Rep votes")
        votes["dem_votes"] = votes["dem_votes"].fillna(0)
        votes["rep_votes"] = votes["rep_votes"].fillna(0)

    # Two-party vote share
    total_major = votes["dem_votes"] + votes["rep_votes"]
    votes["dem_share_2p"] = votes["dem_votes"] / total_major
    votes["rep_share_2p"] = votes["rep_votes"] / total_major

    # Total vote share (as fraction of all votes cast, including third parties)
    votes["turnout"] = votes["totalvotes"]
    votes["dem_share_total"] = votes["dem_votes"] / votes["turnout"]
    votes["rep_share_total"] = votes["rep_votes"] / votes["turnout"]
    votes["third_party_share"] = 1 - votes["dem_share_total"] - votes["rep_share_total"]

    print(f"  {len(votes)} county-year observations")
    print(f"  {votes['county_fips'].nunique()} unique counties, {votes['year'].nunique()} elections")
    print(f"  Mean third-party share: {votes['third_party_share'].mean():.4f}")

    return votes[["county_fips", "year", "state", "county_name",
                   "dem_votes", "rep_votes", "turnout",
                   "dem_share_2p", "rep_share_2p",
                   "dem_share_total", "rep_share_total", "third_party_share"]]


def load_ipums_county(year):
    """Load IPUMS microdata for a given year and aggregate to county level.

    Variable handling:
      - COUNTYFIP == 0: unidentified county, dropped
      - EDUC == 0: N/A or no schooling, included in denominator for education shares
      - INCWAGE == 999999: N/A (not in universe), excluded from wage calculations
      - INCWAGE == 999998: missing, excluded from wage calculations
      - INCWAGE == 0: no wage income, excluded from wage calculations (we want
        mean/median among wage earners, not the full population)
      - HISPAN == 9: not reported, excluded from Hispanic share calculation
      - RACE: general version, 1-9 scale (see docstring for full coding)
    """
    filename = ELECTION_TO_IPUMS[year]
    filepath = os.path.join(DATA_DIR, "ipums", filename)

    if not os.path.exists(filepath):
        print(f"  WARNING: {filepath} not found, skipping year {year}")
        return None

    print(f"  Loading {filename}...")
    df = pd.read_csv(filepath, compression="gzip")
    n_raw = len(df)

    # Drop unidentified counties (COUNTYFIP == 0)
    df = df[df["COUNTYFIP"] != 0].copy()
    n_dropped = n_raw - len(df)
    if n_dropped > 0:
        print(f"  Dropped {n_dropped} observations with unidentified county (COUNTYFIP == 0)")

    if len(df) == 0:
        print(f"  WARNING: No identified counties in {filename}")
        return None

    # Build 5-digit FIPS from state + county codes
    df["county_fips"] = (
        df["STATEFIP"].astype(str).str.zfill(2)
        + df["COUNTYFIP"].astype(str).str.zfill(3)
    )

    grouped = df.groupby("county_fips")

    agg = pd.DataFrame()
    agg["population"] = grouped["PERWT"].sum()

    # --- Age ---
    agg["mean_age"] = grouped.apply(
        lambda g: np.average(g["AGE"], weights=g["PERWT"]),
    )
    agg["share_age_18_34"] = grouped.apply(
        lambda g: np.average(g["AGE"].between(18, 34), weights=g["PERWT"]),
    )
    agg["share_age_65_plus"] = grouped.apply(
        lambda g: np.average(g["AGE"] >= 65, weights=g["PERWT"]),
    )

    # --- Education ---
    # share_college: bachelor's degree or higher (EDUC >= 10)
    # share_no_hs: did not complete high school (EDUC <= 5, i.e., grade 11 or below)
    agg["share_college"] = grouped.apply(
        lambda g: np.average(g["EDUC"] >= 10, weights=g["PERWT"]),
    )
    agg["share_no_hs"] = grouped.apply(
        lambda g: np.average(g["EDUC"] <= 5, weights=g["PERWT"]),
    )

    # --- Income ---
    # Restrict to wage earners: INCWAGE > 0 and INCWAGE < 999998
    workers = df[(df["INCWAGE"] > 0) & (df["INCWAGE"] < 999998)].copy()
    n_excluded = len(df) - len(workers)
    print(f"  Income: {len(workers)} wage earners, {n_excluded} excluded (N/A, missing, or no wage income)")

    if len(workers) > 0:
        workers_grouped = workers.groupby("county_fips")
        agg["median_wage"] = workers_grouped.apply(
            lambda g: _weighted_median(g["INCWAGE"].values, g["PERWT"].values),
        )
        agg["mean_wage"] = workers_grouped.apply(
            lambda g: np.average(g["INCWAGE"], weights=g["PERWT"]),
        )
    else:
        agg["median_wage"] = np.nan
        agg["mean_wage"] = np.nan

    # --- Race ---
    agg["share_white"] = grouped.apply(
        lambda g: np.average(g["RACE"] == 1, weights=g["PERWT"]),
    )
    agg["share_black"] = grouped.apply(
        lambda g: np.average(g["RACE"] == 2, weights=g["PERWT"]),
    )

    # --- Hispanic origin ---
    # Exclude HISPAN == 9 (Not Reported) from both numerator and denominator
    hispan_valid = df[df["HISPAN"] != 9].copy()
    if len(hispan_valid) < len(df):
        print(f"  Hispanic: excluded {len(df) - len(hispan_valid)} observations with HISPAN == 9 (Not Reported)")
    agg["share_hispanic"] = hispan_valid.groupby("county_fips").apply(
        lambda g: np.average(g["HISPAN"].isin([1, 2, 3, 4]), weights=g["PERWT"]),
    )

    agg["year"] = year
    agg = agg.reset_index()

    print(f"  -> {len(agg)} counties with identified FIPS")
    return agg


def validate_merge(election, census, merged, year):
    """Check that every county in each dataset found exactly one match."""
    elec_fips = set(election[election["year"] == year]["county_fips"])
    cens_fips = set(census["county_fips"])
    matched = elec_fips & cens_fips

    print(f"\n  Year {year} merge validation:")
    print(f"    Election counties:  {len(elec_fips)}")
    print(f"    Census counties:    {len(cens_fips)}")
    print(f"    Matched:            {len(matched)}")
    print(f"    Only in election:   {len(elec_fips - cens_fips)}")
    print(f"    Only in census:     {len(cens_fips - elec_fips)}")

    dupes = merged[merged["year"] == year].groupby("county_fips").size()
    n_dupes = (dupes > 1).sum()
    if n_dupes > 0:
        print(f"    WARNING: {n_dupes} counties have duplicate rows after merge!")
    else:
        print(f"    No duplicate matches (1:1 confirmed)")


def main():
    print("Loading presidential election data...")
    election = load_election_data()
    print(f"  {len(election)} county-year observations across {election['year'].nunique()} elections\n")

    print("Loading and aggregating IPUMS data by county...")
    census_panels = []
    for year in sorted(ELECTION_TO_IPUMS.keys()):
        print(f"\nYear {year}:")
        county_data = load_ipums_county(year)
        if county_data is not None:
            census_panels.append(county_data)

    census = pd.concat(census_panels, ignore_index=True)
    print(f"\n\nTotal census county-year observations: {len(census)}")

    # Merge
    print("\n--- Merging datasets ---")
    panel = election.merge(census, on=["county_fips", "year"], how="inner")
    print(f"Merged panel (before balancing): {len(panel)} county-year observations, {panel['county_fips'].nunique()} counties")

    # Validate each year (pre-balancing)
    for year in sorted(ELECTION_TO_IPUMS.keys()):
        census_year = census[census["year"] == year]
        if len(census_year) > 0:
            validate_merge(election, census_year, panel, year)

    # --- Balance the panel: keep only counties present in all years ---
    print("\n--- Balancing panel ---")
    n_years = len(ELECTION_TO_IPUMS)
    county_year_counts = panel.groupby("county_fips")["year"].nunique()
    balanced_counties = set(county_year_counts[county_year_counts == n_years].index)
    n_before = panel["county_fips"].nunique()
    panel = panel[panel["county_fips"].isin(balanced_counties)].copy()
    n_dropped = n_before - len(balanced_counties)
    print(f"  Kept {len(balanced_counties)} counties present in all {n_years} years")
    print(f"  Dropped {n_dropped} counties with incomplete coverage")
    print(f"  Balanced panel: {len(panel)} county-year observations")

    # --- Final validation ---
    print("\n--- Final panel validation ---")

    dupes = panel.groupby(["county_fips", "year"]).size()
    n_dupes = (dupes > 1).sum()
    assert n_dupes == 0, f"FATAL: {n_dupes} duplicate county-year observations"
    print(f"  No duplicate county-year observations (1:1 confirmed)")

    expected_years = set(ELECTION_TO_IPUMS.keys())
    assert set(panel["year"].unique()) == expected_years, "FATAL: Missing years"
    print(f"  All {len(expected_years)} expected years present")

    for col in ["county_fips", "year", "dem_share_2p", "rep_share_2p",
                 "dem_share_total", "rep_share_total", "third_party_share",
                 "population", "mean_age"]:
        n_na = panel[col].isna().sum()
        if n_na > 0:
            print(f"  WARNING: {n_na} missing values in {col}")
        else:
            print(f"  {col}: no missing values")

    assert panel["dem_share_2p"].between(0, 1).all(), "FATAL: dem_share_2p outside [0, 1]"
    assert panel["rep_share_2p"].between(0, 1).all(), "FATAL: rep_share_2p outside [0, 1]"
    share_sum_2p = (panel["dem_share_2p"] + panel["rep_share_2p"]).round(10)
    assert (share_sum_2p == 1.0).all(), "FATAL: two-party shares don't sum to 1"
    print(f"  Two-party shares valid (sum to 1)")

    share_sum_total = (panel["dem_share_total"] + panel["rep_share_total"] + panel["third_party_share"]).round(10)
    assert (share_sum_total == 1.0).all(), "FATAL: total shares don't sum to 1"
    assert panel["third_party_share"].between(0, 1).all(), "FATAL: third_party_share outside [0, 1]"
    print(f"  Total shares valid (dem + rep + third party sum to 1)")

    assert (panel["population"] > 0).all(), "FATAL: non-positive population"
    print(f"  Population: all positive (min={panel['population'].min():,.0f}, max={panel['population'].max():,.0f})")

    # Save panel
    outpath = os.path.join(OUTPUT_DIR, "county_panel.csv")
    panel.to_csv(outpath, index=False)
    print(f"\nPanel saved to {outpath}")
    print(f"Shape: {panel.shape}")
    print(f"Years: {sorted(panel['year'].unique())}")
    print(f"Unique counties: {panel['county_fips'].nunique()}")

    # ══════════════════════════════════════════════════════════════
    #  EXPLORATORY DATA ANALYSIS
    # ══════════════════════════════════════════════════════════════

    print("\n" + "=" * 60)
    print("EXPLORATORY DATA ANALYSIS")
    print("=" * 60)

    # --- Mean vote share by year ---
    print("\nMean two-party vote share by year:")
    year_means_2p = panel.groupby("year")[["dem_share_2p", "rep_share_2p"]].mean()
    print(year_means_2p.round(4).to_string())

    print("\nMean total vote share by year:")
    year_means_total = panel.groupby("year")[["dem_share_total", "rep_share_total", "third_party_share"]].mean()
    print(year_means_total.round(4).to_string())

    # --- Year-to-year swings (two-party) ---
    print("\nLargest year-to-year swings in Democratic two-party vote share:")
    panel_sorted = panel.sort_values(["county_fips", "year"])
    panel_sorted["dem_2p_lag"] = panel_sorted.groupby("county_fips")["dem_share_2p"].shift(1)
    panel_sorted["swing_2p"] = panel_sorted["dem_share_2p"] - panel_sorted["dem_2p_lag"]
    swings = panel_sorted.dropna(subset=["swing_2p"]).copy()
    swings["abs_swing"] = swings["swing_2p"].abs()
    top_swings = swings.nlargest(20, "abs_swing")[
        ["county_fips", "county_name", "state", "year", "dem_2p_lag", "dem_share_2p", "swing_2p"]
    ]
    print(top_swings.round(4).to_string(index=False))

    # --- Year-to-year swings (total) ---
    print("\nLargest year-to-year swings in Democratic total vote share:")
    panel_sorted["dem_total_lag"] = panel_sorted.groupby("county_fips")["dem_share_total"].shift(1)
    panel_sorted["swing_total"] = panel_sorted["dem_share_total"] - panel_sorted["dem_total_lag"]
    swings_t = panel_sorted.dropna(subset=["swing_total"]).copy()
    swings_t["abs_swing"] = swings_t["swing_total"].abs()
    top_swings_t = swings_t.nlargest(20, "abs_swing")[
        ["county_fips", "county_name", "state", "year", "dem_total_lag", "dem_share_total", "swing_total"]
    ]
    print(top_swings_t.round(4).to_string(index=False))

    # --- Largest change from 2012 ---
    print("\nLargest change from 2012 Democratic two-party vote share (any year):")
    baseline = panel[panel["year"] == 2012][["county_fips", "dem_share_2p"]].rename(
        columns={"dem_share_2p": "dem_2p_2012"}
    )
    panel_with_base = panel.merge(baseline, on="county_fips", how="left")
    panel_with_base["change_from_2012"] = panel_with_base["dem_share_2p"] - panel_with_base["dem_2p_2012"]
    panel_with_base["abs_change"] = panel_with_base["change_from_2012"].abs()

    changes = panel_with_base[panel_with_base["year"] != 2012].copy()
    max_change = changes.loc[changes.groupby("county_fips")["abs_change"].idxmax()]
    top_changes = max_change.nlargest(20, "abs_change")[
        ["county_fips", "county_name", "state", "year", "dem_2p_2012", "dem_share_2p", "change_from_2012"]
    ]
    print(top_changes.round(4).to_string(index=False))

    # ══════════════════════════════════════════════════════════════
    #  GRAPHICS
    # ══════════════════════════════════════════════════════════════

    # --- Plot 1: Two-party vote share over time ---
    fig, ax = plt.subplots(figsize=(8, 5))
    year_means_2p.plot(ax=ax, marker="o", linewidth=2)
    ax.set_title("Mean Two-Party Vote Share Over Time")
    ax.set_xlabel("Year")
    ax.set_ylabel("Vote Share")
    ax.set_ylim(0.3, 0.7)
    ax.legend(["Democratic", "Republican"])
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "vote_share_2p_over_time.png"), dpi=150)
    plt.close()
    print("\nSaved: vote_share_2p_over_time.png")

    # --- Plot 2: Total vote share over time (including third parties) ---
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(year_means_total.index, year_means_total["dem_share_total"], marker="o", linewidth=2, label="Democratic")
    ax.plot(year_means_total.index, year_means_total["rep_share_total"], marker="o", linewidth=2, label="Republican")
    ax.plot(year_means_total.index, year_means_total["third_party_share"], marker="s", linewidth=2, linestyle="--", color="gray", label="Third Party")
    ax.set_title("Mean Total Vote Share Over Time (Including Third Parties)")
    ax.set_xlabel("Year")
    ax.set_ylabel("Vote Share")
    ax.set_ylim(0, 0.7)
    ax.legend()
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "vote_share_total_over_time.png"), dpi=150)
    plt.close()
    print("Saved: vote_share_total_over_time.png")

    # --- Plot 2: Mean demographic variables over time ---
    demo_vars = ["mean_age", "share_college", "share_white", "share_hispanic", "mean_wage"]
    demo_labels = ["Mean Age", "Share College", "Share White", "Share Hispanic", "Mean Wage"]

    demo_means = panel.groupby("year")[demo_vars].mean()

    fig, axes = plt.subplots(2, 3, figsize=(14, 8))
    axes = axes.flatten()

    for i, (var, label) in enumerate(zip(demo_vars, demo_labels)):
        ax = axes[i]
        ax.plot(demo_means.index, demo_means[var], marker="o", linewidth=2, color="steelblue")
        ax.set_title(label)
        ax.set_xlabel("Year")
        ax.grid(True, alpha=0.3)

    axes[5].set_visible(False)

    plt.suptitle("Mean Demographic Variables Over Time (County-Level)", fontsize=14, y=1.02)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "demographics_over_time.png"), dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: demographics_over_time.png")

    print("\nDone!")


if __name__ == "__main__":
    main()
