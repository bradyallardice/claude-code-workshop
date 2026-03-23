"""Create sample data files for the workshop exercises.

Finds counties that appear in both the election data and IPUMS for at least
one year (2012-2024), excluding Alaska and Hawaii. Then creates:
  - module_1/data/election/countypres_sample.csv (election data, matched counties, all years)
  - module_1/data/ipums/census_{year}_sample.csv.gz (10% person-level sample, matched counties)

The resulting sample is intentionally unbalanced — not every county appears in
every IPUMS year — so that students encounter this as a data quality issue.

Run from the project root: python module_1/scripts/create_sample_data.py
"""

import pandas as pd
import os

DATA_DIR = os.path.join("module_1", "data")
IPUMS_DIR = os.path.join(DATA_DIR, "IPUMS")

YEARS = [2012, 2016, 2020, 2024]
SAMPLE_FRAC = 0.10
EXCLUDE_STATES = [2, 15]  # Alaska, Hawaii

IPUMS_COLS = [
    "YEAR", "STATEFIP", "COUNTYFIP", "PUMA", "PERWT",
    "AGE", "EDUC", "INCWAGE", "RACE", "HISPAN",
]


def main():
    # --- Find counties in both datasets for at least one year ---
    print("Finding matched counties across datasets...")

    elec = pd.read_csv(os.path.join(DATA_DIR, "countypres_2000-2024.csv"))
    elec = elec.dropna(subset=["county_fips"])
    elec["county_fips"] = elec["county_fips"].astype(int).astype(str).str.zfill(5)
    elec = elec[~elec["county_fips"].str[:2].isin([str(s).zfill(2) for s in EXCLUDE_STATES])]

    matched_any_year = set()
    for yr in YEARS:
        e_fips = set(elec[elec["year"] == yr]["county_fips"].unique())

        filepath = os.path.join(IPUMS_DIR, f"census_{yr}_raw.csv.gz")
        if not os.path.exists(filepath):
            print(f"  WARNING: {filepath} not found, skipping year {yr}")
            continue

        df = pd.read_csv(filepath, compression="gzip", usecols=["STATEFIP", "COUNTYFIP"])
        df = df[(df["COUNTYFIP"] != 0) & (~df["STATEFIP"].isin(EXCLUDE_STATES))]
        df["county_fips"] = df["STATEFIP"].astype(str).str.zfill(2) + df["COUNTYFIP"].astype(str).str.zfill(3)
        i_fips = set(df["county_fips"].unique())

        both = e_fips & i_fips
        matched_any_year.update(both)
        print(f"  {yr}: election={len(e_fips)}, IPUMS={len(i_fips)}, both={len(both)}")

    print(f"  Counties in at least one year: {len(matched_any_year)}")

    # --- Save election sample ---
    print("\nCreating election sample...")
    elec_sample = elec[elec["county_fips"].isin(matched_any_year) & elec["year"].isin(YEARS)]
    outpath = os.path.join(DATA_DIR, "countypres_sample.csv")
    elec_sample.to_csv(outpath, index=False)
    print(f"  {len(elec_sample)} rows, {elec_sample['county_fips'].nunique()} counties -> {outpath}")
    for yr in YEARS:
        n = elec_sample[elec_sample["year"] == yr]["county_fips"].nunique()
        print(f"    {yr}: {n} counties")

    # --- Save IPUMS samples ---
    print("\nCreating IPUMS samples...")
    for yr in YEARS:
        filepath = os.path.join(IPUMS_DIR, f"census_{yr}_raw.csv.gz")
        if not os.path.exists(filepath):
            print(f"  {yr}: raw file not found, skipping")
            continue

        header = pd.read_csv(filepath, compression="gzip", nrows=0).columns.tolist()
        use_cols = [c for c in IPUMS_COLS if c in header]

        print(f"  {yr}: loading {os.path.basename(filepath)}...")
        df = pd.read_csv(filepath, compression="gzip", usecols=use_cols)

        # Filter to matched counties (excl AK/HI)
        df = df[(df["COUNTYFIP"] != 0) & (~df["STATEFIP"].isin(EXCLUDE_STATES))].copy()
        df["county_fips"] = df["STATEFIP"].astype(str).str.zfill(2) + df["COUNTYFIP"].astype(str).str.zfill(3)
        df = df[df["county_fips"].isin(matched_any_year)]
        n_counties = df["county_fips"].nunique()
        df = df.drop(columns=["county_fips"])

        # 10% random sample of persons
        df = df.sample(frac=SAMPLE_FRAC, random_state=42)

        outpath = os.path.join(IPUMS_DIR, f"census_{yr}_sample.csv.gz")
        df.to_csv(outpath, index=False, compression="gzip")
        print(f"    {len(df):,} rows, {n_counties} counties, {len(use_cols)} cols -> {outpath}")

    print("\nDone!")


if __name__ == "__main__":
    main()
