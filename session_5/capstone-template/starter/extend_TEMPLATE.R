# extend_TEMPLATE.R
# Extension analysis for Magistro et al. 2026 replication
#
# Fill in EXTENSION_LABEL and the analysis section for your assigned extension.
# Run from the repo root: Rscript starter/extend_TEMPLATE.R

EXTENSION_LABEL <- "A"  # change to "A", "B", or "C"

# ── Packages ──────────────────────────────────────────────────────────────────
required_packages <- c("dplyr", "tidyr", "ggplot2", "janitor", "cregg", "scales", "MetBrewer")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
lapply(required_packages, library, character.only = TRUE)

# ── Load and reshape data ─────────────────────────────────────────────────────
# Copy your working reshape code from replicate_fig1.R here.
# multi2_reshape should be a long-format data frame with one row per (id, task).

data <- read.csv("data/clean_AJPS.csv")
multi2_reshape <- NULL  # replace with your reshape code

# ── Extension A: Framing × job type interaction ───────────────────────────────
# Does the AI vs. offshoring frame shift preferences differently for
# data science jobs (dsafter) vs. factory jobs (factoryafter)?
#
# Approach:
#   1. Estimate marginal means separately for AI and Offshoring arms,
#      broken out by job attribute (dsafter vs. factoryafter).
#   2. Compute the AI–Offshoring difference for each job attribute level.
#   3. Plot: side-by-side coefficient plots, one column per job type.
#   4. Formally test whether the interaction (frame × job type) is significant
#      using cregg::cj_anova() or a linear model with interaction terms.
#
# Key variables: treat_offshoring, dsafter, factoryafter, qtable

if (EXTENSION_LABEL == "A") {
  # TODO: your Extension A code here
}

# ── Extension B: Robustness battery ──────────────────────────────────────────
# Rerun the main AI vs. offshoring framing effect across a grid of
# specification choices. Produce a specification curve or robustness table.
#
# Specification grid (all combinations):
#   attention_filter:  "all" vs. "pass_only"  (manipulation_check2 == "Pass")
#   weights:           "unweighted" vs. "weighted"  (no weights in clean data — set to 1)
#   estimator:         "ols" (lm) vs. "ologit" (MASS::polr)
#   task_fe:           FALSE vs. TRUE  (add iteration fixed effects)
#
# For each cell, extract: estimate, SE/CI, label
# Plot: specification curve (sorted by estimate) or a table with all cells.

if (EXTENSION_LABEL == "B") {
  if (!requireNamespace("MASS", quietly = TRUE)) install.packages("MASS")
  library(MASS)
  # TODO: your Extension B code here
}

# ── Extension C: Prior trade attitudes as moderator ───────────────────────────
# Does pre-treatment support for trade liberalization moderate the
# AI vs. offshoring framing effect?
#
# Variable: tables_policygr_5 (1–5 scale, higher = more pro-trade)
# Approach:
#   1. Median split: create trade_support_hi (above median) vs. trade_support_lo.
#   2. Estimate marginal means by treat_offshoring separately within each group.
#   3. Compute AI–Offshoring difference within each group.
#   4. Plot: two-panel coefficient plot (low vs. high trade support).
#   5. Formally test moderation: add treat_offshoring × trade_support interaction
#      to a linear model and check significance.

if (EXTENSION_LABEL == "C") {
  # TODO: your Extension C code here
}

# ── Save outputs ──────────────────────────────────────────────────────────────
# Save your figure(s) to paper/figures/ and any tables to paper/tables/
# ggsave("paper/figures/extension_result.png", plot, width = 8, height = 6, dpi = 300)
