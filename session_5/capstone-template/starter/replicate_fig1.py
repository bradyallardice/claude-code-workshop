# replicate_fig1.py
# Goal: reproduce Figure 1 of Magistro et al. 2026
# (marginal means by treatment condition: AI vs. Offshoring)
#
# Run from the repo root: python starter/replicate_fig1.py
# Or interactively in VS Code with Shift+Enter line by line.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# ── Load data ─────────────────────────────────────────────────────────────────
data = pd.read_csv("data/clean_AJPS.csv")

# ── TODO: reshape conjoint data ───────────────────────────────────────────────
# The conjoint data is wide: each task iteration is a separate column
# (e.g., price_after_1, price_after_2, ..., qtable_1, ...).
# You need to reshape to long format so each row is one (respondent, task) pair.
#
# Columns to keep: ID, countr, treat_offshoring, party, party2
# Conjoint attributes: price_after, cs_after, factory_after, ds_after
# Outcome: qtable (support rating 1–5)
#
# Hint: pd.wide_to_long() or pd.melt() + pivot can do the reshaping.

multi2_reshape = None  # replace with your reshaped DataFrame

# ── TODO: estimate marginal means by treatment ────────────────────────────────
# For each treatment arm (AI / Offshoring) and each attribute level,
# compute the mean qtable rating (that's the marginal mean).
# You can use groupby + mean, or statsmodels OLS with dummies.
#
# Structure your results as a DataFrame with columns:
#   feature, level, treat_offshoring, estimate, lower, upper

mm_by = None  # replace with your marginal means DataFrame

# ── TODO: plot ────────────────────────────────────────────────────────────────
# Reproduce Figure 1 exactly: one-column faceted marginal-means plot,
# gray strip headers, dashed midpoint line at 3, AI blue, Offshoring orange,
# legend at bottom. Axis should run from 2.0 to 4.0 and be labeled
# "Marginal mean". Save to paper/figures/figure1_replication.png.
#
# group.colors = {"Offshoring": "#E58606", "AI": "#5D69B1"}

fig = None  # replace with your matplotlib figure

# your plotting code here

# ── Save ──────────────────────────────────────────────────────────────────────
# Uncomment when ready:
# plt.savefig("paper/figures/figure1_replication.png", dpi=300, bbox_inches="tight")
# print("Saved paper/figures/figure1_replication.png")
