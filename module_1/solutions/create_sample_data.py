"""Create smaller sample data files filtered to matched counties, 2008-2024.

Reads the merged county panel to get the set of matched county FIPS codes,
then creates:
  - demo_data/countypres_sample.csv  (election data, matched counties only, 2008-2024)
  - demo_data/IPUMS/census_{year}_sample.csv.gz  (IPUMS data, matched counties only,
    limited to key variables, 2008-2024)
"""

import pandas as pd
import os

DATA_DIR = os.path.join(os.path.dirname(__file__), "demo_data")
IPUMS_DIR = os.path.join(DATA_DIR, "IPUMS")

YEARS = [2016, 2020, 2024]
SAMPLE_FRAC = 0.10

IPUMS_COLS = [
    "YEAR", "STATEFIP", "COUNTYFIP", "PERWT",
    "AGE", "EDUC", "INCWAGE", "RACE", "HISPAN",
]

# Also keep RACESING if present (pre-2016 files use it instead of RACE)
IPUMS_COLS_ALT = IPUMS_COLS + ["RACESING"]


def main():
    # Load panel to get matched FIPS
    panel = pd.read_csv(os.path.join(DATA_DIR, "county_panel.csv"), dtype={"county_fips": str})
    panel = panel[panel["year"].isin(YEARS)]
    matched_fips = set(panel["county_fips"].unique())
    print(f"Matched counties (2008-2024): {len(matched_fips)}")

    # --- Election data ---
    print("\nFiltering election data...")
    elec = pd.read_csv(os.path.join(DATA_DIR, "countypres_2000-2024.csv"))
    elec = elec.dropna(subset=["county_fips"])
    elec["county_fips"] = elec["county_fips"].astype(float).astype(int).astype(str).str.zfill(5)
    elec = elec[elec["county_fips"].isin(matched_fips) & elec["year"].isin(YEARS)]
    outpath = os.path.join(DATA_DIR, "countypres_sample.csv")
    elec.to_csv(outpath, index=False)
    print(f"  Saved {len(elec)} rows to {outpath}")

    # --- IPUMS data ---
    for year in YEARS:
        filename = f"census_{year}_raw.csv.gz"
        filepath = os.path.join(IPUMS_DIR, filename)
        if not os.path.exists(filepath):
            print(f"\n  {filename} not found, skipping")
            continue

        print(f"\nProcessing {filename}...")

        # Read only needed columns
        header = pd.read_csv(filepath, compression="gzip", nrows=0).columns.tolist()
        use_cols = [c for c in IPUMS_COLS_ALT if c in header]
        df = pd.read_csv(filepath, compression="gzip", usecols=use_cols)

        # Filter to matched counties
        df = df[df["COUNTYFIP"] != 0].copy()
        df["county_fips"] = (
            df["STATEFIP"].astype(str).str.zfill(2)
            + df["COUNTYFIP"].astype(str).str.zfill(3)
        )
        df = df[df["county_fips"].isin(matched_fips)]
        df = df.drop(columns=["county_fips"])

        # 10% random sample of persons
        df = df.sample(frac=SAMPLE_FRAC, random_state=42)

        outname = f"census_{year}_sample.csv.gz"
        outpath = os.path.join(IPUMS_DIR, outname)
        df.to_csv(outpath, index=False, compression="gzip")
        print(f"  {len(df)} rows, {len(df.columns)} cols -> {outpath}")

    print("\nDone!")


if __name__ == "__main__":
    main()
