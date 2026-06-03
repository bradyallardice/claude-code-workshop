"""
Session 3 — Respondent demographics summary.

Describes the demographics of survey respondents using ONLY
session_3/data/respondent_demographics.csv (all 2,994 rows, not limited to the
2,044 survey respondents). The file has two demographic variables:

  - income_quintile : 0 = no income (valid, NOT missing); 1-5 = quintiles
                      (1 = lowest, 5 = highest); blank = missing.
  - left_right      : integer -3 (left) to +3 (right); 0 = center;
                      blank = declined (missing).

Produces three PNG figures and three LaTeX (.tex) tables in session_3/output/.
All summaries are unweighted. Run from the project root (AIAgentsCourse/);
function definitions are kept separate from execution so each block can be run
interactively in VS Code (Shift+Enter).
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# ── Paths and shared style ───────────────────────────────────────────
DATA_PATH = "session_3/data/respondent_demographics.csv"
OUTPUT_DIR = "session_3/output"

PRIMARY = "#1f4e79"   # main bar / line color (matches generate_fx_figure.py)
ACCENT = "#c00000"    # accent / annotation color

# Display order and labels for each categorical variable.
INCOME_ORDER = [0, 1, 2, 3, 4, 5]
INCOME_LABELS = ["No income", "Q1\n(lowest)", "Q2", "Q3", "Q4", "Q5\n(highest)"]
LEFT_RIGHT_ORDER = [-3, -2, -1, 0, 1, 2, 3]


# ── Data loading ─────────────────────────────────────────────────────
def load_demographics(path=DATA_PATH):
    """Load the demographics file. Blank cells become NaN (missing)."""
    df = pd.read_csv(path)
    return df


# ── Helper: ordered frequency table with valid- and all-row percentages ─
def frequency_table(series, order):
    """
    Build a frequency table for `series` over the given category `order`.

    Returns a DataFrame with columns: category, count, pct_valid, pct_all.
    A "Missing" row (NaN values) and a "Total" row are appended. Percentages
    are of valid (non-missing) responses and of all rows, respectively.
    """
    n_all = len(series)
    n_missing = int(series.isna().sum())
    n_valid = n_all - n_missing

    counts = series.value_counts(dropna=True)
    rows = []
    for cat in order:
        c = int(counts.get(cat, 0))
        rows.append(
            {
                "category": cat,
                "count": c,
                "pct_valid": 100 * c / n_valid if n_valid else np.nan,
                "pct_all": 100 * c / n_all if n_all else np.nan,
            }
        )

    rows.append(
        {
            "category": "Missing",
            "count": n_missing,
            "pct_valid": np.nan,
            "pct_all": 100 * n_missing / n_all if n_all else np.nan,
        }
    )
    rows.append(
        {
            "category": "Total",
            "count": n_all,
            "pct_valid": 100.0 if n_valid else np.nan,
            "pct_all": 100.0,
        }
    )
    return pd.DataFrame(rows)


# ── Figure 1: income quintile distribution ───────────────────────────
def plot_income_distribution(df, output_dir=OUTPUT_DIR):
    counts = df["income_quintile"].value_counts(dropna=True)
    heights = [int(counts.get(cat, 0)) for cat in INCOME_ORDER]
    n_missing = int(df["income_quintile"].isna().sum())

    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar(range(len(INCOME_ORDER)), heights, color=PRIMARY)
    ax.bar_label(bars, padding=3, fontsize=9)

    ax.set_xticks(range(len(INCOME_ORDER)))
    ax.set_xticklabels(INCOME_LABELS, fontsize=9)
    ax.set_xlabel("Household income quintile", fontsize=11)
    ax.set_ylabel("Number of respondents", fontsize=11)
    ax.set_title("Respondent Income Quintile Distribution", fontsize=12, fontweight="bold")
    ax.grid(True, axis="y", alpha=0.3)
    ax.set_axisbelow(True)
    ax.annotate(
        f"Missing: {n_missing:,} respondents",
        xy=(0.01, 0.97), xycoords="axes fraction",
        ha="left", va="top", fontsize=9, color=ACCENT,
    )

    plt.tight_layout()
    path = f"{output_dir}/income_quintile_distribution.png"
    plt.savefig(path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"✓ Saved: {path}")


# ── Figure 2: left-right ideology distribution ───────────────────────
def plot_left_right_distribution(df, output_dir=OUTPUT_DIR):
    counts = df["left_right"].value_counts(dropna=True)
    heights = [int(counts.get(cat, 0)) for cat in LEFT_RIGHT_ORDER]
    n_missing = int(df["left_right"].isna().sum())

    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar([str(c) for c in LEFT_RIGHT_ORDER], heights, color=PRIMARY)
    ax.bar_label(bars, padding=3, fontsize=9)

    ax.set_xlabel("Left–right self-placement  (−3 = left, 0 = center, +3 = right)", fontsize=11)
    ax.set_ylabel("Number of respondents", fontsize=11)
    ax.set_title("Respondent Left–Right Ideology Distribution", fontsize=12, fontweight="bold")
    ax.grid(True, axis="y", alpha=0.3)
    ax.set_axisbelow(True)
    ax.annotate(
        f"Missing (declined): {n_missing:,} respondents",
        xy=(0.99, 0.97), xycoords="axes fraction",
        ha="right", va="top", fontsize=9, color=ACCENT,
    )

    plt.tight_layout()
    path = f"{output_dir}/left_right_distribution.png"
    plt.savefig(path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"✓ Saved: {path}")


# ── Figure 3: income x ideology cross-tab heatmap ────────────────────
def plot_income_ideology_crosstab(df, output_dir=OUTPUT_DIR):
    ct = pd.crosstab(df["income_quintile"], df["left_right"])
    ct = ct.reindex(index=INCOME_ORDER, columns=LEFT_RIGHT_ORDER, fill_value=0)

    fig, ax = plt.subplots(figsize=(8, 5.5))
    im = ax.imshow(ct.values, cmap="Blues", aspect="auto")

    ax.set_xticks(range(len(LEFT_RIGHT_ORDER)))
    ax.set_xticklabels(LEFT_RIGHT_ORDER)
    ax.set_yticks(range(len(INCOME_ORDER)))
    ax.set_yticklabels(["No income", "Q1", "Q2", "Q3", "Q4", "Q5"])
    ax.set_xlabel("Left–right self-placement", fontsize=11)
    ax.set_ylabel("Income quintile", fontsize=11)
    ax.set_title("Income Quintile × Left–Right Ideology (respondent counts)",
                 fontsize=12, fontweight="bold")

    # Annotate each cell; pick text color for contrast.
    vmax = ct.values.max()
    for i in range(ct.shape[0]):
        for j in range(ct.shape[1]):
            val = int(ct.values[i, j])
            color = "white" if val > 0.6 * vmax else "black"
            ax.text(j, i, f"{val}", ha="center", va="center", fontsize=8, color=color)

    cbar = fig.colorbar(im, ax=ax, shrink=0.85)
    cbar.set_label("Count", fontsize=10)

    plt.tight_layout()
    path = f"{output_dir}/income_ideology_crosstab.png"
    plt.savefig(path, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"✓ Saved: {path}")


# ── LaTeX table writers ──────────────────────────────────────────────
def _fmt_pct(x):
    return "" if pd.isna(x) else f"{x:.1f}"


def write_frequency_tex(freq, var_label, caption, path,
                        category_formatter=str):
    """Render a frequency table (from frequency_table) as a booktabs LaTeX table."""
    lines = [
        "\\begin{table}[htbp]",
        "\\centering",
        f"\\caption{{{caption}}}",
        "\\begin{tabular}{lrrr}",
        "\\toprule",
        f"{var_label} & Count & \\% of valid & \\% of all \\\\",
        "\\midrule",
    ]
    n_rows = len(freq)
    for idx, row in freq.reset_index(drop=True).iterrows():
        cat = row["category"]
        label = cat if cat in ("Missing", "Total") else category_formatter(cat)
        count = f"{int(row['count']):,}"
        pv = _fmt_pct(row["pct_valid"])
        pa = _fmt_pct(row["pct_all"])
        # Rule before the Missing row and before the Total row.
        if cat == "Missing" or cat == "Total":
            lines.append("\\midrule")
        lines.append(f"{label} & {count} & {pv} & {pa} \\\\")
    lines += [
        "\\bottomrule",
        "\\end{tabular}",
        "\\end{table}",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"✓ Saved: {path}")


def write_summary_tex(df, path):
    """Compact overview table of the two demographic variables."""
    n_all = len(df)

    inc = df["income_quintile"]
    lr = df["left_right"]

    inc_valid = int(inc.notna().sum())
    lr_valid = int(lr.notna().sum())

    modal_q = int(inc.mode().iloc[0]) if inc_valid else np.nan
    modal_label = "No income" if modal_q == 0 else f"Q{modal_q}"

    rows = [
        ("Total rows", f"{n_all:,}"),
        ("\\midrule", None),
        ("\\textit{Income quintile}", ""),
        ("\\quad Non-missing", f"{inc_valid:,} ({100*inc_valid/n_all:.1f}\\%)"),
        ("\\quad Missing", f"{n_all-inc_valid:,} ({100*(n_all-inc_valid)/n_all:.1f}\\%)"),
        ("\\quad Modal category", modal_label),
        ("\\midrule", None),
        ("\\textit{Left\\textendash right ideology}", ""),
        ("\\quad Non-missing", f"{lr_valid:,} ({100*lr_valid/n_all:.1f}\\%)"),
        ("\\quad Missing", f"{n_all-lr_valid:,} ({100*(n_all-lr_valid)/n_all:.1f}\\%)"),
        ("\\quad Mean", f"{lr.mean():.2f}"),
        ("\\quad Median", f"{lr.median():.1f}"),
        ("\\quad Std. dev.", f"{lr.std():.2f}"),
    ]

    lines = [
        "\\begin{table}[htbp]",
        "\\centering",
        "\\caption{Respondent demographics summary (\\texttt{respondent\\_demographics.csv}, all rows)}",
        "\\begin{tabular}{ll}",
        "\\toprule",
        "Statistic & Value \\\\",
        "\\midrule",
    ]
    for label, val in rows:
        if label == "\\midrule":
            lines.append("\\midrule")
        else:
            lines.append(f"{label} & {val} \\\\")
    lines += [
        "\\bottomrule",
        "\\end{tabular}",
        "\\end{table}",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"✓ Saved: {path}")


# ── Stdout summary (useful when run interactively) ───────────────────
def print_summary(df):
    print("=== RESPONDENT DEMOGRAPHICS SUMMARY ===")
    print(f"Total rows: {len(df):,}")
    for col in ["income_quintile", "left_right"]:
        n_miss = int(df[col].isna().sum())
        print(f"\n{col}: {n_miss:,} missing ({100*n_miss/len(df):.1f}%)")
        print(df[col].value_counts(dropna=False).sort_index())


# ── Execution ────────────────────────────────────────────────────────
if __name__ == "__main__":
    df = load_demographics()
    print_summary(df)

    # Figures
    plot_income_distribution(df)
    plot_left_right_distribution(df)
    plot_income_ideology_crosstab(df)

    # Tables
    income_freq = frequency_table(df["income_quintile"], INCOME_ORDER)
    write_frequency_tex(
        income_freq,
        var_label="Income quintile",
        caption="Respondent income quintile distribution",
        path=f"{OUTPUT_DIR}/demographics_income_table.tex",
        category_formatter=lambda c: "No income" if c == 0 else f"Q{int(c)}",
    )

    ideology_freq = frequency_table(df["left_right"], LEFT_RIGHT_ORDER)
    write_frequency_tex(
        ideology_freq,
        var_label="Left--right",
        caption="Respondent left--right ideology distribution",
        path=f"{OUTPUT_DIR}/demographics_ideology_table.tex",
        category_formatter=lambda c: f"{int(c):+d}".replace("+0", "0"),
    )

    write_summary_tex(df, f"{OUTPUT_DIR}/demographics_summary.tex")

    print("\nDone.")
