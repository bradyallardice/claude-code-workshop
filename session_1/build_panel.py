"""
Build a county-year panel merging MIT Election Lab presidential returns with
IPUMS ACS microdata, then run basic EDA. Saves panel CSV and plots to
session_1/output/.

Run from project root: python session_1/build_panel.py
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

os.makedirs("session_1/output", exist_ok=True)

# ── 1. Election returns ───────────────────────────────────────────────────────

elec_raw = pd.read_csv("session_1/data/election/countypres_sample.csv")

# Some states report disaggregated voting modes (early vote, election day, etc.)
# instead of a single TOTAL row. Strategy: use TOTAL rows where they exist;
# for other county-years, sum across all modes to reconstruct the county total.
has_total = elec_raw[elec_raw["mode"] == "TOTAL"][["county_fips", "year"]].drop_duplicates()
has_total["_has_total"] = True

elec_tagged = elec_raw.merge(has_total, on=["county_fips", "year"], how="left")
elec_clean = elec_tagged[
    ((elec_tagged["_has_total"] == True) & (elec_tagged["mode"] == "TOTAL"))
    | (elec_tagged["_has_total"] != True)
].copy()

# Sum votes by county-year-party (handles residual duplicates from NaN-mode rows)
dem = (
    elec_clean[elec_clean["party"] == "DEMOCRAT"]
    .groupby(["county_fips", "year"])["candidatevotes"]
    .sum()
    .rename("dem_votes")
)
rep = (
    elec_clean[elec_clean["party"] == "REPUBLICAN"]
    .groupby(["county_fips", "year"])["candidatevotes"]
    .sum()
    .rename("rep_votes")
)
total_votes = (
    elec_clean.groupby(["county_fips", "year"])["totalvotes"].max().rename("total_votes")
)

elec = pd.concat([dem, rep, total_votes], axis=1).reset_index()
elec["dem_2p_share"] = elec["dem_votes"] / (elec["dem_votes"] + elec["rep_votes"])
elec["rep_2p_share"] = 1.0 - elec["dem_2p_share"]
elec["dem_total_share"] = elec["dem_votes"] / elec["total_votes"]
elec["rep_total_share"] = elec["rep_votes"] / elec["total_votes"]

print(f"Election rows: {len(elec)}  |  counties: {elec.county_fips.nunique()}"
      f"  |  years: {sorted(elec.year.unique())}")


# ── 2. IPUMS census microdata ─────────────────────────────────────────────────

CENSUS_YEARS = [2012, 2016, 2020, 2024]

# IPUMS EDUC codes: 10 = bachelor's degree, 11 = graduate/professional degree
COLLEGE_EDUC_MIN = 10

# IPUMS INCWAGE: 999999 = N/A; exclude non-workers (0) for mean wage
INCWAGE_NA = 999990


def load_ipums(year):
    return pd.read_csv(f"session_1/data/IPUMS/census_{year}_sample.csv.gz")


def aggregate_to_county(df):
    """Collapse person-level IPUMS records to weighted county-level shares."""
    df = df.copy()
    df["county_fips"] = df["STATEFIP"] * 1000 + df["COUNTYFIP"]

    # Person-level demographic flags
    df["white_nonhisp"] = (df["RACE"] == 1) & (df["HISPAN"] == 0)
    df["hispanic"] = df["HISPAN"] >= 1
    df["black_nonhisp"] = (df["RACE"] == 2) & (df["HISPAN"] == 0)
    df["age65plus"] = df["AGE"] >= 65

    def wgt_share(g, col):
        return (g[col] * g["PERWT"]).sum() / g["PERWT"].sum()

    demo = (
        df.groupby("county_fips")
        .apply(
            lambda g: pd.Series(
                {
                    "pct_white_nonhisp": wgt_share(g, "white_nonhisp"),
                    "pct_hispanic": wgt_share(g, "hispanic"),
                    "pct_black_nonhisp": wgt_share(g, "black_nonhisp"),
                    "pct_age65plus": wgt_share(g, "age65plus"),
                    "pop_est": g["PERWT"].sum(),
                }
            )
        )
        .reset_index()
    )

    # Education among adults 25+ only
    adults = df[df["AGE"] >= 25].copy()
    adults["college"] = (adults["EDUC"] >= COLLEGE_EDUC_MIN).astype(float)
    educ = (
        adults.groupby("county_fips")
        .apply(lambda g: pd.Series({"pct_college": wgt_share(g, "college")}))
        .reset_index()
    )

    # Mean wage among employed adults with valid wages
    workers = df[(df["AGE"] >= 25) & (df["INCWAGE"] > 0) & (df["INCWAGE"] < INCWAGE_NA)]
    inc = (
        workers.groupby("county_fips")
        .apply(
            lambda g: pd.Series(
                {"mean_incwage": (g["INCWAGE"] * g["PERWT"]).sum() / g["PERWT"].sum()}
            )
        )
        .reset_index()
    )

    return demo.merge(educ, on="county_fips", how="left").merge(
        inc, on="county_fips", how="left"
    )


census_parts = []
for yr in CENSUS_YEARS:
    print(f"  Loading IPUMS {yr}...", end=" ")
    raw = load_ipums(yr)
    agg = aggregate_to_county(raw)
    agg["year"] = yr
    census_parts.append(agg)
    print(f"{len(agg)} counties")

census = pd.concat(census_parts, ignore_index=True)


# ── 3. Merge into county-year panel ──────────────────────────────────────────

panel = elec.merge(census, on=["county_fips", "year"], how="inner")
panel.to_csv("session_1/output/county_panel.csv", index=False)
print(f"\nPanel: {panel.shape[0]} rows, {panel.county_fips.nunique()} counties, "
      f"years {sorted(panel.year.unique())}")


# ── 4. Summary statistics ─────────────────────────────────────────────────────

print("\n=== Summary Statistics ===")
summary_cols = [
    "dem_2p_share", "rep_2p_share", "dem_total_share", "rep_total_share",
    "pct_white_nonhisp", "pct_hispanic", "pct_black_nonhisp",
    "pct_college", "pct_age65plus", "mean_incwage",
]
print(panel[summary_cols].describe().round(3).to_string())


# ── 5. Biggest swings between consecutive elections ───────────────────────────

panel_s = panel.sort_values(["county_fips", "year"])
panel_s["dem_2p_swing"] = panel_s.groupby("county_fips")["dem_2p_share"].diff()
swings = panel_s.dropna(subset=["dem_2p_swing"]).copy()

# Attach county name for readability
county_names = (
    elec_raw[["county_fips", "county_name", "state_po"]]
    .drop_duplicates(subset=["county_fips"])
)
swings = swings.merge(county_names, on="county_fips", how="left")

display_cols = ["state_po", "county_name", "year", "dem_2p_swing", "dem_2p_share"]

print("\n=== Top 10 Swings Toward Democrats (Δ dem 2-party share) ===")
top_dem = swings.nlargest(10, "dem_2p_swing")[display_cols]
print(top_dem.to_string(index=False))

print("\n=== Top 10 Swings Toward Republicans ===")
top_rep = swings.nsmallest(10, "dem_2p_swing")[display_cols]
print(top_rep.to_string(index=False))


# ── 6. Plots ──────────────────────────────────────────────────────────────────

YEARS = sorted(panel["year"].unique())


def year_agg(metric, agg_fn="mean"):
    return panel.groupby("year")[metric].agg(agg_fn)


# — Plot 1: National mean 2-party vote shares over time —
fig, ax = plt.subplots(figsize=(8, 5))
ax.plot(YEARS, year_agg("dem_2p_share") * 100, marker="o", color="#0015BC", label="Democrat")
ax.plot(YEARS, year_agg("rep_2p_share") * 100, marker="o", color="#E81B23", label="Republican")
ax.yaxis.set_major_formatter(mtick.PercentFormatter())
ax.set_xlabel("Election year")
ax.set_ylabel("Mean county 2-party vote share")
ax.set_title("Mean County-Level 2-Party Presidential Vote Share")
ax.legend()
ax.set_xticks(YEARS)
plt.tight_layout()
plt.savefig("session_1/output/vote_share_2p_over_time.png", dpi=150)
plt.close()
print("Saved vote_share_2p_over_time.png")


# — Plot 2: Distribution of Dem 2-party share by year (box plots) —
fig, ax = plt.subplots(figsize=(9, 5))
data_by_year = [panel.loc[panel["year"] == yr, "dem_2p_share"].dropna() * 100 for yr in YEARS]
bp = ax.boxplot(data_by_year, labels=YEARS, patch_artist=True,
                medianprops={"color": "black", "linewidth": 2})
for patch in bp["boxes"]:
    patch.set_facecolor("#AABFDD")
ax.axhline(50, color="gray", linestyle="--", linewidth=0.8, label="50%")
ax.yaxis.set_major_formatter(mtick.PercentFormatter())
ax.set_xlabel("Election year")
ax.set_ylabel("Dem 2-party share")
ax.set_title("Distribution of County Dem 2-Party Share by Year")
ax.legend()
plt.tight_layout()
plt.savefig("session_1/output/dem_2p_distribution.png", dpi=150)
plt.close()
print("Saved dem_2p_distribution.png")


# — Plot 3: Key demographics over time —
fig, axes = plt.subplots(2, 2, figsize=(11, 8))
demo_vars = [
    ("pct_white_nonhisp", "% White non-Hispanic", "#4477AA"),
    ("pct_college", "% College educated (25+)", "#66AA55"),
    ("pct_age65plus", "% Age 65+", "#AA5544"),
    ("mean_incwage", "Mean wage income ($)", "#AA7700"),
]
for ax, (col, label, color) in zip(axes.flat, demo_vars):
    vals = year_agg(col)
    ax.plot(YEARS, vals, marker="o", color=color)
    ax.set_xlabel("Year")
    ax.set_title(label)
    ax.set_xticks(YEARS)
    if "pct_" in col:
        ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1))
    else:
        ax.yaxis.set_major_formatter(mtick.FuncFormatter(lambda x, _: f"${x:,.0f}"))
plt.suptitle("County-Level Demographic Trends", fontsize=13, y=1.01)
plt.tight_layout()
plt.savefig("session_1/output/demographics_over_time.png", dpi=150, bbox_inches="tight")
plt.close()
print("Saved demographics_over_time.png")


# — Plot 4: Scatter — college share vs. Dem 2-party share (most recent year) —
yr_latest = max(YEARS)
sub = panel[panel["year"] == yr_latest].dropna(subset=["pct_college", "dem_2p_share"])
fig, ax = plt.subplots(figsize=(8, 6))
sc = ax.scatter(
    sub["pct_college"] * 100, sub["dem_2p_share"] * 100,
    alpha=0.4, s=20, c="#0015BC",
)
# OLS trendline
m, b = np.polyfit(sub["pct_college"] * 100, sub["dem_2p_share"] * 100, 1)
xs = np.linspace(sub["pct_college"].min() * 100, sub["pct_college"].max() * 100, 100)
ax.plot(xs, m * xs + b, color="black", linewidth=1.5, linestyle="--")
ax.axhline(50, color="gray", linestyle=":", linewidth=0.8)
ax.xaxis.set_major_formatter(mtick.PercentFormatter())
ax.yaxis.set_major_formatter(mtick.PercentFormatter())
ax.set_xlabel("% College educated (adults 25+)")
ax.set_ylabel("Dem 2-party share")
ax.set_title(f"Education vs. Dem Vote Share ({yr_latest})")
plt.tight_layout()
plt.savefig("session_1/output/college_vs_dem_share.png", dpi=150)
plt.close()
print("Saved college_vs_dem_share.png")

print("\nAll outputs saved to session_1/output/")
