"""
Generate FX exchange rate time series figure for the Session 3 LaTeX exercise.
Plots the CHF/PLN exchange rate over time, highlighting the SNB floor removal
event (January 15, 2015) that shocked Polish FX loan holders.
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# ── Load FX data ─────────────────────────────────────────────────
df = pd.read_csv("module_3/data/PLN_CHF_EUR_FXdata.csv")
df["date"] = pd.to_datetime(df["YYYY/MM/DD"])
df = df.sort_values("date")

# ── Plot ─────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))

ax.plot(df["date"], df["CHF/PLN"], color="#1f4e79", linewidth=1.8, label="CHF/PLN")

# Highlight the SNB floor removal event (15 Jan 2015)
event_date = pd.Timestamp("2015-01-15")
ax.axvline(event_date, color="#c00000", linestyle="--", linewidth=1.2, alpha=0.8)
ax.annotate(
    "SNB removes\nCHF/EUR floor\n(Jan 15, 2015)",
    xy=(event_date, df["CHF/PLN"].max() * 0.98),
    xytext=(15, -5),
    textcoords="offset points",
    fontsize=9,
    color="#c00000",
)

ax.set_xlabel("Date", fontsize=11)
ax.set_ylabel("CHF/PLN Exchange Rate", fontsize=11)
ax.set_title("Swiss Franc to Polish Zloty Exchange Rate", fontsize=12, fontweight="bold")
ax.xaxis.set_major_locator(mdates.MonthLocator(interval=2))
ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
plt.setp(ax.xaxis.get_majorticklabels(), rotation=30, ha="right")
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("module_3/output/fx_rate_figure.png", dpi=300, bbox_inches="tight")
plt.close()

print("✓ Saved: module_3/output/fx_rate_figure.png")
