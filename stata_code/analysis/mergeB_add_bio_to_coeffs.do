/* merge in ACLs and catch to the dataset with prices in it.*/

#delimit cr
version 15.1
pause off

local obs_by_stock ${data_main}\observed_by_stock_$vintage_string.dta
local observer_all ${data_main}\sector_coverage_rates_$vintage_string.dta


local bio_data $data_external/annual_catch_and_acl_$vintage_string.dta 
local prices $data_main/dmis_output_species_prices_${vintage_string}.dta

local cOLS_coefficients "${my_results}/constrained_least_squares_${vintage_string}.dta" 
local cOLS_coefficients "${my_results}/nls_least_squares_quarterly_GDPDEF${vintage_string}.dta" 

local out_dataset "${my_results}/ols_tested_mergedGDP_${vintage_string}.dta" 



/* fuel. we'll use May 1 fuel prices or 1st observed month if May isn't available. Be careful of first and last years */
use  "$data_external\diesel_${vintage_string}.dta", clear
drop if DDFUELNYH==.
gen year=year(daten)
gen month=month(daten)
gen mark=0
replace mark=1 if month==5
bysort year: egen tm=total(mark)
bysort year: replace mark=1 if tm==0 & mark==0 & _n==1
keep if mark==1
keep year DDFUELNYH
rename year fishing_year
tempfile fuelprice
save `fuelprice'

use  "$data_external/deflatorsQ_${vintage_string}.dta", clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
save `deflators'












use `prices', clear
merge m:1 fishing_year using `fuelprice', keep(1 3)
assert _merge==3
drop _merge


gen dateq=qofd(dofm(trip_monthly_date))
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3
/*I've normalized by GDP deflator */
replace dlr_dollar=dlr_dollar/fGDP
rename dlr_dollar dlr_dollarGDP
gen DDFUEL_R=DDFUELNYH/fGDP

collapse (sum) dlr_live dlr_dollar (first) DDFUELNYH DDFUEL_R, by(stockcode fishing_year stock_id)

gen live_priceGDP=dlr_dollar/dlr_live
tsset stockcode fishing_year
keep stockcode fishing_year live_price  DDFUELNYH DDFUEL_R
gen lag_live_priceGDP=l1.live_price


pause


tempfile price_clean
save `price_clean'


use `bio_data', clear
keep fishing_year stockcode stock sector_livemt_acl sector_livemt_catch
tsset stockcode fishing_year
/* observer coverage by stock*/

merge 1:1 stockcode fishing_year using `obs_by_stock', keep(1 3)
drop _merge
gen lag_proportion_obs=l1.proportion_observed
pause
/* targeted observer coverage rates */
merge m:1 fishing_year using `observer_all', keep(1 3)
drop _merge

pause
keep if stockcode<=17
/*
gen allocated=1
replace allocated=0 if stock=="SNE/MA Winter Flounder" & fishing_year<=2012
bysort fishing_year: egen Nalloc=total(allocated)


sort fishing_year allocated utilization

bysort fishing_year allocated (utilization): gen utilization_rank=_n
*/
gen utilization= (sector_livemt_catch/ sector_livemt_acl)


/**************************************************************/
/* construct dummies for the highest utilization in each area */
/**************************************************************/
gen stockarea2=stockarea
replace stockarea2="GB" if inlist(stockarea,"GBE","GBW")

/* highest GOM is either the GOM or CC/GOM */
/* highest GB is GBE, GBW,or GB, or CC/GOM */
/* highest SNEMA is highest SNEMA or CCGOM*/
/* highest unit is highest unit */
/* 521 will always be a problem: It is part of CCGOM for Yellowtail, GB from Cod, Haddock, and SNEMA for Winter */
/* There's nothing I can really do here about it -- I either group CC/GOM in with each OR I leave it by itself.*/

sort stockarea2 fishing_year utilization
/*pick the top stock and top 2 stocks by utilization in each stock area */
bysort stockarea2 fishing_year (utilization): gen maxU1=_n==_N
bysort stockarea2 fishing_year (utilization): gen maxU2=_n>=_N-1





gen util50=utilization>=.50
gen util75=utilization>=.75
gen util90=utilization>=.90

tsset
foreach var of varlist utilization util50 util75 util90 maxU1 maxU2 {
gen lag_`var'=l.`var'
}
tsset
gen acl_change=((sector_livemt_acl-l1.sector_livemt_acl)/l1.sector_livemt_acl)

gen acl_up=acl_change>=0


notes acl_change: fractional year-on-year change in ACL.
notes utilization: ACL utilization rate
notes acl_up: ACL increased


tempfile biod
save `biod'

use `cOLS_coefficients', clear
drop if stockcode==.
merge 1:1 fishing_year stockcode using `biod'


assert stockcode>=98 | fishing_year==2009 if _merge==2
drop if _merge==2
assert _merge==3
drop _merge
tsset stockcode fishing_year

merge 1:1 fishing_year stockcode using `price_clean', keep(1 3)
assert _merge==3
drop _merge
pause
cap drop stock_id stock nespp3 stockarea
merge m:1 stockcode using ${data_main}/stock_codes_${vintage_string}.dta, keep(1 3)
assert _merge==3
drop _merge
/*Prices (b's) are non-negative by construction. 0 is on the boundary of the parameter space, which is slightly difficult for testing purposes.

	But, I'm going to ignore this and state 
	H0: b=0
	HA: b>0
	One tail test. If I want the tail to have 
	
	5%, I need to use z=1.645
	2.5%	z=1.96
	1% 2.33
	.5% 2.58
	

	need to think about this. There are stocks with price at or near 0. There are other stocks that have so few trades that we can't actually estimate anything (like with a price =1 )
	*/
gen z=b/se	
gen badj=b
replace badj=0 if z<=1.645
replace badj=0 if se==0
replace badj=0 if badj==.
replace badj=. if inlist(stockcode,17) & fishing_year<=2012

replace badj=b if stockname=="witch_flounder" & fishing_year==2013

/* construct inshore, offshore, unit stock variables */
gen distance=0
replace distance=2 if strmatch(stockname,"GB*")
replace distance=1 if strmatch(stockname,"*GOM*") | strmatch(stockname,"SNEMA*") 

/* construct a species variable */
gen species=stockname
replace species=subinstr(species,"GOM_","",1)
replace species=subinstr(species,"SNEMA_","",1)
replace species=subinstr(species,"GBE_","",1)
replace species=subinstr(species,"GBW_","",1)
replace species=subinstr(species,"GB_","",1)


/* construct qp_ratio */
gen qp_ratio=badj/live_priceGDP

save `out_dataset', replace

