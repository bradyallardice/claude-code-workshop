* Session 2 Solution — Part 3: Robustness Checks and LaTeX Table (Stata version)
* Generates specification variants and outputs a publication-style LaTeX table.
* Requires: estout (ssc install estout)

clear all
set more off

* ── Load merged data ─────────────────────────────────────────────
import delimited "session_5/option_b/output/merged_survey.csv", clear varnames(1)

* Encode categorical variables with explicit reference categories
encode treatment, gen(treat_num)
encode fx_status, gen(fx_num)

* Identify the reference levels by their text labels
* cntrl = control, none = no FX exposure
levelsof treat_num if treatment == "cntrl", local(cntrl_level)
levelsof fx_num   if fx_status == "none",   local(none_level)

* Derived: any information treatment
gen any_info = (treatment != "cntrl")

* ── Fit six specifications ───────────────────────────────────────
* (1) Base, weighted
logit supports_intervention ib`cntrl_level'.treat_num [pweight=survey_weight]
estimates store m1
local n1 = e(N)

* (2) Base, unweighted
logit supports_intervention ib`cntrl_level'.treat_num
estimates store m2
local n2 = e(N)

* (3) + FX + demographics (weighted)
logit supports_intervention ib`cntrl_level'.treat_num ib`none_level'.fx_num ///
      age female ed_level urban_rural [pweight=survey_weight]
estimates store m3
local n3 = e(N)

* (4) Full controls (weighted)
logit supports_intervention ib`cntrl_level'.treat_num ib`none_level'.fx_num ///
      age female ed_level urban_rural income_quintile left_right [pweight=survey_weight]
estimates store m4
local n4 = e(N)

* (5) Pooled treatment (weighted)
logit supports_intervention any_info ib`none_level'.fx_num ///
      age female ed_level urban_rural [pweight=survey_weight]
estimates store m5
local n5 = e(N)

* (6) Urban only (weighted)
logit supports_intervention ib`cntrl_level'.treat_num ib`none_level'.fx_num ///
      age female ed_level urban_rural if urban_rural >= 2 [pweight=survey_weight]
estimates store m6
local n6 = e(N)

di _n "=== MODELS FITTED ==="
di "(1) Base (weighted):       N=`n1'"
di "(2) Base (unweighted):     N=`n2'"
di "(3) + Controls:            N=`n3'"
di "(4) Full controls:         N=`n4'"
di "(5) Pooled treatment:      N=`n5'"
di "(6) Urban only:            N=`n6'"

* ── Export LaTeX table with esttab ───────────────────────────────
* Renames make output labels consistent with the Python/R versions

esttab m1 m2 m3 m4 m5 m6 using "session_5/option_b/exercise_2/tables/robustness_table.tex", ///
    replace                                               ///
    label booktabs                                        ///
    b(%9.3f) se(%9.3f)                                    ///
    star(* 0.10 ** 0.05 *** 0.01)                         ///
    keep(2.treat_num 3.treat_num 4.treat_num              ///
         any_info 2.fx_num 3.fx_num)                      ///
    coeflabels(                                           ///
        2.treat_num "Info treatment"                      ///
        3.treat_num "History treatment"                   ///
        4.treat_num "Hungary treatment"                   ///
        any_info "Any information"                        ///
        2.fx_num "FX exposed (current)"                   ///
        3.fx_num "FX exposed (past)")                     ///
    mtitles("Base (weighted)" "Base (unweighted)"         ///
            "+ Controls" "Full controls"                  ///
            "Pooled treatment" "Urban only")              ///
    title(Logistic Regression: Support for Government Intervention) ///
    nonumbers nonotes                                     ///
    addnotes("\scriptsize \$^{***}p<0.01\$; \$^{**}p<0.05\$; \$^{*}p<0.1\$. Reference: control group, no FX loan.")

di _n "LaTeX table saved to session_5/option_b/exercise_2/tables/robustness_table.tex"
