# Session 2 Solution — Part 3: Robustness Checks and LaTeX Table (R version)
# Generates specification variants and outputs a publication-style LaTeX table.

library(dplyr)
library(readr)

# ── Load merged data ─────────────────────────────────────────────
df <- read_csv("module_5/option_b/output/merged_survey.csv")

# Reference categories
df$treatment <- factor(df$treatment, levels = c("cntrl", "info", "history", "Hungary"))
df$fx_status <- factor(df$fx_status, levels = c("none", "current", "past"))

# Derived variable
df$any_info <- as.integer(df$treatment != "cntrl")

# ── Define specifications ────────────────────────────────────────
fit_logit <- function(formula, data, wt_col = NULL) {
  if (is.null(wt_col)) {
    glm(formula, data = data, family = binomial())
  } else {
    # Add weights column to data and reference by name to avoid scoping issues
    data$.wt <- data[[wt_col]]
    eval(bquote(glm(.(formula), data = data, family = binomial(), weights = .wt)))
  }
}

treat <- "treatment"
fx3   <- "fx_status"
demog <- "age + female + ed_level + urban_rural"
full  <- "age + female + ed_level + urban_rural + income_quintile + left_right"

specs <- list(
  "(1)" = list(formula = as.formula(paste("supports_intervention ~", treat)),
               data = df, wt_col = "survey_weight", label = "Base (weighted)"),
  "(2)" = list(formula = as.formula(paste("supports_intervention ~", treat)),
               data = df, wt_col = NULL,            label = "Base (unweighted)"),
  "(3)" = list(formula = as.formula(paste("supports_intervention ~", treat, "+", fx3, "+", demog)),
               data = df, wt_col = "survey_weight", label = "+ Controls"),
  "(4)" = list(formula = as.formula(paste("supports_intervention ~", treat, "+", fx3, "+", full)),
               data = df, wt_col = "survey_weight", label = "Full controls"),
  "(5)" = list(formula = as.formula(paste("supports_intervention ~ any_info +", fx3, "+", demog)),
               data = df, wt_col = "survey_weight", label = "Pooled treatment"),
  "(6)" = list(formula = as.formula(paste("supports_intervention ~", treat, "+", fx3, "+", demog)),
               data = df %>% filter(urban_rural >= 2), wt_col = "survey_weight", label = "Urban only")
)

# ── Fit all models ───────────────────────────────────────────────
models <- list()
for (name in names(specs)) {
  spec <- specs[[name]]
  m <- fit_logit(spec$formula, spec$data, spec$wt_col)
  models[[name]] <- m
  cat(sprintf("%s %-20s N=%d\n", name, spec$label, nobs(m)))
}

# ── Helper: extract coefficient with significance stars ──────────
coef_str <- function(model, param_substr) {
  coefs <- coef(summary(model))
  match_key <- grep(param_substr, rownames(coefs), fixed = TRUE)
  if (length(match_key) == 0) return(c("", ""))
  coef_val <- coefs[match_key[1], "Estimate"]
  se_val   <- coefs[match_key[1], "Std. Error"]
  p_val    <- coefs[match_key[1], "Pr(>|z|)"]
  stars <- if (p_val < 0.01) "***" else if (p_val < 0.05) "**" else if (p_val < 0.1) "*" else ""
  c(sprintf("$%.3f%s$", coef_val, stars), sprintf("$(%.3f)$", se_val))
}

# Row definitions: (label, param substring, include per column)
rows <- list(
  list("Info treatment",       "treatmentinfo",    c(T, T, T, T, F, T)),
  list("History treatment",    "treatmenthistory", c(T, T, T, T, F, T)),
  list("Hungary treatment",    "treatmentHungary", c(T, T, T, T, F, T)),
  list("Any information",      "any_info",         c(F, F, F, F, T, F)),
  list("FX exposed (current)", "fx_statuscurrent", c(F, F, T, T, T, T)),
  list("FX exposed (past)",    "fx_statuspast",    c(F, F, T, T, T, T))
)

model_keys <- names(specs)

# ── Build LaTeX table ────────────────────────────────────────────
latex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Logistic Regression: Support for Government Intervention}",
  "\\label{tab:robustness}",
  "\\small",
  paste0("\\begin{tabular}{l", paste(rep("c", length(model_keys)), collapse = ""), "}"),
  "\\toprule",
  paste(" &", paste(model_keys, collapse = " & "), "\\\\"),
  paste(" &", paste(sprintf("\\scriptsize %s", sapply(specs, function(s) s$label)), collapse = " & "), "\\\\"),
  "\\midrule"
)

for (r in rows) {
  row_label   <- r[[1]]
  param_key   <- r[[2]]
  include_flags <- r[[3]]
  coef_cells <- character(length(model_keys))
  se_cells   <- character(length(model_keys))
  for (i in seq_along(model_keys)) {
    if (include_flags[i]) {
      cs <- coef_str(models[[model_keys[i]]], param_key)
      coef_cells[i] <- cs[1]
      se_cells[i]   <- cs[2]
    }
  }
  latex <- c(latex,
             paste0(row_label, " & ", paste(coef_cells, collapse = " & "), " \\\\"),
             paste0(" & ", paste(se_cells, collapse = " & "), " \\\\[0.3em]"))
}

latex <- c(latex,
  "\\midrule",
  paste("Demographic controls &", paste(c("No", "No", "Yes", "Yes", "Yes", "Yes"), collapse = " & "), "\\\\"),
  paste("Survey weights &", paste(c("Yes", "No", "Yes", "Yes", "Yes", "Yes"), collapse = " & "), "\\\\"),
  paste("Sample &", paste(c("Full", "Full", "Full", "Full", "Full", "Urban"), collapse = " & "), "\\\\"),
  paste("N &", paste(sapply(model_keys, function(k) nobs(models[[k]])), collapse = " & "), "\\\\"),
  "\\bottomrule",
  sprintf("\\multicolumn{%d}{l}{\\scriptsize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$. Reference: control group, no FX loan.} \\\\",
          length(model_keys) + 1),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(latex, "module_5/option_b/exercise_2/tables/robustness_table.tex")
cat("\nLaTeX table saved to module_5/option_b/exercise_2/tables/robustness_table.tex\n")
