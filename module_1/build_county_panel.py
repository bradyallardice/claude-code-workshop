"""Build a county-level panel joining presidential vote shares with IPUMS demographics.

Reads:
  - demo_data/countypres_2000-2024.csv (MIT Election Data + Science Lab)
  - demo_data/IPUMS/census_{year}_raw.csv.gz (IPUMS USA microdata)

Outputs:
  - demo_data/county_panel.csv

The script matches election years to the nearest IPUMS ACS/census file,
aggregates person-level IPUMS records to county-level demographics using
person weights, and merges with county-level vote shares. Only counties
identified in both datasets are kept, and the script verifies that every
county in each dataset finds exactly one match in the other.
"""

import pandas as pd
import numpy as np
import os
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "demo_data")

# Map each election year to the IPUMS file to use
ELECTION_TO_IPUMS = {
    2000: "census_2000_raw.csv.gz",
    2004: "census_2004_raw.csv.gz",
    2008: "census_2008_raw.csv.gz",
    2012: "census_2012_raw.csv.gz",
    2016: "census_2016_raw.csv.gz",
    2020: "census_2020_raw.csv.gz",
    2024: "census_2024_raw.csv.gz",
}


def load_election_data():
    """Load and reshape presidential election data to county-year level vote shares."""
    df = pd.read_csv(os.path.join(DATA_DIR, "countypres_2000-2024.csv"))

    # Keep only TOTAL mode rows and major parties
    df = df[df["mode"] == "TOTAL"].copy()

    # Drop rows with missing FIPS, then build clean 5-digit zero-padded string
    df = df.dropna(subset=["county_fips"])
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

    # Two-party vote share
    votes["dem_share"] = votes["dem_votes"] / (votes["dem_votes"] + votes["rep_votes"])
    votes["rep_share"] = votes["rep_votes"] / (votes["dem_votes"] + votes["rep_votes"])
    votes["turnout"] = votes["totalvotes"]

    return votes[["county_fips", "year", "state", "county_name",
                   "dem_votes", "rep_votes", "dem_share", "rep_share", "turnout"]]


def load_ipums_county(year):
    """Load IPUMS microdata for a given year and aggregate to county level.

    Drops observations with COUNTYFIP == 0 (county not identified).
    Constructs 5-digit FIPS from STATEFIP and COUNTYFIP.
    """
    filename = ELECTION_TO_IPUMS[year]
    filepath = os.path.join(DATA_DIR, "IPUMS", filename)

    if not os.path.exists(filepath):
        print(f"  WARNING: {filepath} not found, skipping year {year}")
        return None

    print(f"  Loading {filename}...")
    df = pd.read_csv(filepath, compression="gzip")

    # Skip files without county identifiers
    if "COUNTYFIP" not in df.columns:
        print(f"  WARNING: No COUNTYFIP column in {filename}, skipping year {year}")
        return None

    # Drop unidentified counties
    df = df[df["COUNTYFIP"] != 0].copy()

    if len(df) == 0:
        print(f"  WARNING: No identified counties in {filename}")
        return None

    # Build 5-digit FIPS
    df["county_fips"] = (
        df["STATEFIP"].astype(str).str.zfill(2)
        + df["COUNTYFIP"].astype(str).str.zfill(3)
    )

    # Weight
    w = df["PERWT"]

    # --- Aggregate demographics ---

    # Helper: weighted mean
    def wmean(col):
        return lambda x: np.average(x[col], weights=x["PERWT"])

    # Helper: weighted share where condition is true
    def wshare(mask):
        return np.average(mask, weights=w[mask.index])

    grouped = df.groupby("county_fips")

    agg = pd.DataFrame()
    agg["population"] = grouped["PERWT"].sum()

    # Age
    agg["mean_age"] = grouped.apply(
        lambda g: np.average(g["AGE"], weights=g["PERWT"])    )
    agg["share_age_18_34"] = grouped.apply(
        lambda g: np.average(g["AGE"].between(18, 34), weights=g["PERWT"]),
    )
    agg["share_age_65_plus"] = grouped.apply(
        lambda g: np.average(g["AGE"] >= 65, weights=g["PERWT"]),
    )

    # Education (EDUC: 0-11 scale; 6+ = some college, 10+ = bachelor's+)
    agg["share_college"] = grouped.apply(
        lambda g: np.average(g["EDUC"] >= 10, weights=g["PERWT"]),
    )
    agg["share_no_hs"] = grouped.apply(
        lambda g: np.average(g["EDUC"] <= 2, weights=g["PERWT"]),
    )

    # Employment (EMPSTAT: 1=employed, 2=unemployed, 3=not in labor force)
    labor_force = df[df["EMPSTAT"].isin([1, 2])]
    unemp_rate = labor_force.groupby("county_fips").apply(
        lambda g: np.average(g["EMPSTAT"] == 2, weights=g["PERWT"]),
    )
    agg["unemployment_rate"] = unemp_rate

    agg["share_labor_force"] = grouped.apply(
        lambda g: np.average(g["LABFORCE"] == 2, weights=g["PERWT"]),
    )

    # Income (INCWAGE: wage income; top-coded values vary by year, 999999 = N/A)
    workers = df[(df["INCWAGE"] > 0) & (df["INCWAGE"] < 999998)]
    agg["median_wage"] = workers.groupby("county_fips")["INCWAGE"].median()
    agg["mean_wage"] = workers.groupby("county_fips").apply(
        lambda g: np.average(g["INCWAGE"], weights=g["PERWT"]),
    )

    # Race — RACESING (1=White,2=Black) if available, else RACE (1=White,2=Black)
    race_col = "RACESING" if "RACESING" in df.columns else "RACE"
    agg["share_white"] = grouped.apply(
        lambda g: np.average(g[race_col] == 1, weights=g["PERWT"]),
    )
    agg["share_black"] = grouped.apply(
        lambda g: np.average(g[race_col] == 2, weights=g["PERWT"]),
    )
    agg["share_hispanic"] = grouped.apply(
        lambda g: np.average(g["HISPAN"] > 0, weights=g["PERWT"]),
    )

    # Poverty (POVERTY: % of poverty line; 0 = N/A)
    poverty_valid = df[df["POVERTY"] > 0]
    agg["share_poverty"] = poverty_valid.groupby("county_fips").apply(
        lambda g: np.average(g["POVERTY"] < 100, weights=g["PERWT"]),
    )

    agg["year"] = year
    agg = agg.reset_index()

    print(f"  -> {len(agg)} counties with identified FIPS")
    return agg


def validate_merge(election, census, merged, year):
    """Check that every county in each dataset found exactly one match."""
    elec_fips = set(election[election["year"] == year]["county_fips"])
    cens_fips = set(census["county_fips"])
    merged_fips = set(merged[merged["year"] == year]["county_fips"])

    only_election = elec_fips - cens_fips
    only_census = cens_fips - elec_fips
    matched = elec_fips & cens_fips

    print(f"\n  Year {year} merge validation:")
    print(f"    Election counties:  {len(elec_fips)}")
    print(f"    Census counties:    {len(cens_fips)}")
    print(f"    Matched:            {len(matched)}")
    print(f"    Only in election:   {len(only_election)}")
    print(f"    Only in census:     {len(only_census)}")

    # Check for duplicates (should be zero)
    dupes = merged[merged["year"] == year].groupby("county_fips").size()
    n_dupes = (dupes > 1).sum()
    if n_dupes > 0:
        print(f"    WARNING: {n_dupes} counties have duplicate rows after merge!")
    else:
        print(f"    No duplicate matches (1:1 confirmed)")

    return only_election, only_census


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
    print(f"Merged panel: {len(panel)} county-year observations")

    # Validate each year
    all_only_election = set()
    all_only_census = set()
    for year in sorted(ELECTION_TO_IPUMS.keys()):
        census_year = census[census["year"] == year]
        if len(census_year) > 0:
            oe, oc = validate_merge(election, census_year, panel, year)
            all_only_election.update(oe)
            all_only_census.update(oc)

    # Save
    outpath = os.path.join(DATA_DIR, "county_panel.csv")
    panel.to_csv(outpath, index=False)
    print(f"\nPanel saved to {outpath}")
    print(f"Shape: {panel.shape}")
    print(f"Years: {sorted(panel['year'].unique())}")
    print(f"Unique counties: {panel['county_fips'].nunique()}")


if __name__ == "__main__":
    main()
