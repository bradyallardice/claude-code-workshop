"""Build a county-year panel merging presidential election returns with IPUMS
census demographics, then run basic EDA.

Workshop demo for session 1. The script:
  1. Loads county-level presidential returns (sample) and computes two-party and
     total Democratic/Republican vote shares per county-year.
  2. Aggregates IPUMS person-level microdata to person-weighted county demographics
     for each election year (2012, 2016, 2020, 2024).
  3. Inner-merges the two on (county_fips, year) and balances the panel to counties
     present in all four years.
  4. Prints summaries and the biggest vote-share swings.
  5. Saves the panel and two trend plots to session_1/output/.

Conventions (see CLAUDE.md):
  - pandas for data manipulation; CSV/CSV.GZ inputs.
  - Hardcoded relative paths from the project root; run from AIAgentsCourse/.
  - Function definitions are separate from the bottom execution block so each step
    can be run interactively in VS Code (Shift+Enter).

Analytical choices follow session_1/docs/decisions.md.
"""

import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# --- Paths and constants (relative to project root) ---

ELECTION_PATH = "session_1/data/election/countypres_sample.csv"
IPUMS_TEMPLATE = "session_1/data/ipums/census_{year}_sample.csv.gz"
OUTPUT_DIR = "session_1/output"

YEARS = [2012, 2016, 2020, 2024]
BASELINE_YEAR = 2012

# IPUMS missing/N-A wage codes (INCWAGE): 999998 = missing, 999999 = N/A.
WAGE_MISSING_FLOOR = 999998


# ──────────────────────────────────────────────────────────────────────────────
#  Election data
# ──────────────────────────────────────────────────────────────────────────────

def load_election(path=ELECTION_PATH):
    """Load county presidential returns and compute per-county-year vote shares.

    Keeps only mode == "TOTAL" rows (avoids double-counting per-method breakdowns),
    drops records with missing county_fips, and pivots Democrat/Republican votes
    to one row per county-year. Returns two-party shares, the total-vote Democratic
    share, and turnout.
    """
    df = pd.read_csv(path)

    df = df[df["mode"] == "TOTAL"].copy()
    df = df.dropna(subset=["county_fips"])
    # FIPS arrive as floats like 1276.0; normalize to 5-digit zero-padded strings.
    df["county_fips"] = (
        df["county_fips"].astype(float).astype(int).astype(str).str.zfill(5)
    )

    major = df[df["party"].isin(["DEMOCRAT", "REPUBLICAN"])]
    votes = major.pivot_table(
        index=["county_fips", "year", "state", "county_name", "totalvotes"],
        columns="party",
        values="candidatevotes",
        aggfunc="sum",
    ).reset_index()
    votes.columns.name = None

    votes = votes.rename(columns={"DEMOCRAT": "dem_votes", "REPUBLICAN": "rep_votes"})
    # A county may report only one major party; treat the missing party as 0 votes.
    votes[["dem_votes", "rep_votes"]] = votes[["dem_votes", "rep_votes"]].fillna(0)

    two_party = votes["dem_votes"] + votes["rep_votes"]
    votes["dem_2p_share"] = votes["dem_votes"] / two_party
    votes["rep_2p_share"] = votes["rep_votes"] / two_party
    votes["dem_share_total"] = votes["dem_votes"] / votes["totalvotes"]
    votes["turnout"] = votes["totalvotes"]

    return votes[[
        "county_fips", "year", "state", "county_name",
        "dem_votes", "rep_votes", "dem_2p_share", "rep_2p_share",
        "dem_share_total", "turnout",
    ]]


# ──────────────────────────────────────────────────────────────────────────────
#  IPUMS census data
# ──────────────────────────────────────────────────────────────────────────────

def load_ipums_county(year):
    """Aggregate one year of IPUMS person microdata to person-weighted county stats.

    Drops unidentified counties (COUNTYFIP == 0), builds a 5-digit FIPS, and weights
    every statistic by PERWT. Hispanic share excludes "Not Reported" (HISPAN == 9);
    mean wage uses wage earners only (0 < INCWAGE < 999998). Returns one row per
    county tagged with the election `year`.
    """
    path = IPUMS_TEMPLATE.format(year=year)
    df = pd.read_csv(path, compression="gzip")

    df = df[df["COUNTYFIP"] != 0].copy()
    df["county_fips"] = (
        df["STATEFIP"].astype(str).str.zfill(2)
        + df["COUNTYFIP"].astype(str).str.zfill(3)
    )

    w = df["PERWT"]
    df["_w"] = w
    df["_age_w"] = df["AGE"] * w
    df["_college_w"] = (df["EDUC"] >= 10) * w
    df["_white_w"] = (df["RACE"] == 1) * w

    # Hispanic: numerator HISPAN in 1..4; exclude HISPAN == 9 from num and denom.
    hisp_known = df["HISPAN"] != 9
    df["_hisp_num_w"] = (df["HISPAN"].between(1, 4)) * w
    df["_hisp_den_w"] = hisp_known * w

    # Wage: wage earners only.
    wage_earner = (df["INCWAGE"] > 0) & (df["INCWAGE"] < WAGE_MISSING_FLOOR)
    df["_wage_num_w"] = np.where(wage_earner, df["INCWAGE"] * w, 0.0)
    df["_wage_den_w"] = np.where(wage_earner, w, 0.0)

    g = df.groupby("county_fips")
    s = g.sum(numeric_only=True)

    out = pd.DataFrame({
        "population": s["_w"],
        "mean_age": s["_age_w"] / s["_w"],
        "college_share": s["_college_w"] / s["_w"],
        "white_share": s["_white_w"] / s["_w"],
        "hispanic_share": s["_hisp_num_w"] / s["_hisp_den_w"],
        "mean_wage": s["_wage_num_w"] / s["_wage_den_w"],
    })
    out["year"] = year
    return out.reset_index()


def load_all_ipums(years=YEARS):
    """Stack the per-year county aggregates into one long census frame."""
    return pd.concat([load_ipums_county(y) for y in years], ignore_index=True)


# ──────────────────────────────────────────────────────────────────────────────
#  Merge and balance
# ──────────────────────────────────────────────────────────────────────────────

def validate_merge(election, census, year):
    """Report per-year match counts between election and census FIPS sets."""
    elec_fips = set(election.loc[election["year"] == year, "county_fips"])
    cens_fips = set(census.loc[census["year"] == year, "county_fips"])
    matched = elec_fips & cens_fips
    print(
        f"  {year}: matched={len(matched)} "
        f"election_only={len(elec_fips - cens_fips)} "
        f"census_only={len(cens_fips - elec_fips)}"
    )


def build_panel(election, census, years=YEARS):
    """Inner-merge election and census, then balance to counties in all years."""
    print("Merge validation (per year):")
    for year in years:
        validate_merge(election, census, year)

    merged = election.merge(census, on=["county_fips", "year"], how="inner")

    # No county-year should appear more than once.
    assert not merged.duplicated(["county_fips", "year"]).any(), \
        "Duplicate county-year rows after merge — check for a many-to-many join."

    # Balance: keep only counties observed in every year.
    counts = merged.groupby("county_fips")["year"].nunique()
    balanced_fips = counts[counts == len(years)].index
    n_before = merged["county_fips"].nunique()
    panel = merged[merged["county_fips"].isin(balanced_fips)].copy()
    panel = panel.sort_values(["county_fips", "year"]).reset_index(drop=True)

    print(
        f"\nBalanced panel: kept {panel['county_fips'].nunique()} of {n_before} "
        f"counties present in all {len(years)} years."
    )
    return panel


# ──────────────────────────────────────────────────────────────────────────────
#  EDA
# ──────────────────────────────────────────────────────────────────────────────

def summarize(panel):
    """Print panel shape, mean two-party shares, and demographic means by year."""
    print("=" * 60)
    print("PANEL SUMMARY")
    print("=" * 60)
    print(f"Shape: {panel.shape}")
    print(f"Years: {sorted(panel['year'].unique())}")
    print(f"Counties: {panel['county_fips'].nunique()}")
    print()

    print("Mean two-party vote share by year:")
    print(panel.groupby("year")[["dem_2p_share", "rep_2p_share"]].mean().round(4).to_string())
    print()

    demo_vars = ["mean_age", "college_share", "white_share", "hispanic_share", "mean_wage"]
    print("Mean demographics by year:")
    print(panel.groupby("year")[demo_vars].mean().round(3).to_string())
    print()


def biggest_swings(panel, n=20):
    """Print the largest year-to-year and from-baseline Democratic swings."""
    p = panel.sort_values(["county_fips", "year"]).copy()

    # Year-to-year swing in two-party Dem share, within county.
    p["dem_2p_lag"] = p.groupby("county_fips")["dem_2p_share"].shift(1)
    p["swing"] = p["dem_2p_share"] - p["dem_2p_lag"]
    yty = p.dropna(subset=["swing"]).copy()
    yty["abs_swing"] = yty["swing"].abs()
    print(f"Largest year-to-year swings in Democratic two-party share (top {n}):")
    print(
        yty.nlargest(n, "abs_swing")[
            ["county_fips", "county_name", "state", "year", "dem_2p_lag", "dem_2p_share", "swing"]
        ].round(4).to_string(index=False)
    )
    print()

    # Largest change from the baseline year (per county, any later year).
    base = panel[panel["year"] == BASELINE_YEAR][["county_fips", "dem_2p_share"]].rename(
        columns={"dem_2p_share": "dem_2p_base"}
    )
    wb = panel.merge(base, on="county_fips", how="left")
    wb = wb[wb["year"] != BASELINE_YEAR].copy()
    wb["change_from_base"] = wb["dem_2p_share"] - wb["dem_2p_base"]
    wb["abs_change"] = wb["change_from_base"].abs()
    peak = wb.loc[wb.groupby("county_fips")["abs_change"].idxmax()]
    print(f"Largest change from {BASELINE_YEAR} Democratic two-party share (top {n}):")
    print(
        peak.nlargest(n, "abs_change")[
            ["county_fips", "county_name", "state", "year", "dem_2p_base", "dem_2p_share", "change_from_base"]
        ].round(4).to_string(index=False)
    )
    print()


# ──────────────────────────────────────────────────────────────────────────────
#  Plots
# ──────────────────────────────────────────────────────────────────────────────

def plot_vote_share(panel, output_dir=OUTPUT_DIR):
    """Line plot of mean two-party Dem/Rep vote share over time."""
    year_means = panel.groupby("year")[["dem_2p_share", "rep_2p_share"]].mean()
    fig, ax = plt.subplots(figsize=(8, 5))
    year_means.plot(ax=ax, marker="o", linewidth=2)
    ax.set_title("Mean Two-Party Vote Share Over Time")
    ax.set_xlabel("Year")
    ax.set_ylabel("Vote Share")
    ax.set_ylim(0.3, 0.7)
    ax.legend(["Democratic", "Republican"])
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    path = os.path.join(output_dir, "vote_share_2p_over_time.png")
    plt.savefig(path, dpi=150)
    plt.close()
    print(f"Saved: {path}")


def plot_demographics(panel, output_dir=OUTPUT_DIR):
    """2x3 grid of mean demographic variables over time (6th axis hidden)."""
    demo_vars = ["mean_age", "college_share", "white_share", "hispanic_share", "mean_wage"]
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
    path = os.path.join(output_dir, "demographics_over_time.png")
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"Saved: {path}")


# ──────────────────────────────────────────────────────────────────────────────
#  Execution (runnable top-to-bottom or interactively, line by line)
# ──────────────────────────────────────────────────────────────────────────────

os.makedirs(OUTPUT_DIR, exist_ok=True)

election = load_election()
census = load_all_ipums()
panel = build_panel(election, census)

panel_path = os.path.join(OUTPUT_DIR, "county_panel.csv")
panel.to_csv(panel_path, index=False)
print(f"Saved: {panel_path}\n")

summarize(panel)
biggest_swings(panel)

plot_vote_share(panel)
plot_demographics(panel)

print("\nDone!")
