

clear  
set more off
if ("`c(username)'"=="guillaumedaudin") global dir "~/Documents/Recherche/2017 BDF_Commerce VA"
else global dir "\\intra\partages\au_dcpm\DiagConj\Commun\CommerceVA"


*capture log close
*log using "$dir/$S_DATE.log", replace


use "$dir/Bases/csv_WIOD.dta", clear
replace c=upper(c)
replace s=upper(s)
generate agregat_secteur="na" 
replace agregat_secteur="alimentaire" if s=="A01" || s=="A03"

*NEIG: bien manuf hors energie
replace agregat_secteur="neig" if s=="A02" || s=="C10-C12"|| s=="C13-C15" ||s=="C16" || s=="C17" ||s=="C18"|| s=="C20"|| s=="C21"|| s=="C22"|| s=="C23"||s=="C24"||s=="C25"||s=="C26"||s=="C27"|| s=="C28"||s=="C29" || s=="C30" || s=="C31_C32"|| s=="C33"||s=="F"

replace agregat_secteur="services" if s=="E36" || s=="E37-39" || s=="H49" || s=="H50" || s=="H51" || s=="H52" || s=="H53" || s=="I"|| s=="J58"|| s=="J59_J60" || s=="J61" || s=="J62_J63" || s=="K64" || s=="K65" || s=="K66" ||  s=="E36" || s=="E37-E39" || s=="L68" || s=="M69_M70"|| s=="M71" || s=="M72" || s=="M73" || s=="M74_M75" || s=="N" || s=="O84" || s=="P85" ||  s=="Q" ||  s=="R_S" ||  s=="G45" ||  s=="G46" ||  s=="G47" || s=="T" || s=="U"

replace agregat_secteur="energie" if s=="D35"  || s=="C19" || s=="B"
 save "$dir/Bases/csv_WIOD.dta", replace
