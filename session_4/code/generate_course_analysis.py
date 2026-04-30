"""
Generate synthetic course data, summary statistics, regression results, and visualizations.
Outputs LaTeX tables and PNG figures for the course overview paper.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from datetime import datetime, timedelta
import os

# Set random seed for reproducibility
np.random.seed(42)

# ══════════════════════════════════════════════════════════════════════════════
# 1. GENERATE SYNTHETIC DATA
# ══════════════════════════════════════════════════════════════════════════════

# Number of participants
n_attended = 150
n_waitlist = 80

# Create attendance indicator
attendance = np.concatenate([np.ones(n_attended), np.zeros(n_waitlist)])
n_total = len(attendance)

# Generate baseline data
data = {
    'attended': attendance,
    'age': np.random.normal(35, 8, n_total),
    'experience_years': np.random.uniform(0, 20, n_total),
    'field_econ': np.random.binomial(1, 0.4, n_total),
    'field_stat': np.random.binomial(1, 0.3, n_total),
    'field_comp': np.random.binomial(1, 0.3, n_total),
}

df = pd.DataFrame(data)
df = df[df['age'] > 0]  # Remove impossible ages
df = df.reset_index(drop=True)

# Satisfaction scores (only for attendees, 5 waves over the course)
np.random.seed(42)
satisfaction_waves = []
for i in range(5):
    satisfaction = np.random.normal(7.5, 1.2, n_attended) + 0.3 * i
    satisfaction = np.clip(satisfaction, 1, 10)
    satisfaction_waves.append(satisfaction)

satisfaction_df = pd.DataFrame({
    'session_1': satisfaction_waves[0],
    'session_2': satisfaction_waves[1],
    'session_3': satisfaction_waves[2],
    'session_4': satisfaction_waves[3],
    'final': satisfaction_waves[4],
})

# Generate long-term earnings (2 years post-course)
# Attended gets a boost
base_earnings = np.random.normal(80000, 25000, n_total)
earnings_boost = df['attended'] * np.random.normal(12000, 5000, n_total)
post_course_earnings = base_earnings + earnings_boost + np.random.normal(0, 3000, n_total)

df['earnings_pre'] = base_earnings
df['earnings_post'] = np.maximum(post_course_earnings, 30000)  # Floor at $30k

# Attrition (only relevant for attendees)
attrition_rates = [0.05, 0.08, 0.12, 0.15]  # Sessions 1-4
n_completed = n_attended
for rate in attrition_rates:
    n_completed = int(n_completed * (1 - rate))

# Save raw data
df.to_csv('session_4/data/course_participants.csv', index=False)
satisfaction_df.to_csv('session_4/data/satisfaction.csv', index=False)

# ══════════════════════════════════════════════════════════════════════════════
# 2. SUMMARY STATISTICS TABLE
# ══════════════════════════════════════════════════════════════════════════════

def create_summary_stats_table(df):
    """Create a summary statistics table."""
    attended = df[df['attended'] == 1]
    waitlist = df[df['attended'] == 0]

    variables = ['age', 'experience_years']

    summary = []
    for var in variables:
        attended_mean = attended[var].mean()
        attended_std = attended[var].std()
        waitlist_mean = waitlist[var].mean()
        waitlist_std = waitlist[var].std()

        summary.append({
            'Variable': var.replace('_', ' ').title(),
            'Attended (Mean)': f'{attended_mean:.2f}',
            'Attended (SD)': f'{attended_std:.2f}',
            'Waitlist (Mean)': f'{waitlist_mean:.2f}',
            'Waitlist (SD)': f'{waitlist_std:.2f}',
        })

    summary.append({
        'Variable': 'N',
        'Attended (Mean)': f'{len(attended)}',
        'Attended (SD)': '',
        'Waitlist (Mean)': f'{len(waitlist)}',
        'Waitlist (SD)': '',
    })

    summary_df = pd.DataFrame(summary)
    return summary_df

summary_df = create_summary_stats_table(df)

# Convert to LaTeX table
latex_summary = summary_df.to_latex(index=False, escape=False)
# Keep booktabs format (toprule, midrule, bottomrule) for academic style

with open('session_4/paper/tables/summary_stats.tex', 'w') as f:
    f.write(latex_summary)

# ══════════════════════════════════════════════════════════════════════════════
# 3. REGRESSION: EFFECT OF COURSE ATTENDANCE ON EARNINGS
# ══════════════════════════════════════════════════════════════════════════════

# Prepare regression data
X = df[['attended', 'experience_years', 'age']].values
y = df['earnings_post'].values

# Fit regression
model = LinearRegression()
model.fit(X, y)

# Get results
coef_attended = model.coef_[0]
coef_exp = model.coef_[1]
coef_age = model.coef_[2]
intercept = model.intercept_

# Calculate standard errors (simple approximation)
residuals = y - model.predict(X)
rss = np.sum(residuals**2)
mse = rss / (len(y) - 3)
var_covar = mse * np.linalg.inv(X.T @ X)
se = np.sqrt(np.diag(var_covar))

se_attended = se[0]
se_exp = se[1]
se_age = se[2]

# Calculate t-stats and p-values
from scipy import stats
t_attended = coef_attended / se_attended
p_attended = 2 * (1 - stats.t.cdf(np.abs(t_attended), len(y) - 3))

# R-squared
y_pred = model.predict(X)
ss_res = np.sum((y - y_pred)**2)
ss_tot = np.sum((y - y.mean())**2)
r_squared = 1 - (ss_res / ss_tot)

# Create regression results table in standard academic format
# Create detailed results for each variable
def format_coef(coef, se, t_stat, p_val):
    """Format coefficient with significance stars."""
    sig = ''
    if p_val < 0.001:
        sig = '$^{***}$'
    elif p_val < 0.01:
        sig = '$^{**}$'
    elif p_val < 0.05:
        sig = '$^{*}$'
    return f'{coef:.2f}{sig}'

# Calculate t-stats and p-values for all coefficients
t_exp = coef_exp / se_exp
p_exp = 2 * (1 - stats.t.cdf(np.abs(t_exp), len(y) - 3))

t_age = coef_age / se_age
p_age = 2 * (1 - stats.t.cdf(np.abs(t_age), len(y) - 3))

# Build the LaTeX table manually with booktabs academic formatting
latex_table = r'''\begin{tabular}{lcc}
\toprule
Variable & Coefficient & (Std. Error) \\
\midrule
Attended Course & ''' + format_coef(coef_attended, se_attended, t_attended, p_attended) + r''' & (''' + f'{se_attended:.2f}' + r''') \\
Experience (years) & ''' + format_coef(coef_exp, se_exp, t_exp, p_exp) + r''' & (''' + f'{se_exp:.2f}' + r''') \\
Age & ''' + format_coef(coef_age, se_age, t_age, p_age) + r''' & (''' + f'{se_age:.2f}' + r''') \\
Constant & ''' + f'{intercept:.2f}' + r''' & \\
\midrule
Observations & ''' + f'{len(y)}' + r''' & \\
R$^2$ & ''' + f'{r_squared:.4f}' + r''' & \\
\bottomrule
\end{tabular}

\vspace{0.3em}

\textit{Note:} ''' + r'''Dependent variable is post-course earnings in USD. Standard errors in parentheses.''' + '\n' + \
r'''Significance levels: $^{*}p<0.05$, $^{**}p<0.01$, $^{***}p<0.001$.'''

with open('session_4/paper/tables/regression_earnings.tex', 'w') as f:
    f.write(latex_table)

# ══════════════════════════════════════════════════════════════════════════════
# 4. CREATE FIGURES
# ══════════════════════════════════════════════════════════════════════════════

plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

# Figure 1: Number of students over sessions
fig, ax = plt.subplots(figsize=(8, 5))
sessions = ['Session 1', 'Session 2', 'Session 3', 'Session 4', 'Completed']
n_students = [150, 142, 131, 111, 94]
colors = ['#1f77b4' if i < 4 else '#ff7f0e' for i in range(len(sessions))]
ax.bar(sessions, n_students, color=colors, alpha=0.7, edgecolor='black')
ax.set_ylabel('Number of Students', fontsize=12)
ax.set_title('Course Enrollment Over Time', fontsize=14, fontweight='bold')
ax.set_ylim([0, 160])
for i, v in enumerate(n_students):
    ax.text(i, v + 3, str(v), ha='center', fontweight='bold')
plt.tight_layout()
plt.savefig('session_4/paper/figures/enrollment.png', dpi=300, bbox_inches='tight')
plt.close()

# Figure 2: Satisfaction over time
fig, ax = plt.subplots(figsize=(8, 5))
sessions_sat = ['Session 1', 'Session 2', 'Session 3', 'Session 4', 'Final']
mean_satisfaction = [sat.mean() for sat in satisfaction_waves]
std_satisfaction = [sat.std() for sat in satisfaction_waves]
ax.plot(sessions_sat, mean_satisfaction, marker='o', linewidth=2.5, markersize=8, color='#2ca02c')
ax.fill_between(range(len(sessions_sat)),
                np.array(mean_satisfaction) - np.array(std_satisfaction),
                np.array(mean_satisfaction) + np.array(std_satisfaction),
                alpha=0.2, color='#2ca02c')
ax.set_ylabel('Mean Satisfaction Score', fontsize=12)
ax.set_title('Student Satisfaction Over Course', fontsize=14, fontweight='bold')
ax.set_ylim([5, 10])
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('session_4/paper/figures/satisfaction.png', dpi=300, bbox_inches='tight')
plt.close()

# Figure 3: Attrition rate by session
fig, ax = plt.subplots(figsize=(8, 5))
sessions_att = ['Session 1→2', 'Session 2→3', 'Session 3→4', 'Course Completion']
attrition = [5, 8, 12, 15]
ax.bar(sessions_att, attrition, color='#d62728', alpha=0.7, edgecolor='black')
ax.set_ylabel('Attrition Rate (%)', fontsize=12)
ax.set_title('Session-to-Session Attrition Rates', fontsize=14, fontweight='bold')
ax.set_ylim([0, 20])
for i, v in enumerate(attrition):
    ax.text(i, v + 0.5, f'{v}%', ha='center', fontweight='bold')
plt.tight_layout()
plt.savefig('session_4/paper/figures/attrition.png', dpi=300, bbox_inches='tight')
plt.close()

# Figure 4: Effect of course attendance on earnings
fig, ax = plt.subplots(figsize=(8, 5))
attended_earnings = df[df['attended'] == 1]['earnings_post']
waitlist_earnings = df[df['attended'] == 0]['earnings_post']

bp = ax.boxplot([attended_earnings, waitlist_earnings],
                  labels=['Attended\nCourse', 'Waitlist\n(Control)'],
                  patch_artist=True,
                  widths=0.6)

for patch, color in zip(bp['boxes'], ['#1f77b4', '#ff7f0e']):
    patch.set_facecolor(color)
    patch.set_alpha(0.7)

ax.set_ylabel('Post-Course Earnings ($)', fontsize=12)
ax.set_title('Effect of Course Attendance on 2-Year Earnings', fontsize=14, fontweight='bold')
ax.grid(True, alpha=0.3, axis='y')

# Add mean values
means = [attended_earnings.mean(), waitlist_earnings.mean()]
for i, mean in enumerate(means, 1):
    ax.plot(i, mean, marker='D', markersize=8, color='red', zorder=3)

plt.tight_layout()
plt.savefig('session_4/paper/figures/earnings_effect.png', dpi=300, bbox_inches='tight')
plt.close()

# ══════════════════════════════════════════════════════════════════════════════
# 5. CREATE TABLE PNGS
# ══════════════════════════════════════════════════════════════════════════════

def latex_table_to_png(tex_table_path, png_output_path, title=""):
    """Compile a LaTeX table file to PNG using pdflatex and pdf2image."""
    import subprocess
    import tempfile
    from pdf2image import convert_from_path

    # Read the table content
    with open(tex_table_path, 'r') as f:
        table_content = f.read()

    # Create a minimal LaTeX document wrapping the table
    title_block = ''
    if title:
        title_block = r'\begin{center}\textbf{\large ' + title + r'}\end{center}' + '\n\\vspace{0.5em}\n'

    wrapper = r'''\documentclass[border=10pt]{standalone}
\usepackage{booktabs}
\usepackage{amsmath}
\begin{document}
''' + title_block + table_content + r'''
\end{document}
'''

    with tempfile.TemporaryDirectory() as tmpdir:
        tex_path = os.path.join(tmpdir, 'table.tex')
        pdf_path = os.path.join(tmpdir, 'table.pdf')

        with open(tex_path, 'w') as f:
            f.write(wrapper)

        # Compile with pdflatex
        result = subprocess.run(
            ['pdflatex', '-interaction=nonstopmode', '-output-directory', tmpdir, tex_path],
            capture_output=True, text=True
        )

        if not os.path.exists(pdf_path):
            print(f"Error compiling {tex_table_path}:")
            print(result.stdout[-1000:])
            return False

        # Convert PDF to PNG
        images = convert_from_path(pdf_path, dpi=300)
        images[0].save(png_output_path, 'PNG')
        return True


def table_to_png(df, filename, title="", academic=True):
    """Legacy function — kept for compatibility but unused for academic tables."""
    pass

# Create PNG versions of tables by compiling the actual LaTeX files with pdflatex
latex_table_to_png(
    'session_4/paper/tables/summary_stats.tex',
    'session_4/paper/figures/summary_stats_table.png',
    title='Summary Statistics'
)

latex_table_to_png(
    'session_4/paper/tables/regression_earnings.tex',
    'session_4/paper/figures/regression_results_table.png',
    title='Regression Results: Effect on Earnings'
)

# ══════════════════════════════════════════════════════════════════════════════
# 6. SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

print("\n✓ Data generation complete!")
print(f"\nGenerated:")
print(f"  • {len(df)} total participants ({len(df[df['attended']==1])} attended, {len(df[df['attended']==0])} waitlist)")
print(f"  • {n_completed} students completed the course")
print(f"\nLaTeX tables:")
print(f"  • session_4/paper/tables/summary_stats.tex")
print(f"  • session_4/paper/tables/regression_earnings.tex")
print(f"\nFigures:")
print(f"  • 4 data visualization PNGs in session_4/paper/figures/")
print(f"  • 2 academic-style table PNGs in session_4/paper/figures/")
print(f"\nData files:")
print(f"  • session_4/data/course_participants.csv")
print(f"  • session_4/data/satisfaction.csv")
print(f"\nRegression: Course attendance effect = ${coef_attended:.2f} (p = {p_attended:.4f})")
print(f"R-squared: {r_squared:.4f}")
