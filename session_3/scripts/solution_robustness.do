* Session 2 Solution -- Part 3: Robustness Checks and LaTeX Table
* Generates specification variants and outputs a publication-style LaTeX table.
*
* Run from the project root (AIAgentsCourse/):
*   do session_3/scripts/solution_robustness.do
*
* Note on weights: see solution_estimate.do -- [iweight] reproduces the
* statsmodels freq_weights point estimates for non-integer survey weights.

clear all
set more off

* -- Load merged data ------------------------------------------------
import delimited "session_3/output/merged_survey.csv", clear case(preserve)

* Set reference categories (lowest numeric code = reference)
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

* Create derived variables
gen byte any_info = treatment != "cntrl"

* Complete cases subset (constant N across all specifications)
egen byte _miss = rowmiss(supports_intervention treat_n fx_n age female ///
    ed_level urban_rural income_quintile left_right survey_weight)
quietly count if _miss == 0
display "Complete cases: " r(N)
drop _miss

* -- Fit all models --------------------------------------------------
quietly logit supports_intervention ib0.treat_n [iweight=survey_weight]
estimates store m1
display "(1) Base (weighted)      N=" e(N)

quietly logit supports_intervention ib0.treat_n
estimates store m2
display "(2) Base (unweighted)    N=" e(N)

quietly logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural [iweight=survey_weight]
estimates store m3
display "(3) + Controls           N=" e(N)

quietly logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural income_quintile left_right [iweight=survey_weight]
estimates store m4
display "(4) Full controls        N=" e(N)

quietly logit supports_intervention any_info ib0.fx_n age female ed_level urban_rural [iweight=survey_weight]
estimates store m5
display "(5) Pooled treatment     N=" e(N)

quietly logit supports_intervention ib0.treat_n ib0.fx_n age female ed_level urban_rural if urban_rural >= 2 [iweight=survey_weight]
estimates store m6
display "(6) Urban only           N=" e(N)

* -- Key coefficients for comparison ---------------------------------
display _newline "=== TREATMENT EFFECTS ACROSS SPECIFICATIONS ==="
display %-6s "Spec" " " %-20s "Label" " " %6s "N" "  " %10s "Info coef" " " %8s "Info p"
display "{hline 60}"
local labs `" "Base (weighted)" "Base (unweighted)" "+ Controls" "Full controls" "Pooled treatment" "Urban only" "'
local i = 1
foreach m in m1 m2 m3 m4 m5 m6 {
    local lab : word `i' of `labs'
    quietly estimates restore `m'
    * spec (5) pools treatment into any_info; others use the info dummy
    if "`m'" == "m5" {
        local term any_info
    }
    else {
        local term 1.treat_n
    }
    local b = _b[`term']
    local se = _se[`term']
    local p = 2 * (1 - normal(abs(`b'/`se')))
    display %-6s "(`i')" " " %-20s "`lab'" " " %6.0f e(N) "  " %10.4f `b' " " %8.4f `p'
    local ++i
}

* -- Generate LaTeX table --------------------------------------------
* Helper: formatted coefficient (+stars) and SE strings for `term'.
capture program drop fmtcoef
program define fmtcoef, rclass
    args term
    local b  = _b[`term']
    local se = _se[`term']
    local p  = 2 * (1 - normal(abs(`b'/`se')))
    local st = ""
    if `p' < 0.10 local st "*"
    if `p' < 0.05 local st "**"
    if `p' < 0.01 local st "***"
    return local cstr = "$" + string(`b', "%5.3f") + "`st'$"
    return local sstr = "$(" + string(`se', "%5.3f") + ")$"
end

capture file close tf
file open tf using "session_3/output/robustness_table.tex", write replace
file write tf "\begin{table}[htbp]" _n "\centering" _n
file write tf "\caption{Logistic Regression: Support for Government Intervention}" _n
file write tf "\label{tab:robustness}" _n "\small" _n
file write tf "\begin{tabular}{lcccccc}" _n "\toprule" _n
file write tf " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write tf " & \scriptsize Base (weighted) & \scriptsize Base (unweighted) & \scriptsize + Controls & \scriptsize Full controls & \scriptsize Pooled treatment & \scriptsize Urban only \\" _n
file write tf "\midrule" _n

* Coefficient rows. Each row: label, term, and which models (columns) include it.
* models order: m1 m2 m3 m4 m5 m6
local nrows = 6
local rlab1 "Info treatment"
local rterm1 "1.treat_n"
local rinc1 "1 1 1 1 0 1"
local rlab2 "History treatment"
local rterm2 "2.treat_n"
local rinc2 "1 1 1 1 0 1"
local rlab3 "Hungary treatment"
local rterm3 "3.treat_n"
local rinc3 "1 1 1 1 0 1"
local rlab4 "Any information"
local rterm4 "any_info"
local rinc4 "0 0 0 0 1 0"
local rlab5 "FX exposed (current)"
local rterm5 "1.fx_n"
local rinc5 "0 0 1 1 1 1"
local rlab6 "FX exposed (past)"
local rterm6 "2.fx_n"
local rinc6 "0 0 1 1 1 1"

forvalues r = 1/`nrows' {
    local lab "`rlab`r''"
    local term "`rterm`r''"
    local inc "`rinc`r''"
    local coefline "`lab'"
    local seline " "
    forvalues c = 1/6 {
        local flag : word `c' of `inc'
        if `flag' == 1 {
            quietly estimates restore m`c'
            fmtcoef `term'
            local coefline "`coefline' & `r(cstr)'"
            local seline "`seline' & `r(sstr)'"
        }
        else {
            local coefline "`coefline' & "
            local seline "`seline' & "
        }
    }
    file write tf "`coefline' \\" _n
    file write tf "`seline' \\[0.3em]" _n
}

file write tf "\midrule" _n
file write tf "Demographic controls & No & No & Yes & Yes & Yes & Yes \\" _n
file write tf "Survey weights & Yes & No & Yes & Yes & Yes & Yes \\" _n
file write tf "Sample & Full & Full & Full & Full & Full & Urban \\" _n

local nline "N"
forvalues c = 1/6 {
    quietly estimates restore m`c'
    local nline "`nline' & `=e(N)'"
}
file write tf "`nline' \\" _n
file write tf "\bottomrule" _n
file write tf "\multicolumn{7}{l}{\scriptsize \$^{***}p<0.01\$; \$^{**}p<0.05\$; \$^{*}p<0.1\$. Reference: control group, no FX loan.} \\" _n
file write tf "\end{tabular}" _n "\end{table}" _n
file close tf

display _newline(2) "LaTeX table saved to session_3/output/robustness_table.tex"
