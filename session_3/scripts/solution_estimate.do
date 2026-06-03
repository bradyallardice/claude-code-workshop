* Session 2 Solution -- Part 2: Specify and Estimate
* Logistic regression of supports_intervention on treatment, with progressive
* addition of controls to demonstrate the missing data trap.
*
* Run from the project root (AIAgentsCourse/):
*   do session_3/scripts/solution_estimate.do
*
* Note on weights: the Python version uses statsmodels freq_weights. We use
* Stata [iweight], which weights the likelihood the same way and so reproduces
* the point estimates for non-integer survey weights. (pweight would instead
* give design-robust SEs; fweight requires integer weights.)

clear all
set more off

* -- Load merged data ------------------------------------------------
import delimited "session_3/output/merged_survey.csv", clear case(preserve)

* -- Set reference categories explicitly -----------------------------
* Numeric codes chosen so the lowest value is the reference category
* (cntrl for treatment, none for fx_status), matching the Python setup.
gen byte treat_n = .
replace treat_n = 0 if treatment == "cntrl"
replace treat_n = 1 if treatment == "info"
replace treat_n = 2 if treatment == "history"
replace treat_n = 3 if treatment == "Hungary"
label define treatlbl 0 "cntrl" 1 "info" 2 "history" 3 "Hungary"
label values treat_n treatlbl

gen byte fx_n = .
replace fx_n = 0 if fx_status == "none"
replace fx_n = 1 if fx_status == "current"
replace fx_n = 2 if fx_status == "past"
label define fxlbl 0 "none" 1 "current" 2 "past"
label values fx_n fxlbl

* -- Step 4: Base model -- treatment only, weighted ------------------
display _newline(2) "{hline 60}"
display "MODEL: Base model (treatment only, weighted)"
display "{hline 60}"
logit supports_intervention ib0.treat_n [iweight=survey_weight]
estimates store m1

* -- Step 5: Add FX exposure -----------------------------------------
display _newline(2) "{hline 60}"
display "MODEL: + FX exposure"
display "{hline 60}"
logit supports_intervention ib0.treat_n ib0.fx_n [iweight=survey_weight]
estimates store m2

* -- Step 6: Add demographic controls --------------------------------
* First WITHOUT income and left_right (no additional missingness)
display _newline(2) "{hline 60}"
display "MODEL: + demographics (no income, no left-right)"
display "{hline 60}"
logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural [iweight=survey_weight]
estimates store m3a

* Now WITH income_quintile (drops ~525)
display _newline(2) "{hline 60}"
display "MODEL: + income_quintile (THE MISSING DATA TRAP)"
display "{hline 60}"
logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural income_quintile [iweight=survey_weight]
estimates store m3b

* Now WITH left_right (drops ~504)
display _newline(2) "{hline 60}"
display "MODEL: + left_right"
display "{hline 60}"
logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural left_right [iweight=survey_weight]
estimates store m3c

* Now WITH both (drops ~859)
display _newline(2) "{hline 60}"
display "MODEL: + both income_quintile and left_right"
display "{hline 60}"
logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural income_quintile left_right [iweight=survey_weight]
estimates store m3d

* -- Step 7: Interaction -- treatment x FX exposure ------------------
display _newline(2) "{hline 60}"
display "MODEL: Treatment x FX exposure interaction"
display "{hline 60}"
logit supports_intervention ib0.treat_n##ib0.fx_n age female ed_level urban_rural [iweight=survey_weight]
estimates store m4

* -- Summary of sample sizes -----------------------------------------
display _newline(2) "{hline 60}"
display "SUMMARY: THE MISSING DATA TRAP"
display "{hline 60}"
foreach m in m1 m2 m3a m3b m3c m3d m4 {
    quietly estimates restore `m'
    display "  `m'  N = " e(N)
}

* -- Export summary statistics table ---------------------------------
gen byte fx_current = fx_status == "current"
gen byte fx_past    = fx_status == "past"

capture file close sf
file open sf using "session_3/output/summary_stats.tex", write replace
file write sf "\begin{tabular}{lrrrrr}" _n "\toprule" _n
file write sf "Variable & N & Mean & SD & Min & Max \\" _n "\midrule" _n

* variable / printed label pairs
local svars supports_intervention age female ed_level urban_rural income_quintile left_right fx_current fx_past
local slabs `" "Supports intervention (0/1)" "Age (years)" "Female (0/1)" "Education level (1--5)" "Urban--rural (1--5)" "Income quintile (1--5)" "Left--right placement (0--10)" "FX exposed, current (0/1)" "FX exposed, past (0/1)" "'
local i = 1
foreach v of local svars {
    local lab : word `i' of `slabs'
    quietly summarize `v'
    file write sf "`lab' & " (r(N)) " & " %4.2f (r(mean)) " & " %4.2f (r(sd)) ///
        " & " %4.2f (r(min)) " & " %4.2f (r(max)) " \\" _n
    local ++i
}
file write sf "\bottomrule" _n "\end{tabular}" _n
file close sf
display _newline "Saved: session_3/output/summary_stats.tex"

* -- Export main regression table ------------------------------------
* Helper returns a coefficient string with stars in `cstr' and an SE
* string in `sstr' for term `term' of the currently restored model.
* (Pass an empty term to emit blank cells.)
capture program drop fmtcoef
program define fmtcoef, rclass
    args term
    if "`term'" == "" {
        return local cstr ""
        return local sstr ""
        exit
    }
    local b  = _b[`term']
    local se = _se[`term']
    local z  = `b' / `se'
    local p  = 2 * (1 - normal(abs(`z')))
    local st = ""
    if `p' < 0.10 local st "*"
    if `p' < 0.05 local st "**"
    if `p' < 0.01 local st "***"
    return local cstr = "$" + string(`b', "%5.3f") + "^{" + "`st'" + "}$"
    return local sstr = "$(" + string(`se', "%5.3f") + ")$"
end

capture file close mf
file open mf using "session_3/output/main_table.tex", write replace
file write mf "\begin{tabular}{lcc}" _n "\toprule" _n
file write mf " & (1) & (2) \\" _n
file write mf " & \textit{Baseline} & \textit{+ Controls} \\" _n "\midrule" _n

* Treatment rows: column (1) from m1, column (2) from m3a
local trows 1.treat_n 2.treat_n 3.treat_n
local tlabs `" "Info treatment" "History treatment" "Hungary treatment" "'
local i = 1
foreach term of local trows {
    local lab : word `i' of `tlabs'
    quietly estimates restore m1
    fmtcoef `term'
    local c1 "`r(cstr)'"
    local s1 "`r(sstr)'"
    quietly estimates restore m3a
    fmtcoef `term'
    local c2 "`r(cstr)'"
    local s2 "`r(sstr)'"
    file write mf "`lab' & `c1' & `c2' \\" _n
    file write mf " & `s1' & `s2' \\[0.3em]" _n
    local ++i
}

* FX rows: column (2) only (from m3a)
local frows 1.fx_n 2.fx_n
local flabs `" "FX exposed (current)" "FX exposed (past)" "'
local i = 1
quietly estimates restore m3a
foreach term of local frows {
    local lab : word `i' of `flabs'
    fmtcoef `term'
    file write mf "`lab' & & `r(cstr)' \\" _n
    file write mf " & & `r(sstr)' \\[0.3em]" _n
    local ++i
}

quietly estimates restore m1
local n1 = e(N)
quietly estimates restore m3a
local n3a = e(N)

file write mf "\midrule" _n
file write mf "Demographic controls & No & Yes \\" _n
file write mf "Survey weights & Yes & Yes \\" _n
file write mf "N & `n1' & `n3a' \\" _n
file write mf "\bottomrule" _n
file write mf "\multicolumn{3}{l}{\scriptsize \$^{***}p<0.01\$; \$^{**}p<0.05\$; \$^{*}p<0.1\$.} \\" _n
file write mf "\end{tabular}" _n
file close mf
display "Saved: session_3/output/main_table.tex"
