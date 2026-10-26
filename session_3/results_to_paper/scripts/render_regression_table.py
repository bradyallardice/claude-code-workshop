"""
Render a long-format regression results CSV into a LaTeX table fragment.

Input:  results/regression_results.csv (one row per coefficient, N, R^2, spec label, note)
Output: tables/regression_table.tex, a tabular plus notes with NO document wrapper, so a
        paper can pull it in with \\input{tables/regression_table.tex} inside its own
        table environment. Requires \\usepackage{booktabs} and \\usepackage{makecell}.

The output is a fragment, not a standalone document, and each row is labelled with the
coefficient name. The output folder is created if it is missing, and an existing output
file is overwritten.

Run from the session_3/results_to_paper folder:
    python scripts/render_regression_table.py
or give both paths:
    python scripts/render_regression_table.py results/regression_results.csv tables/regression_table.tex
"""

import os
import sys

import pandas as pd

DEFAULT_CSV_PATH = "results/regression_results.csv"
DEFAULT_TEX_PATH = "tables/regression_table.tex"

# Row labels for each coef_type in the CSV. A coef_type missing from this dict stops the
# script instead of printing an unlabeled row.
COEF_LABELS = {
    "info": "Information",
    "history": "History",
    "hungary": "Hungary comparison",
    "any_info": "Any information",
}

REQUIRED_COLUMNS = ["row_type", "display_order", "spec", "coef_type", "coef", "se",
                    "pvalue", "value_num", "value_str"]


def stars(pvalue):
    """Significance stars: *** p<0.001, ** p<0.01, * p<0.05, + p<0.1."""
    if pvalue < 0.001:
        return "$^{***}$"
    if pvalue < 0.01:
        return "$^{**}$"
    if pvalue < 0.05:
        return "$^{*}$"
    if pvalue < 0.1:
        return "$^{+}$"
    return ""


def format_coefficient_cell(coef, se, pvalue):
    """Coefficient with stars, standard error underneath (stacked with makecell)."""
    if pd.isna(coef) or pd.isna(se):
        return ""
    return r"\makecell{" + f"{coef:.3f}{stars(pvalue)}" + r"\\ " + f"({se:.3f})" + "}"


def load_results(csv_path):
    """Read the CSV as numbers where they should be, and check the columns we rely on."""
    df = pd.read_csv(csv_path, na_values=["NA"])
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"{csv_path} is missing columns: {missing}")
    return df


def render_table(df):
    """Build the LaTeX text (tabular plus notes) from the results data frame."""
    spec_rows = df[df["row_type"] == "spec_label"].sort_values("display_order")
    specs = spec_rows["spec"].tolist()
    spec_names = spec_rows["value_str"].tolist()
    if len(specs) != len(set(specs)):
        raise ValueError("duplicate spec keys in spec_label rows")

    coefficient_rows = df[df["row_type"] == "coefficient"]
    unknown = set(coefficient_rows["coef_type"]) - set(COEF_LABELS)
    if unknown:
        raise ValueError(f"no row label for coef_type(s): {sorted(unknown)}; add them to COEF_LABELS")
    unknown_specs = set(coefficient_rows["spec"]) - set(specs)
    if unknown_specs:
        raise ValueError(f"coefficients for specs with no spec_label row: {sorted(unknown_specs)}")

    # Row order: by the display_order of each coef_type's first appearance
    coef_order = (coefficient_rows.groupby("coef_type")["display_order"].min()
                  .sort_values().index.tolist())

    lines = [r"\setlength{\tabcolsep}{4pt}",
             r"\begin{tabular}{l" + "c" * len(specs) + "}",
             r"\toprule",
             "& " + " & ".join(spec_names) + r" \\",
             r"\midrule"]

    for coef_type in coef_order:
        cells = [COEF_LABELS[coef_type]]
        for spec in specs:
            match = coefficient_rows[(coefficient_rows["spec"] == spec)
                                     & (coefficient_rows["coef_type"] == coef_type)]
            if len(match) == 0:
                cells.append("")
            else:
                row = match.iloc[0]
                cells.append(format_coefficient_cell(row["coef"], row["se"], row["pvalue"]))
        lines.append(" & ".join(cells) + r" \\")

    lines.append(r"\midrule")
    for row_type, label, number_format in [("n", "N", "{:,.0f}"), ("r2", r"Pseudo $R^2$", "{:.3f}")]:
        cells = [label]
        for spec in specs:
            match = df[(df["row_type"] == row_type) & (df["spec"] == spec)]
            if len(match) == 0:
                raise ValueError(f"no {row_type} row for spec {spec}")
            cells.append(number_format.format(match.iloc[0]["value_num"]))
        lines.append(" & ".join(cells) + r" \\")
    lines += [r"\bottomrule", r"\end{tabular}", ""]

    note_rows = df[df["row_type"] == "note"]
    if len(note_rows) > 0:
        lines += [r"\vspace{0.5em}", "", r"{\footnotesize " + note_rows.iloc[0]["value_str"] + r" \par}",
                  "", r"{\footnotesize $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$, $^{+}p<0.1$ \par}"]
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    csv_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_CSV_PATH
    tex_path = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_TEX_PATH
    tex_text = render_table(load_results(csv_path))
    with open(tex_path, "w") as tex_file:
        tex_file.write(tex_text)
    print(f"LaTeX table written to {tex_path}")
