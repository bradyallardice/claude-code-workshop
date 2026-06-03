# Session 2 Solution -- Part 3: Robustness Checks and LaTeX Table
# Generates specification variants and outputs a publication-style LaTeX table.
#
# Run from the project root (AIAgentsCourse/):
#   Rscript session_3/scripts/solution_robustness.R
#
# Note on weights: see solution_estimate.R -- glm() weights reproduce the
# statsmodels freq_weights point estimates.

library(readr)

# -- Load merged data -------------------------------------------------
df <- read_csv("session_3/output/merged_survey.csv", show_col_types = FALSE)

# Set reference categories (first level = reference)
df$treatment <- factor(df$treatment,
                       levels = c("cntrl", "info", "history", "Hungary"))
df$fx_status <- factor(df$fx_status,
                       levels = c("none", "current", "past"))

# Create derived variables
df$any_info <- as.integer(df$treatment != "cntrl")

# Complete cases subset (constant N across all specifications)
complete_cols <- c("supports_intervention", "treatment", "fx_status",
                   "age", "female", "ed_level", "urban_rural",
                   "income_quintile", "left_right", "survey_weight")
df_complete <- df[complete.cases(df[, complete_cols]), ]
cat("Complete cases:", nrow(df_complete), "\n")


# -- Helper -----------------------------------------------------------
fit_logit <- function(formula, data, weights_col = NULL) {
  # Fit logistic regression, return model object.
  if (!is.null(weights_col)) {
    data$.w <- data[[weights_col]]  # glm() resolves `weights` inside `data`
    glm(formula, data = data, family = binomial(), weights = .w)
  } else {
    glm(formula, data = data, family = binomial())
  }
}


# -- Define specifications -------------------------------------------
treat <- "treatment"
fx3   <- "fx_status"
demog <- "age + female + ed_level + urban_rural"
full  <- "age + female + ed_level + urban_rural + income_quintile + left_right"

specs <- list(
  "(1)" = list(formula = sprintf("supports_intervention ~ %s", treat),
               data = df, weights = "survey_weight", label = "Base (weighted)"),
  "(2)" = list(formula = sprintf("supports_intervention ~ %s", treat),
               data = df, weights = NULL, label = "Base (unweighted)"),
  "(3)" = list(formula = sprintf("supports_intervention ~ %s + %s + %s", treat, fx3, demog),
               data = df, weights = "survey_weight", label = "+ Controls"),
  "(4)" = list(formula = sprintf("supports_intervention ~ %s + %s + %s", treat, fx3, full),
               data = df, weights = "survey_weight", label = "Full controls"),
  "(5)" = list(formula = sprintf("supports_intervention ~ any_info + %s + %s", fx3, demog),
               data = df, weights = "survey_weight", label = "Pooled treatment"),
  "(6)" = list(formula = sprintf("supports_intervention ~ %s + %s + %s", treat, fx3, demog),
               data = df[df$urban_rural >= 2, ], weights = "survey_weight", label = "Urban only")
)

# -- Fit all models ---------------------------------------------------
models <- list()
for (name in names(specs)) {
  spec <- specs[[name]]
  m <- fit_logit(as.formula(spec$formula), spec$data, spec$weights)
  models[[name]] <- m
  cat(sprintf("%s %-20s N=%d\n", name, spec$label, length(m$y)))
}

# -- Key coefficients for comparison ---------------------------------
cat("\n=== TREATMENT EFFECTS ACROSS SPECIFICATIONS ===\n")
cat(sprintf("%-6s %-20s %6s  %10s %8s\n", "Spec", "Label", "N", "Info coef", "Info p"))
cat(strrep("-", 60), "\n")

for (name in names(specs)) {
  m <- models[[name]]
  cf <- summary(m)$coefficients
  info_key <- grep("info", rownames(cf), ignore.case = TRUE, value = TRUE)
  if (length(info_key) > 0) {
    k <- info_key[1]
    cat(sprintf("%-6s %-20s %6d  %10.4f %8.4f\n",
                name, specs[[name]]$label, length(m$y), cf[k, 1], cf[k, 4]))
  } else {
    cat(sprintf("%-6s %-20s %6d  %10s\n",
                name, specs[[name]]$label, length(m$y), "N/A"))
  }
}


# -- Generate LaTeX table --------------------------------------------
coef_str <- function(model, param_substr) {
  # Extract coefficient and SE as formatted strings with significance stars.
  cf <- summary(model)$coefficients
  for (key in rownames(cf)) {
    if (grepl(param_substr, key, fixed = TRUE)) {
      coef <- cf[key, 1]; se <- cf[key, 2]; p <- cf[key, 4]
      st <- if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
      return(c(sprintf("$%.3f%s$", coef, st), sprintf("$(%.3f)$", se)))
    }
  }
  c("", "")
}

# Row definitions: (label, R term substring, [include per column])
#                                                  (1)    (2)    (3)    (4)    (5)    (6)
rows <- list(
  list("Info treatment",       "treatmentinfo",     c(TRUE,  TRUE,  TRUE,  TRUE,  FALSE, TRUE)),
  list("History treatment",    "treatmenthistory",  c(TRUE,  TRUE,  TRUE,  TRUE,  FALSE, TRUE)),
  list("Hungary treatment",    "treatmentHungary",  c(TRUE,  TRUE,  TRUE,  TRUE,  FALSE, TRUE)),
  list("Any information",      "any_info",          c(FALSE, FALSE, FALSE, FALSE, TRUE,  FALSE)),
  list("FX exposed (current)", "fx_statuscurrent",  c(FALSE, FALSE, TRUE,  TRUE,  TRUE,  TRUE)),
  list("FX exposed (past)",    "fx_statuspast",     c(FALSE, FALSE, TRUE,  TRUE,  TRUE,  TRUE))
)

model_keys <- c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)")

L <- character(0)
L <- c(L, "\\begin{table}[htbp]")
L <- c(L, "\\centering")
L <- c(L, "\\caption{Logistic Regression: Support for Government Intervention}")
L <- c(L, "\\label{tab:robustness}")
L <- c(L, "\\small")
L <- c(L, paste0("\\begin{tabular}{l", strrep("c", length(model_keys)), "}"))
L <- c(L, "\\toprule")

# Header
L <- c(L, paste0(" & ", paste(model_keys, collapse = " & "), " \\\\"))

# Sub-header with labels
sublabels <- sapply(model_keys, function(k) specs[[k]]$label)
subheader <- paste(sprintf("\\scriptsize %s", sublabels), collapse = " & ")
L <- c(L, paste0(" & ", subheader, " \\\\"))
L <- c(L, "\\midrule")

# Coefficient rows
for (row in rows) {
  row_label <- row[[1]]; param_key <- row[[2]]; include_flags <- row[[3]]
  coef_cells <- character(length(model_keys))
  se_cells   <- character(length(model_keys))
  for (i in seq_along(model_keys)) {
    if (include_flags[i]) {
      cs <- coef_str(models[[model_keys[i]]], param_key)
      coef_cells[i] <- cs[1]; se_cells[i] <- cs[2]
    } else {
      coef_cells[i] <- ""; se_cells[i] <- ""
    }
  }
  L <- c(L, paste0(row_label, " & ", paste(coef_cells, collapse = " & "), " \\\\"))
  L <- c(L, paste0(" & ", paste(se_cells, collapse = " & "), " \\\\[0.3em]"))
}

L <- c(L, "\\midrule")

# Controls row
controls_row <- c("No", "No", "Yes", "Yes", "Yes", "Yes")
L <- c(L, paste0("Demographic controls & ", paste(controls_row, collapse = " & "), " \\\\"))

# Weights row
weights_row <- c("Yes", "No", "Yes", "Yes", "Yes", "Yes")
L <- c(L, paste0("Survey weights & ", paste(weights_row, collapse = " & "), " \\\\"))

# Sample row
sample_row <- c("Full", "Full", "Full", "Full", "Full", "Urban")
L <- c(L, paste0("Sample & ", paste(sample_row, collapse = " & "), " \\\\"))

# N row
n_row <- sapply(model_keys, function(k) as.character(length(models[[k]]$y)))
L <- c(L, paste0("N & ", paste(n_row, collapse = " & "), " \\\\"))

L <- c(L, "\\bottomrule")
L <- c(L, paste0("\\multicolumn{", length(model_keys) + 1,
                 "}{l}{\\scriptsize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$. Reference: control group, no FX loan.} \\\\"))
L <- c(L, "\\end{tabular}")
L <- c(L, "\\end{table}")

latex_output <- paste(L, collapse = "\n")

# Save LaTeX table
cat(latex_output, file = "session_3/output/robustness_table.tex")

cat("\n\nLaTeX table saved to session_3/output/robustness_table.tex\n")
cat("\n", latex_output, "\n", sep = "")
