/* Code to estimate yearly non-linear hedonic models for ACE Prices.

this code is pretty janky. Even though the base specification is the same for all years, each year is different and I have to look at all the years individually.*/
/* I'm going to use 5% one tailed that happens to be P=0.10 as my criteria for a cutoff to test down */

/************************************/
/************************************/
/* You have to hand edit the file NLS_by_year.tex 
to remove the extra lines corresponding to the "equation name" from NLS.
*/
/************************************/
/************************************/
#delimit cr
version 15.1
pause off
mat drop _all
est drop _all
local logfile "${my_results}/nls_least_squares_quarterlyA.smcl" 
cap log close 
log using `logfile', replace

*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_intermediate}/cleaned_quota.dta" 



/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 

local NLS_out ${my_tables}/NLS_by_year.tex
local estout_relabel "b_SNEMA_winter:_cons SNEMA_winter b_CCGOM_yellowtail:_cons CCGOM_Yellowtail b_GBE_cod:_cons GBE_Cod b_GBW_cod:_cons GBW_Cod b_GBE_haddock:_cons GBE_Haddock b_GBW_haddock:_cons GBW_Haddock b_GB_winter:_cons GB_Winter b_GB_yellowtail:_cons GB_Yellowtail b_GOM_cod:_cons GOM_Cod b_GOM_haddock:_cons GOM_Haddock b_GOM_winter:_cons GOM_Winter b_plaice:_cons Plaice b_pollock:_cons Pollock b_redfish:_cons Redfish b_SNEMA_yellowtail:_cons SNEMA_Yellowtail b_white_hake:_cons White_hake b_witch_flounder:_cons Witch b_q1:_cons Q1 b_q2:_cons Q2 b_q3:_cons Q3 b_q4:_cons Q4 b_interaction:_cons interaction b_cons:_cons Constant"
local estout_opts "replace style(tex) starlevels(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(2))) stats(r2 rmse aic bic) varlabels(`estout_relabel') mlabels(2010 2011 2012 2013 2014 2015 2016 2017 2018 2019)  substitute(_ \_) "

local out_coefficients "${my_results}/nls_least_squares_quarterly_`flavor'${vintage_string}.dta" 

use `in_price_data', clear
do "${analysis_code}/small/final_dataclean.do"








/* Positive trades by fy */
preserve

foreach var of varlist CCGOM_yellowtail-SNEMA_winter{
replace `var'=`var'>1
rename `var' trades_`var'
}
collapse (sum) trades* , by(fy q_fy)
reshape long trades_ ,i(fy q_fy) j(stockname) string
rename trades_ trades_Q
reshape wide trades, i(fy stockname) j(q_fy)
tempfile trades
save `trades'

restore




/* set up tempfiles to store statsby results */
tempfile s2010 s2011 s2012 s2013 s2014 s2015 s2016 s2017 s2018 s2019


/* OLS and NLS models with ALL coefficients */


/* Pooled regression */
local rhs CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish  SNEMA_yellowtail  white_hake witch_flounder SNEMA_winter

/* OLS where there is a quarterly per-pound discount (cents) that changes every quarter  */
	  /* this isn't good because it forces the stocks with near zero values to get discounted */

qui forvalues yr =2010(1)2019{
	di "estimating unconstrained OLS for year `yr'"
	regress compensationR_`flavor' `rhs' i1.lease_only_sector#c.total_lbs if fy==`yr'
	
	est store ols`yr'
	
	predict lev`yr' if e(sample), leverage

	nl (compensationR_`flavor' = {b: `rhs'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2  + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
	est store nls`yr'
 }
/****************************************************************/
/****************************************************************/
/**********************2010 *************************************/
/****************************************************************/
/****************************************************************/

local yr 2010


year_initialize `yr'
local rhs2 `rhs'

local zero GBE_haddock GBW_haddock  SNEMA_winter 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


/* there are 2 coefs that are statistically 0 and SNEMA_winter is not allocated
GBE_haddock, GBW_haddock,  
Redfish stays in! */


regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 

/* whole value discounted */
nl (compensationR_`flavor' = {b: `rhs2'}*(1 + {b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

nl (compensationR_`flavor' = {b: `rhs2'}*(1  + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
estimates title: Model A
est store refined_nl`yr'
est save $compare2010, replace

statsby _b _se, by(markin) saving(`s2010', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

/* the Q3 and Q4 coeffs individually are not significant, but jointly are. I don't know what to make of that  but I will leave them in.*/


/****************************************************************/
/****************************************************************/
/**********************2011 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2011

year_initialize `yr'
local rhs2 `rhs'

local zero GBE_haddock GBW_haddock  SNEMA_winter plaice
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

/* there are 4 coefs that are statistically 0
GBW_haddock  GOM_winter redfish plaice */

 

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

local zero redfish 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



nl (compensationR_`flavor' = {b: `rhs2'}*(1+ {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

estimates title: Model A
est store refined_nl`yr'
est save $compare2011, replace

  
  statsby _b _se, by(markin) saving(`s2011', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

/****************************************************************/
/****************************************************************/
/**********************2012 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2012

year_initialize `yr'
local rhs2 `rhs'

local zero GBE_haddock GBW_haddock  SNEMA_winter 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

/* there are 3 coefs that are statistically 0
GBE_haddock GBW_haddock  SNEMA_winter  */

  
  
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

/* Now redfish is zero  */

local zero redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'



nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


/* we're also getting pollock as a zero prices, we'll set this to zero too */

local zero pollock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

estimates title: Model A
est store refined_nl`yr'
est save $compare2012, replace
   
  statsby _b _se, by(markin) saving(`s2012', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q4}*qtr4) + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

  
  
/****************************************************************/
/****************************************************************/
/**********************2013 *************************************/
/****************************************************************/
/****************************************************************/

local yr 2013

year_initialize `yr'
local rhs2 `rhs'


local zero GBE_haddock  
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)




local zero redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)






local zero GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



estimates title: Model A
est store refined_nl`yr'
est save $compare2013, replace

statsby _b _se, by(markin) saving(`s2013', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


  /* 2013,  I'm getting a small negative price for GOM winter -- actual -$0.40, I'm going to just constrain it to zero. 
  While there are 30ish trades with GOM winter in it, most  have many many things going on. I think it's just those trades had bad bargaining.
  
*/

/****************************************************************/
/****************************************************************/
/**********************2014 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2014

year_initialize `yr'
local rhs2 `rhs'

  
  
local zero GBE_haddock GBW_haddock  GB_yellowtail  redfish 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



local zero GOM_winter 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



local zero SNEMA_winter 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)




/* 2014 doesn't show any flattening */

nl (compensationR_`flavor' = {b: `rhs2'} + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

  /* and once I remove the flattening, pollock doesn't matter either */
  
  
  
local zero pollock 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'
nl (compensationR_`flavor' = {b: `rhs2'} + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


estimates title: Model A
est store refined_nl`yr'
est save $compare2014, replace

statsby _b _se, by(markin) saving(`s2014', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'} + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


/****************************************************************/
/****************************************************************/
/**********************2015 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2015

year_initialize `yr'
local rhs2 `rhs'



  
  
local zero GBE_haddock GBW_haddock GOM_winter white_hake
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)hasconstant(b_cons)



local zero GB_yellowtail
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'
regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)hasconstant(b_cons)



local zero GB_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)hasconstant(b_cons)


estimates title: Model A
est store refined_nl`yr'
est save $compare2015, replace

statsby _b _se, by(markin) saving(`s2015', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)hasconstant(b_cons)

/****************************************************************/
/****************************************************************/
/**********************2016 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2016

year_initialize `yr'
local rhs2 `rhs'

  
  
local zero GBE_haddock GBW_haddock GOM_winter pollock 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
/* we're also getting pollock as a zero prices, we'll set this to zero too */
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)




local zero GB_winter GB_yellowtail
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

estimates title: Model A
est store refined_nl`yr'
est save $compare2016, replace

statsby _b _se, by(markin) saving(`s2016', replace)  : nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


 
/****************************************************************/
/****************************************************************/
/**********************2017 *************************************/
/****************************************************************/
/****************************************************************/

local yr 2017

year_initialize `yr'
local rhs2 `rhs'
  
local zero  GOM_winter pollock GBE_haddock GBW_haddock 
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+ {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



estimates title: Model A
est store refined_nl`yr'
est save $compare2017, replace

statsby _b _se, by(markin) saving(`s2017', replace)  :nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+ {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

  

/****************************************************************/
/****************************************************************/
/**********************2018 *************************************/
/****************************************************************/
/****************************************************************/
local yr 2018

year_initialize `yr'
local rhs2 `rhs'


  
local zero GB_yellowtail GOM_haddock SNEMA_yellowtail
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


  
local zero GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


local zero redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

  

local zero GBE_haddock GBW_haddock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


estimates title: Model A
est store refined_nl`yr'
est save $compare2018, replace

statsby _b _se, by(markin) saving(`s2018', replace) :nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)

/****************************************************************/
/****************************************************************/
/**********************2019 *************************************/
/****************************************************************/
/****************************************************************/

local yr 2019

year_initialize `yr'
local rhs2 `rhs'


  
local zero GBE_haddock GBW_haddock GOM_haddock SNEMA_yellowtail
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


   
local zero GB_yellowtail redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


local zero pollock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)




local zero GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3 ) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


estimates title: Model A
est store refined_nl`yr'
est save $compare2019, replace

statsby _b _se, by(markin) saving(`s2019', replace) :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q3}*qtr3 ) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)hasconstant(b_cons)



/****************************************************************/
/****************************************************************/
/*Stack together code */

estout refined_nl* using `NLS_out', `estout_opts' 


clear
local yr 2010
use `s`yr''
gen fishing_year=`yr'

forvalues yr =2011(1)2019{
append using `s`yr''
replace fishing_year=`yr' if fishing_year==.
}


reshape long b_ , i(fishing_year) j(stockname) string

cap drop markin
rename fishing_year fy


gen type="coef" if strmatch(stockname,"*b_cons")
replace type="se" if strmatch(stockname,"*se_cons")

replace stockname=subinstr(stockname,"_b_cons","",.) 
replace stockname=subinstr(stockname,"_se_cons","",.) 


/* save these coeffs somewhere */


reshape wide b, i(fy stockname) j(type) string
merge m:1 fy stockname using `trades'
cap drop _merge


gen stockcode=.
replace stockcode=1 if strmatch(stockname,"CCGOM_yellowtail")
replace stockcode=2 if strmatch(stockname,"GBE_cod")
replace stockcode=3 if strmatch(stockname,"GBW_cod")
replace stockcode=4 if strmatch(stockname,"GBE_haddock")
replace stockcode=5 if strmatch(stockname,"GBW_haddock")
replace stockcode=6 if strmatch(stockname,"GB_winter")
replace stockcode=7 if strmatch(stockname,"GB_yellowtail")
replace stockcode=8 if strmatch(stockname,"GOM_cod")
replace stockcode=9 if strmatch(stockname,"GOM_haddock")
replace stockcode=10 if strmatch(stockname,"GOM_winter")
replace stockcode=11 if strmatch(stockname,"plaice")
replace stockcode=12 if strmatch(stockname,"pollock")

replace stockcode=13 if strmatch(stockname,"redfish")
replace stockcode=14 if strmatch(stockname,"SNEMA_yellowtail")
replace stockcode=15 if strmatch(stockname,"white_hake")
replace stockcode=16 if strmatch(stockname,"witch_flounder")
replace stockcode=17 if strmatch(stockname,"SNEMA_winter")

merge m:1 stockcode using ${data_main}/stock_codes_${vintage_string}.dta, keep(1 3)
drop _merge

rename fy fishing_year
rename b_se se
rename b_coef b
save `out_coefficients', replace
log close

*/

/*
https://www.stata.com/support/faqs/statistics/one-sided-tests-for-coefficients/
 In the special case where you are interested in testing whether a coefficient is greater than, less than, or equal to zero, you can calculate the p-values directly from the regression output. When the estimated coefficient is positive, as for weight, you can do so as follows:
H0: βweight = 0 	p-value = 0.008 (given in regression output)
H0: βweight <= 0 	p-value = 0.008/2 = 0.004
H0: βweight >= 0 	p-value = 1 − (0.008/2) = 0.996

When the estimated coefficient is negative, as for mpg, the same code can be used: 

*/
