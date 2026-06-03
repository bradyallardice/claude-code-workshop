* Generate FX exchange rate time series figure for the Session 3 LaTeX exercise.
* Plots the CHF/PLN exchange rate over time, highlighting the SNB floor removal
* event (January 15, 2015) that shocked Polish FX loan holders.
*
* Run from the project root (AIAgentsCourse/):
*   do session_3/scripts/generate_fx_figure.do

clear all
set more off

* -- Load FX data ----------------------------------------------------
* CSV columns: Jul.Day, YYYY/MM/DD, Wdy, CHF/EUR, CHF/PLN
* "/" is illegal in Stata variable names, so the importer renames the
* columns; we standardise them below.
import delimited "session_3/data/PLN_CHF_EUR_FXdata.csv", clear varnames(1)

* Build a Stata daily date from the YYYY/MM/DD string column (v2).
gen date = date(yyyymmdd, "YMD")
format date %td
sort date

* CHF/PLN imports as "chfpln" (slash stripped).
rename chfpln chf_pln

* -- Plot ------------------------------------------------------------
* SNB floor removal event: 15 Jan 2015.
local event = td(15jan2015)
quietly summarize chf_pln
local ymax = r(max)

twoway (line chf_pln date, lcolor("31 78 121") lwidth(medthick)), ///
    xline(`event', lcolor("192 0 0") lpattern(dash)) ///
    text(`=`ymax'*0.98' `event' "SNB removes CHF/EUR floor (Jan 15, 2015)", ///
        placement(e) color("192 0 0") size(small)) ///
    xlabel(, format(%tdMon_CCYY) angle(30)) ///
    xtitle("Date") ytitle("CHF/PLN Exchange Rate") ///
    title("Swiss Franc to Polish Zloty Exchange Rate") ///
    graphregion(color(white)) legend(off)

graph export "session_3/output/fx_rate_figure.png", replace width(2700)

display "Saved: session_3/output/fx_rate_figure.png"
