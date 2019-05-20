*Pour le calcul des consommations intermédiaires domestique dans la HC importée

clear
set more off

if ("`c(username)'"=="guillaumedaudin") global dir "~/Documents/Recherche/2017 BDF_Commerce VA"
if ("`c(hostname)'" == "widv269a") global dir  "D:\home\T822289\CommerceVA" 
if ("`c(hostname)'" == "FP1376CD") global dir  "T:\CommerceVA" 

if ("`c(username)'"=="guillaumedaudin") global dirgit "~/Documents/Recherche/2017 BDF_Commerce VA/commerce_VA_inflation"
if ("`c(hostname)'" == "widv269a") global dirgit  "D:\home\T822289\CommerceVA\GIT\commerce_va_inflation" 
if ("`c(hostname)'" == "FP1376CD") global dirgit  "T:\CommerceVA\GIT\commerce_va_inflation" 



capture log close
log using "$dir/$S_DATE.log", replace
set matsize 7000



capture program drop contenu_dom_HC_impt // fournit le % des ci dom dans la HC impt
program  contenu_dom_HC_impt
args yrs source hze pays_int
*Année, source, hze_not ou hze_yes pour pays membres de la ZE et pays hors ZE, pays_int celui auquel on s'intéresse

capture erase "$dir/Bases/contenu_dom_HC_impt_`yrs'_`source'_`hze'.dta"

* exemple  

*Ouverture de la base contenant le vecteur ligne de production par pays et secteurs

use "$dir/Bases/`source'_ICIO_`yrs'.dta"
if "`source'"=="TIVA" {
	drop if v1 == "VA+TAXSUB" | v1 == "OUT"
	gen pays=upper(substr(v1,1,3))
	gen secteur = upper(substr(v1,5,.))
	order pays secteur
}

if "`source'"=="TIVA_REV4" {
	drop if v1 == "VALU" | strmatch(v1, "*TAXSUB") == 1 | v1 == "OUTPUT"
	generate pays = strupper(substr(v1,1,strpos(v1,"_")-1))
	generate secteur = strupper(substr(v1,strpos(v1,"_")+1,.))
	order pays secteur
}



* on conserve uniquement les CI, en éliminants les emplois finals
if "`source'"=="WIOD" {
	 
	drop *57 *58 *59 *60 *61
	rename Country pays
	rename IndustryCode secteur
	order pays secteur
	sort pays secteur
	drop if pays=="TOT"
	* on supprime les lignes total intermediate conso à GO de la base wiod_icio
}


keep pays $var_entree_sortie




** Ici, on fait Y.Btilde



foreach var of varlist $var_entree_sortie {
*	On cherche à enlever les auto-consommations intermédiaires
	if "`source'" == "TIVA" | "`source'" == "TIVA_REV4" local pays_colonne = upper(substr("`var'",1,3))
	if "`source'" == "WIOD" local pays_colonne = substr("`var'",2,3)
	
	replace `var' = 0 if pays=="`pays_colonne'"	
	if strpos(upper("$china"),upper("`pays_colonne'"))!=0  {
			foreach i of global china {	
			replace `var' = 0 if upper(pays) == upper("`i'")
		}
	}
	
	
	if strpos(upper("$mexique"),upper("`pays_colonne'"))!=0 {
			foreach i of global mexique {	
			replace `var' = 0 if upper(pays) == upper("`i'")
		}
	}
		

	*** Puis on enlève les CI qui ne viennent pas du pays d'intérêt
	
	if "`pays_int'" == "CHN" {
		replace `var' = 0 if strpos(upper("$china"),upper(pays))==0
	}
	
	if "`pays_int'" == "MEX" {
		replace `var' = 0 if strpos(upper("$mexique"),upper(pays))==0
	}
			
	if ("`pays_int'" != "CHN" & "`pays_int'" != "MEX") | "`source'" == "WIOD" {
		replace `var' = 0 if upper(pays)!=upper("`pays_int'") 
	}
	
	
	display "`hze' -- `pays_colonne'" 
}



*somme des CI pour chaque secteur de chaque pays
collapse (sum) $var_entree_sortie

display "after collapse"


*obtention de deux lignes, l'une de CI, l'autre de prod pour chaque secteur, issue de la base  `source'_`yrs'_OUT
append using "$dir/Bases/`source'_`yrs'_OUT.dta"

*transpositin en colonne, puis création d'un ratio de CI importées par secteur 
xpose, clear varname
rename v1 ci_dom
rename v2 prod_etranger
generate ratio_ci_dom_prod_etranger=ci_dom / prod_etranger




/*
if "`source'"=="TIVA" {
	generate pays = strlower(substr(_varname,1,3))
	generate sector = strlower(substr(_varname,strpos(_varname,"_")+1,.))
}


*renomme les pays et secteur à partir de la base csv_WIOD
if "`source'"=="WIOD" {
*/


merge 1:1 _n using "$dir/Bases/csv_`source'.dta"
rename c pays
rename s sector
replace sector = upper(sector)
replace pays=upper(pays)
drop p_shock
drop _merge




generate pays_conso = upper("`pays_int'")
generate year= `yrs'
if "`source'"=="TIVA"  replace pays =upper(pays)
if "`source'"=="TIVA_REV4"  replace pays =upper(pays)
if "`source'"=="TIVA_REV4"  replace sector =upper(sector)
if "`source'"=="TIVA_REV4"  replace pays_conso =upper(pays_conso)


merge 1:1 pays sector year pays_conso using "$dir/Bases/HC_`source'.dta", keep (1 3)

assert _merge==3
drop _merge


gen contenu_dom_HC_etranger=conso*ratio_ci_dom_prod_etranger
collapse (sum) contenu_dom_HC_etranger conso, by(pays_conso year)
replace contenu_dom_HC_etranger = contenu_dom_HC_etranger/conso
rename pays_conso pays
replace pays =upper(pays)

capture append using "$dir/Bases/contenu_dom_HC_impt_`yrs'_`source'_`hze'.dta"
sort pays

save "$dir/Bases/contenu_dom_HC_impt_`yrs'_`source'_`hze'.dta", replace
* enregistrement des ratio de CI dom par secteur par pays d'interet









end





**pOUR TEST




foreach source in  /*WIOD TIVA*/ TIVA_REV4 {

	if "`source'"=="WIOD" global start_year 2000	
	if "`source'"=="TIVA" global start_year 1995
	if "`source'"=="TIVA_REV4" global start_year 2015


	if "`source'"=="WIOD" global end_year 2014
	if "`source'"=="TIVA" global end_year 2011
	if "`source'"=="TIVA_REV4" global end_year 2015

	
	do "$dirgit/Definition_pays_secteur.do"   
	Definition_pays_secteur `source'



*	foreach i of numlist 2010  {
	foreach i of numlist $start_year (1)$end_year  {
		capture erase "$dir/Bases/contenu_dom_HC_impt_`yrs'_`source'_hze_non.dta"
		capture erase "$dir/Bases/contenu_dom_HC_impt_`yrs'_`source'_hze_yes.dta"
		foreach pays of global country_hc {
			contenu_dom_HC_impt `i' `source' hze_not `pays'
			contenu_dom_HC_impt `i' `source' hze_yes `pays'
		}
	}
}
