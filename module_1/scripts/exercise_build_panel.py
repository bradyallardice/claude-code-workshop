"""Exercise: Build a county-level panel joining election returns with IPUMS demographics.

This script works but has no validation, no logging, and no edge case handling.
Your task: ask Claude Code to improve it.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

DATA_DIR = os.path.join("module_1", "data")
OUTPUT_DIR = os.path.join("module_1", "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Load election data ---

elec = pd.read_csv(os.path.join(DATA_DIR, "countypres_sample.csv"))
elec = elec[elec["mode"] == "TOTAL"].copy()
elec = elec.dropna(subset=["county_fips"])
elec["county_fips"] = elec["county_fips"].astype(float).astype(int).astype(str).str.zfill(5)

major = elec[elec["party"].isin(["DEMOCRAT", "REPUBLICAN"])].copy()
votes = major.pivot_table(
    index=["county_fips", "year", "state", "county_name", "totalvotes"],
    columns="party",
    values="candidatevotes",
    aggfunc="sum",
).reset_index()

votes.columns.name = None
votes = votes.rename(columns={"DEMOCRAT": "dem_votes", "REPUBLICAN": "rep_votes"})
votes["dem_share"] = votes["dem_votes"] / (votes["dem_votes"] + votes["rep_votes"])
votes["rep_share"] = votes["rep_votes"] / (votes["dem_votes"] + votes["rep_votes"])
votes["turnout"] = votes["totalvotes"]

election = votes[["county_fips", "year", "state", "county_name",
                   "dem_votes", "rep_votes", "dem_share", "rep_share", "turnout"]]

# --- Load and aggregate IPUMS data ---

ELECTION_TO_IPUMS = {
    2012: "census_2012_sample.csv.gz",
    2016: "census_2016_sample.csv.gz",
    2020: "census_2020_sample.csv.gz",
    2024: "census_2024_sample.csv.gz",
}

census_panels = []
for year, filename in ELECTION_TO_IPUMS.items():
    filepath = os.path.join(DATA_DIR, "IPUMS", filename)
    df = pd.read_csv(filepath, compression="gzip")
    df = df[df["COUNTYFIP"] != 0].copy()

    df["county_fips"] = (
        df["STATEFIP"].astype(str).str.zfill(2)
        + df["COUNTYFIP"].astype(str).str.zfill(3)
    )

    grouped = df.groupby("county_fips")
    agg = pd.DataFrame()
    agg["population"] = grouped["PERWT"].sum()
    agg["mean_age"] = grouped.apply(lambda g: np.average(g["AGE"], weights=g["PERWT"]))
    agg["share_college"] = grouped.apply(lambda g: np.average(g["EDUC"] >= 10, weights=g["PERWT"]))
    agg["share_white"] = grouped.apply(lambda g: np.average(g["RACE"] == 1, weights=g["PERWT"]))
    agg["share_hispanic"] = grouped.apply(lambda g: np.average(g["HISPAN"] > 0, weights=g["PERWT"]))
    agg["mean_wage"] = grouped.apply(lambda g: np.average(g["INCWAGE"], weights=g["PERWT"]))
    agg["year"] = year
    agg = agg.reset_index()
    census_panels.append(agg)

census = pd.concat(census_panels, ignore_index=True)

# --- Merge and save ---

panel = election.merge(census, on=["county_fips", "year"], how="inner")
panel.to_csv(os.path.join(DATA_DIR, "county_panel.csv"), index=False)

# ══════════════════════════════════════════════════════════════════
#  EXPLORATORY DATA ANALYSIS
# ══════════════════════════════════════════════════════════════════

print("=" * 60)
print("PANEL SUMMARY")
print("=" * 60)
print(f"Shape: {panel.shape}")
print(f"Years: {sorted(panel['year'].unique())}")
print(f"Counties: {panel['county_fips'].nunique()}")
print()

# --- Mean vote share by year ---
print("Mean two-party vote share by year:")
year_means = panel.groupby("year")[["dem_share", "rep_share"]].mean()
print(year_means.round(4).to_string())
print()

# --- Year-to-year swings (biggest in absolute terms) ---
print("Largest year-to-year swings in Democratic vote share:")
panel_sorted = panel.sort_values(["county_fips", "year"])
panel_sorted["dem_share_lag"] = panel_sorted.groupby("county_fips")["dem_share"].shift(1)
panel_sorted["swing"] = panel_sorted["dem_share"] - panel_sorted["dem_share_lag"]
swings = panel_sorted.dropna(subset=["swing"]).copy()
swings["abs_swing"] = swings["swing"].abs()
top_swings = swings.nlargest(20, "abs_swing")[
    ["county_fips", "county_name", "state", "year", "dem_share_lag", "dem_share", "swing"]
]
print(top_swings.round(4).to_string(index=False))
print()

# --- Largest change from 2012 baseline ---
print("Largest change from 2012 Democratic vote share (any year):")
baseline = panel[panel["year"] == 2012][["county_fips", "dem_share"]].rename(
    columns={"dem_share": "dem_share_2012"}
)
panel_with_base = panel.merge(baseline, on="county_fips", how="left")
panel_with_base["change_from_2012"] = panel_with_base["dem_share"] - panel_with_base["dem_share_2012"]
panel_with_base["abs_change"] = panel_with_base["change_from_2012"].abs()

# Exclude 2012 itself
changes = panel_with_base[panel_with_base["year"] != 2012].copy()
# Largest absolute change per county (across any year)
max_change = changes.loc[changes.groupby("county_fips")["abs_change"].idxmax()]
top_changes = max_change.nlargest(20, "abs_change")[
    ["county_fips", "county_name", "state", "year", "dem_share_2012", "dem_share", "change_from_2012"]
]
print(top_changes.round(4).to_string(index=False))
print()

# ══════════════════════════════════════════════════════════════════
#  GRAPHICS
# ══════════════════════════════════════════════════════════════════

# --- Plot 1: Mean vote share over time ---
fig, ax = plt.subplots(figsize=(8, 5))
year_means.plot(ax=ax, marker="o", linewidth=2)
ax.set_title("Mean Two-Party Vote Share Over Time")
ax.set_xlabel("Year")
ax.set_ylabel("Vote Share")
ax.set_ylim(0.3, 0.7)
ax.legend(["Democratic", "Republican"])
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(os.path.join(OUTPUT_DIR, "vote_share_over_time.png"), dpi=150)
plt.close()
print("Saved: vote_share_over_time.png")

# --- Plot 2: Mean demographic variables over time ---
demo_vars = ["mean_age", "share_college", "share_white", "share_hispanic", "mean_wage"]
demo_labels = ["Mean Age", "Share College", "Share White", "Share Hispanic", "Mean Wage"]

# Normalize mean_wage to fit on same scale
demo_means = panel.groupby("year")[demo_vars].mean()

fig, axes = plt.subplots(2, 3, figsize=(14, 8))
axes = axes.flatten()

for i, (var, label) in enumerate(zip(demo_vars, demo_labels)):
    ax = axes[i]
    ax.plot(demo_means.index, demo_means[var], marker="o", linewidth=2, color="steelblue")
    ax.set_title(label)
    ax.set_xlabel("Year")
    ax.grid(True, alpha=0.3)

# Hide the 6th subplot
axes[5].set_visible(False)

plt.suptitle("Mean Demographic Variables Over Time (County-Level)", fontsize=14, y=1.02)
plt.tight_layout()
plt.savefig(os.path.join(OUTPUT_DIR, "demographics_over_time.png"), dpi=150, bbox_inches="tight")
plt.close()
print("Saved: demographics_over_time.png")

print("\nDone!")
