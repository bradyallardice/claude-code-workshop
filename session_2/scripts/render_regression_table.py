"""
Render regression table CSV to LaTeX following the skill specification.
Reads tab_swiss_franc_logit.csv and produces tab_swiss_franc_logit.tex
"""

import pandas as pd
import numpy as np
from pathlib import Path


def format_coef(coef, se, pvalue):
    """Format coefficient with stars and SE below."""
    if pd.isna(coef) or pd.isna(se):
        return ""

    # Compute stars
    if pvalue < 0.001:
        stars = "$^{***}$"
    elif pvalue < 0.01:
        stars = "$^{**}$"
    elif pvalue < 0.05:
        stars = "$^{*}$"
    elif pvalue < 0.1:
        stars = "$^{+}$"
    else:
        stars = ""

    coef_str = f"{coef:.3f}{stars}"
    se_str = f"({se:.3f})"
    # Use \newline for within-cell line breaks in tabular with booktabs
    return f"{coef_str}\\newline {se_str}"


def render_latex(csv_path, tex_path):
    """Render CSV to LaTeX table."""
    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False, na_values=[])

    # Convert numeric columns
    for col in ['coef', 'se', 'pvalue', 'value_num', 'display_order']:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # Get unique specs in order
    spec_labels = df[df['row_type'] == 'spec_label'].sort_values('display_order')
    specs = spec_labels['spec'].tolist()
    spec_names = spec_labels['value_str'].tolist()

    # Get coefficients and organize by dv and coef_type
    coefs = df[df['row_type'] == 'coefficient'].copy()
    coefs = coefs.sort_values(['display_order'])

    # Get all DVs
    dvs = coefs['dv'].unique()
    coef_types_per_dv = {}
    for dv in dvs:
        coef_types_per_dv[dv] = coefs[coefs['dv'] == dv]['coef_type'].unique().tolist()

    # Start building LaTeX
    lines = []
    lines.append(r"\begin{tabular}{l*{" + str(len(specs)) + r"}{c}}")
    lines.append(r"\toprule")

    # Header row
    header = "& " + " & ".join(spec_names) + r" \\"
    lines.append(header)
    lines.append(r"\midrule")

    # Coefficient block
    for dv in dvs:
        dv_label = coefs[coefs['dv'] == dv]['dv_label'].iloc[0]
        for i, coef_type in enumerate(coef_types_per_dv[dv]):
            # Row label
            if i == 0:
                row_label = dv_label
            else:
                row_label = ""

            # Collect cells for this row
            cells = [row_label]
            for spec in specs:
                matching_coef = coefs[
                    (coefs['dv'] == dv) &
                    (coefs['spec'] == spec) &
                    (coefs['coef_type'] == coef_type)
                ]

                if len(matching_coef) > 0:
                    row = matching_coef.iloc[0]
                    coef = row['coef']
                    se = row['se']
                    pvalue = row['pvalue']
                    cell = format_coef(coef, se, pvalue)
                else:
                    cell = ""

                cells.append(cell)

            # Format row properly - cells should be on separate lines
            row_str = cells[0]  # row label
            for cell in cells[1:]:
                row_str += " & " + cell
            row_str += r" \\"
            lines.append(row_str)

        # Add spacing after DV group (except for last)
        if dv != dvs[-1]:
            lines.append(r"\addlinespace")

    # Remove last addlinespace
    if lines[-1] == r"\addlinespace":
        lines.pop()

    lines.append(r"\midrule")

    # Summary block (N, R2)
    # N row
    n_row = ["N"]
    ns_df = df[df['row_type'] == 'n'].sort_values('display_order')
    for spec in specs:
        n_val = ns_df[ns_df['spec'] == spec]['value_num'].values
        if len(n_val) > 0:
            n_str = f"{int(n_val[0]):,}"
            n_row.append(n_str)
        else:
            n_row.append("")
    lines.append(" & ".join(n_row) + r" \\")

    # R2 row
    r2_row = [r"Pseudo $R^2$"]
    r2_df = df[df['row_type'] == 'r2'].sort_values('display_order')
    for spec in specs:
        r2_val = r2_df[r2_df['spec'] == spec]['value_num'].values
        if len(r2_val) > 0:
            r2_str = f"{r2_val[0]:.3f}"
            r2_row.append(r2_str)
        else:
            r2_row.append("")
    lines.append(" & ".join(r2_row) + r" \\")

    lines.append(r"\bottomrule")
    lines.append(r"\end{tabular}")

    # Notes
    note_df = df[df['row_type'] == 'note']
    if len(note_df) > 0:
        note_text = note_df['value_str'].values[0]
        lines.append("")
        lines.append(r"\vspace{0.5em}")
        lines.append(r"\\ \\")
        lines.append(r"\small")
        lines.append(note_text)
        lines.append(r"\\\\ \textsuperscript{***} $p<0.001$, \textsuperscript{**} $p<0.01$, \textsuperscript{*} $p<0.05$, \textsuperscript{+} $p<0.1$")

    # Write LaTeX file
    tex_content = "\n".join(lines)

    # Wrap in minimal document for standalone compilation
    full_tex = r"""\documentclass{article}
\usepackage{booktabs}
\usepackage{geometry}
\geometry{margin=1in}

\begin{document}

\begin{table}[h]
\centering
""" + tex_content + r"""
\end{table}

\end{document}
"""

    with open(tex_path, 'w') as f:
        f.write(full_tex)

    print(f"LaTeX table written to {tex_path}")
    return tex_path


if __name__ == '__main__':
    csv_path = 'session_2/output/tab_swiss_franc_logit.csv'
    tex_path = 'session_2/output/tab_swiss_franc_logit.tex'
    render_latex(csv_path, tex_path)
