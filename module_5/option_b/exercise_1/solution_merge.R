# Session 2 Solution — Part 1: Merge and Explore (R version)
# Merges the survey data with the demographics file using a left join.

library(dplyr)
library(readr)

# ── Load data ────────────────────────────────────────────────────
survey <- read_csv("module_5/option_b/data/swiss_franc_survey.csv")
demog  <- read_csv("module_5/option_b/data/respondent_demographics.csv")

cat("Survey shape:", dim(survey), "\n")
cat("Demographics shape:", dim(demog), "\n")
cat("Survey unique IDs:", length(unique(survey$respondent_id)), "\n")
cat("Demographics unique IDs:", length(unique(demog$respondent_id)), "\n")

# ── Merge: left join on respondent_id ────────────────────────────
merged <- survey %>% left_join(demog, by = "respondent_id")

# ── Verify the merge ─────────────────────────────────────────────
cat("\n=== MERGE VERIFICATION ===\n")
cat("Merged shape:", dim(merged), "\n")
stopifnot(nrow(merged) == 2044)
cat("Row count: 2,044 (no rows lost or gained)\n")

stopifnot(length(unique(merged$respondent_id)) == 2044)
cat("No duplicate respondent IDs\n")

# ── Explore the data ─────────────────────────────────────────────
cat("\n=== TREATMENT GROUPS ===\n")
print(table(merged$treatment))

cat("\n=== OUTCOME DISTRIBUTION ===\n")
print(table(merged$supports_intervention, useNA = "always"))
cat("\nUnweighted proportion supporting:",
    round(mean(merged$supports_intervention, na.rm = TRUE), 4), "\n")

non_na <- !is.na(merged$supports_intervention)
weighted_prop <- weighted.mean(
  merged$supports_intervention[non_na],
  w = merged$survey_weight[non_na]
)
cat("Weighted proportion supporting:", round(weighted_prop, 4), "\n")

cat("\n=== FX EXPOSURE ===\n")
print(table(merged$fx_status, useNA = "always"))

cat("\n=== MISSING DATA ===\n")
for (col in names(merged)) {
  n_miss <- sum(is.na(merged[[col]]))
  if (n_miss > 0) {
    cat(sprintf("  %s: %d missing (%.1f%%)\n",
                col, n_miss, n_miss / nrow(merged) * 100))
  }
}

cat("\n=== INCOME QUINTILE = 0 ===\n")
cat("Respondents with income_quintile = 0:",
    sum(merged$income_quintile == 0, na.rm = TRUE), "\n")

# ── Save ─────────────────────────────────────────────────────────
write_csv(merged, "module_5/option_b/output/merged_survey.csv")
cat("\nSaved merged data to module_5/option_b/output/merged_survey.csv\n")
