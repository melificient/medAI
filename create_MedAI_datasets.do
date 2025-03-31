
cd "/Users/mouellet/Library/CloudStorage/Dropbox/HBS/ARIEL/astern_projects/NBER AI/Boris_Glenn_paper/2024/github"
*cd "https://github.com/melificient/medAI"


*process FDA list of AI/ML devices pulled May 2024
import excel using raw/fda_ai_devices_may2024.xlsx, clear firstrow allstring
keep SubmissionNumber 
rename SubmissionNumber idnumber
tempfile fda_ai_devices
save `fda_ai_devices', replace

*process which 2010-2023 FDA list of AI/ML have readable documents and software as keyword
import excel using raw/software_readables.xlsx, clear firstrow allstring
destring, replace
tempfile software_readables
save `software_readables', replace

*process FDA 510k data pulled April 2024
import excel using raw/pmn96cur.xlsx, clear firstrow allstring
rename *, lower
rename knumber idnumber
rename decision decisioncode
gen dtrec=date(datereceived,"MD20Y")
gen dtdec=date(decisiondate,"MD20Y")
format dt* %td
gen yrdec=year(dtdec)
gen yrrec=year(dtrec)
keep idnumber applicant street1 city state  zip devicename productcode decisioncode classadvisecomm stateorsumm  type dtrec dtdec yrdec yrrec 
tempfile fda_510k_devices
save `fda_510k_devices', replace

*process MAUDE adverse events data for 823 devives at idnumber level
u 943_AEs_for_fda_devices, clear
gen adverse_events=1
merge m:1 idnumber using `fda_510k_devices',keepusing(dtdec) keep(1 3)
gen dtae=date(date_received, "MD20Y")
format dtae %td
gen timetoAE=(dtae-dtdec)/365.25
gen ae_3mths=adverse_events if timetoAE<=(3/12)
gen ae_6mths=adverse_events if timetoAE<=(6/12)
gen ae_9mths=adverse_events if timetoAE<=(9/12)
gen ae_1yr=adverse_events if timetoAE<=1
gen ae_2yr=adverse_events if timetoAE<=2
collapse (sum) adverse_events ae_3mths ae_6mths ae_9mths ae_1yr ae_2yr, by(idnumber)
label var ae_3mths "AEs within 3 months of FDA approval"
label var ae_6mths "AEs within 6 months of FDA approval"
label var ae_9mths "AEs within 9 months of FDA approval"
label var ae_1yr "AEs within 1 year of FDA approval"
label var ae_2yr "AEs within 2 years of FDA approval"
label var adverse_events "Total adverse_events for that device"
*tab report_source_code
*REPORT_SOUR |
*    CE_CODE |      Freq.     Percent        Cum.
*------------+-----------------------------------
*          M |        943      100.00      100.00
*------------+-----------------------------------
*      Total |        943      100.00
*all mandatory so code mandatory as same
gen adverse_events_mand = adverse_events
gen ae_mand_3mths = ae_3mths
gen ae_mand_6mths = ae_6mths
gen ae_mand_9mths = ae_9mths
gen ae_mand_1yr = ae_1yr
gen ae_mand_2yr = ae_2yr
label var adverse_events_mand "Total Mandatory adverse_events for that device"
label var ae_mand_3mths "Mandatory AEs within 3 months of FDA approval"
label var ae_mand_6mths "Mandatory AEs within 6 months of FDA approval"
label var ae_mand_9mths "Mandatory AEs within 9 months of FDA approval"
label var ae_mand_1yr "Mandatory AEs within 1 year of FDA approval"
label var ae_mand_2yr "Mandatory AEs within 2 years of FDA approval"
tempfile ae_counts
count
save `ae_counts', replace


u  `fda_510k_devices', clear
*restrict to 2010 to 2023
keep if yrdec>=2010 & yrdec<=2023
*restrict to FDA AI devices
merge 1:1 idnumber using `fda_ai_devices',keep(1 3)
gen fda_ai=(_merge==3)
drop _merge
keep if fda_ai==1
*restrict to devices with machine readable documents and bring in software keyword
merge 1:1 idnumber using `software_readables',keep(3)
drop _merge
count
keep if machineread_dum==1
drop machineread_dum
merge 1:1 idnumber using `ae_counts',keep(1 3)
drop _merge
save 823_fda_devices_withAEs, replace



