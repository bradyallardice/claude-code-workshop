# replicate_fig1.R
# Goal: reproduce Figure 1 of Magistro et al. 2026
# (marginal means by treatment condition: AI vs. Offshoring)
#
# Run from the repo root: Rscript starter/replicate_fig1.R
# Or interactively in VS Code with Shift+Enter line by line.

# ── Packages ──────────────────────────────────────────────────────────────────
required_packages <- c("dplyr", "tidyr", "ggplot2", "janitor", "cregg",
                       "scales", "MetBrewer")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
lapply(required_packages, library, character.only = TRUE)

# cregg 0.4.0 is required; install from CRAN archive if version differs
if (packageVersion("cregg") != "0.4.0") {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_version("cregg", version = "0.4.0", dependencies = TRUE)
  library(cregg)
}

# ── Load data ─────────────────────────────────────────────────────────────────
data <- read.csv("data/clean_AJPS.csv")

# ── TODO: reshape and clean the conjoint data ─────────────────────────────────
# Hint: see reference_code/main.R lines ~60–130 for the reshape logic.
# You need to:
#   1. Select the relevant columns (qtable_*, price_after_*, cs_after_*,
#      factory_after_*, ds_after_*, ID, countr, treat_offshoring, party, party2)
#   2. Reshape from wide to long (gather → separate → spread)
#   3. Convert variables to factors and relevel them

multi2_reshape <- NULL  # replace this with your reshaped data

# ── TODO: estimate marginal means by treatment ────────────────────────────────
# Use cregg::cj() with estimate = "mm" and by = ~treat_offshoring
# See reference_code/main.R lines ~133–135

mm_by <- NULL  # replace with your cj() call

# ── TODO: plot ────────────────────────────────────────────────────────────────
# Reproduce Figure 1 exactly: one-column faceted marginal-means plot, gray facet
# strips, dashed midpoint line at 3, AI blue, Offshoring orange, legend at bottom.
# Axis should run from 2.0 to 4.0 and be labeled "Marginal mean".
# Save the finished figure to paper/figures/figure1_replication.png.
# See reference_code/main.R lines ~137–165

plot <- NULL  # replace with your ggplot() call

# ── Save ──────────────────────────────────────────────────────────────────────
# Uncomment when your plot is ready:
# ggsave("paper/figures/figure1_replication.png", plot, width = 6.5, height = 8, dpi = 300)
# cat("Saved paper/figures/figure1_replication.png\n")
