# Session 2 Solution -- Part 1: Merge and Explore
# Merges the survey data with the demographics file using a left join.
#
# Runnable interactively in VS Code / RStudio (send line by line) or via:
#   Rscript session_3/scripts/solution_merge.R
# Assumes the working directory is the project root (AIAgentsCourse/).

library(dplyr)
library(readr)

# -- Load data --------------------------------------------------------
survey <- read_csv("session_3/data/swiss_franc_survey.csv", show_col_types = FALSE)
demog  <- read_csv("session_3/data/respondent_demographics.csv", show_col_types = FALSE)

cat("Survey shape:", nrow(survey), "x", ncol(survey), "\n")
cat("Demographics shape:", nrow(demog), "x", ncol(demog), "\n")
cat("Survey unique IDs:", n_distinct(survey$respondent_id), "\n")
cat("Demographics unique IDs:", n_distinct(demog$respondent_id), "\n")

# -- Merge: left join on respondent_id --------------------------------
merged <- left_join(survey, demog, by = "respondent_id")

# -- Verify the merge -------------------------------------------------
cat("\n=== MERGE VERIFICATION ===\n")
cat("Merged shape:", nrow(merged), "x", ncol(merged), "\n")
stopifnot(nrow(merged) == 2044)
cat("Row count: 2,044 (no rows lost or gained)\n")

stopifnot(n_distinct(merged$respondent_id) == 2044)
cat("No duplicate respondent IDs\n")

# -- Explore the data -------------------------------------------------
cat("\n=== TREATMENT GROUPS ===\n")
print(sort(table(merged$treatment)))

cat("\n=== OUTCOME DISTRIBUTION ===\n")
print(table(merged$supports_intervention, useNA = "ifany"))
cat(sprintf("\nUnweighted proportion supporting: %.4f\n",
            mean(merged$supports_intervention, na.rm = TRUE)))

ok <- !is.na(merged$supports_intervention)
weighted_prop <- weighted.mean(merged$supports_intervention[ok],
                               w = merged$survey_weight[ok])
cat(sprintf("Weighted proportion supporting: %.4f\n", weighted_prop))

cat("\n=== FX EXPOSURE ===\n")
print(table(merged$fx_status, useNA = "ifany"))

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

# -- Save -------------------------------------------------------------
write_csv(merged, "session_3/output/merged_survey.csv")
cat("\nSaved merged data to session_3/output/merged_survey.csv\n")
