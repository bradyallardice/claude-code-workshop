# Session 2 Solution -- Part 2: Specify and Estimate
# Logistic regression of supports_intervention on treatment, with progressive
# addition of controls to demonstrate the missing data trap.
#
# Run from the project root (AIAgentsCourse/):
#   Rscript session_3/scripts/solution_estimate.R
#
# Note on weights: the Python version uses statsmodels freq_weights. R's glm()
# weights argument for a binomial family gives the same point estimates, so we
# pass survey_weight there. (Standard errors follow the same likelihood.)

library(readr)

# -- Load merged data -------------------------------------------------
df <- read_csv("session_3/output/merged_survey.csv", show_col_types = FALSE)

# -- Set reference categories explicitly ------------------------------
# The first factor level is the reference category in R.
df$treatment <- factor(df$treatment,
                       levels = c("cntrl", "info", "history", "Hungary"))
df$fx_status <- factor(df$fx_status,
                       levels = c("none", "current", "past"))


run_logit <- function(formula, data, weights_col = NULL, label = "") {
  # Run a logistic regression and print summary.
  if (!is.null(weights_col)) {
    data$.w <- data[[weights_col]]  # glm() resolves `weights` inside `data`
    model <- glm(formula, data = data, family = binomial(), weights = .w)
  } else {
    model <- glm(formula, data = data, family = binomial())
  }
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("MODEL:", label, "\n")
  cat("Formula:", deparse(formula), "\n")
  cat("N =", length(model$y), "\n")
  cat(strrep("=", 60), "\n", sep = "")
  print(summary(model)$coefficients)
  model
}


# -- Step 4: Base model -- treatment only, weighted -------------------
m1 <- run_logit(supports_intervention ~ treatment, df,
                weights_col = "survey_weight",
                label = "Base model (treatment only, weighted)")

# -- Step 5: Add FX exposure -----------------------------------------
m2 <- run_logit(supports_intervention ~ treatment + fx_status, df,
                weights_col = "survey_weight", label = "+ FX exposure")

# -- Step 6: Add demographic controls --------------------------------
# First WITHOUT income and left_right (no additional missingness)
m3a <- run_logit(
  supports_intervention ~ treatment + fx_status + age + female + ed_level + urban_rural,
  df, weights_col = "survey_weight",
  label = "+ demographics (no income, no left-right)")

# Now WITH income_quintile (drops ~525)
m3b <- run_logit(
  supports_intervention ~ treatment + fx_status + age + female + ed_level + urban_rural + income_quintile,
  df, weights_col = "survey_weight",
  label = "+ income_quintile (THE MISSING DATA TRAP)")

# Now WITH left_right (drops ~504)
m3c <- run_logit(
  supports_intervention ~ treatment + fx_status + age + female + ed_level + urban_rural + left_right,
  df, weights_col = "survey_weight", label = "+ left_right")

# Now WITH both (drops ~859)
m3d <- run_logit(
  supports_intervention ~ treatment + fx_status + age + female + ed_level + urban_rural + income_quintile + left_right,
  df, weights_col = "survey_weight",
  label = "+ both income_quintile and left_right")

# -- Step 7: Interaction -- treatment x FX exposure ------------------
m4 <- run_logit(
  supports_intervention ~ treatment * fx_status + age + female + ed_level + urban_rural,
  df, weights_col = "survey_weight",
  label = "Treatment x FX exposure interaction")

# -- Summary of sample sizes -----------------------------------------
cat("\n", strrep("=", 60), "\n", sep = "")
cat("SUMMARY: THE MISSING DATA TRAP\n")
cat(strrep("=", 60), "\n", sep = "")
models <- list(
  "Treatment only"             = m1,
  "+ FX exposure"              = m2,
  "+ age, female, ed, urban"   = m3a,
  "+ income_quintile"          = m3b,
  "+ left_right"               = m3c,
  "+ both income & LR"         = m3d,
  "Treatment x FX interaction" = m4
)
for (name in names(models)) {
  cat(sprintf("  %-35s N = %d\n", name, length(models[[name]]$y)))
}

# -- Export summary statistics table ---------------------------------
# Treat missing fx_status as 0 (matches pandas, where NaN == "current" is False)
df$fx_current <- as.integer(!is.na(df$fx_status) & df$fx_status == "current")
df$fx_past    <- as.integer(!is.na(df$fx_status) & df$fx_status == "past")

summary_vars <- c(
  supports_intervention = "Supports intervention (0/1)",
  age                   = "Age (years)",
  female                = "Female (0/1)",
  ed_level              = "Education level (1--5)",
  urban_rural           = "Urban--rural (1--5)",
  income_quintile       = "Income quintile (1--5)",
  left_right            = "Left--right placement (0--10)",
  fx_current            = "FX exposed, current (0/1)",
  fx_past               = "FX exposed, past (0/1)"
)

summary_latex <- "\\begin{tabular}{lrrrrr}\n\\toprule\nVariable & N & Mean & SD & Min & Max \\\\\n\\midrule\n"
for (var in names(summary_vars)) {
  s <- df[[var]][!is.na(df[[var]])]
  summary_latex <- paste0(
    summary_latex,
    sprintf("%s & %d & %.2f & %.2f & %.2f & %.2f \\\\\n",
            summary_vars[[var]], length(s), mean(s), sd(s), min(s), max(s)))
}
summary_latex <- paste0(summary_latex, "\\bottomrule\n\\end{tabular}\n")

cat(summary_latex, file = "session_3/output/summary_stats.tex")
cat("\nSaved: session_3/output/summary_stats.tex\n")

# -- Export main regression table ------------------------------------
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

# Helpers to pull coefficient/SE/p by exact term name (NA if absent).
getp <- function(m, term) if (term %in% names(coef(m))) coef(m)[term] else NA
gets <- function(m, term) {
  cf <- summary(m)$coefficients
  if (term %in% rownames(cf)) cf[term, "Std. Error"] else NA
}
getpval <- function(m, term) {
  cf <- summary(m)$coefficients
  if (term %in% rownames(cf)) cf[term, 4] else NA
}

# Two columns: treatment-only vs. with FX + demographics
main_latex <- "\\begin{tabular}{lcc}\n\\toprule\n & (1) & (2) \\\\\n & \\textit{Baseline} & \\textit{+ Controls} \\\\\n\\midrule\n"

treatment_params <- c(
  treatmentinfo    = "Info treatment",
  treatmenthistory = "History treatment",
  treatmentHungary = "Hungary treatment"
)
for (param in names(treatment_params)) {
  label <- treatment_params[[param]]
  c1 <- getp(m1, param);  s1 <- gets(m1, param);  p1 <- getpval(m1, param)
  c2 <- getp(m3a, param); s2 <- gets(m3a, param); p2 <- getpval(m3a, param)
  main_latex <- paste0(main_latex,
    sprintf("%s & $%.3f^{%s}$ & $%.3f^{%s}$ \\\\\n", label, c1, stars(p1), c2, stars(p2)),
    sprintf(" & $(%.3f)$ & $(%.3f)$ \\\\[0.3em]\n", s1, s2))
}

fx_params <- c(
  fx_statuscurrent = "FX exposed (current)",
  fx_statuspast    = "FX exposed (past)"
)
for (param in names(fx_params)) {
  label <- fx_params[[param]]
  if (param %in% names(coef(m3a))) {
    c <- getp(m3a, param); s <- gets(m3a, param); p <- getpval(m3a, param)
    main_latex <- paste0(main_latex,
      sprintf("%s & & $%.3f^{%s}$ \\\\\n", label, c, stars(p)),
      sprintf(" & & $(%.3f)$ \\\\[0.3em]\n", s))
  }
}

main_latex <- paste0(main_latex,
  "\\midrule\n",
  "Demographic controls & No & Yes \\\\\n",
  "Survey weights & Yes & Yes \\\\\n",
  sprintf("N & %d & %d \\\\\n", length(m1$y), length(m3a$y)),
  "\\bottomrule\n",
  "\\multicolumn{3}{l}{\\scriptsize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.} \\\\\n",
  "\\end{tabular}\n")

cat(main_latex, file = "session_3/output/main_table.tex")
cat("Saved: session_3/output/main_table.tex\n")
