/*this is a do file to a few simple models that explain the price of ACE as a function of

output prices, ACLs, and utilization.

NOTE: Because the first stage regression is deflated by GDP implicit price deflator, our betas are also deflated by the implicit price deflator and should be thought of as 'real' prices.  
Any second stage must also use prices that are similarly normalized

Here is a brief characterization of the dataset and it's empirical challenges
1.  The panel is relatively small -- 167 (17 stocks and 10 fishing years .  SNEMA winter was not allocated until 2013).
2.  Prices are bounded below by zero.  Many observations are either zero or have very low prices:

	59 of those observations are zero
	71 have prices under 10 cents

	53 have prices over 50 cents
	20 have prices over $1.
	The largest price I see is $2.90

	Over the 10 years
	GBE and GBW haddock, and redfish have had quota prices of approximately 1 cent

3.  There's at least a few endogenous covariates. 
		A.  It's hard to make the case that annual quota prices, annual output prices, and annual utilization rates are not determined simultanously.  Therefore fish prices and quota utilziation are endogenous.
		B.  The targeted observer coverage level is probably exogenous, but the realized may not be.
		C.  The proportion of catch each stock that is observed is very likely endogenous to the price of quota.
		
4.  There's some persistence from year-to-year in ace prices. I'd argue that it's likely persistence in the RHS variables that determine prices, but we should check for uncorrelated residuals over time as a specification test.



This means we need to account for a few things
IMHO #3 is the most important, everything is inconsistent without taking care of endogeneity.  It's somewhat reasonable to try a specification where we move output prices to the RHS. 

Problem 1 rules out the Arellano-Bond estimators that could be used to address 3 and 4. Arellano-bond style estimators requires large n and short t.  17 is not large.
Problem 1 also rules out the Wooldridge style (https://www.statalist.org/forums/forum/general-stata-discussion/general/1381373-ivpoisson-with-panel-data-fixed-effects) that would address 2 and 3.




We'll estimate a handful of models, none are perfect:
We get consistent results for all of them though.
	Same signs. Things sometimes become statistically insignificant.
	
1. OLS: don't handle the "zero" nature very well.
2. FE models:  probably not quite enough degrees of freedom to be very good at resolving any differences due to RHS vars.
3. RE models:  FE models indicate Linear RE isn't good.

4.  Tobit:  Fits the corner solution setup well.  But reading Wooldridge (2002) between the lines a litte suggests a Poisson QMLE (y=exp(XB)) setup is better.  
	If we stick with Tobit, we are interested in the predict xb (the linear prediction) and NOT predict ystar (expected Y, conditional on being positive).  But, this is a little janky because it produces negative predictions
	

5.  Poisson QMLE - is nice because it also fits the corner solution DGP.  It "fits" better than OLS as judged by the square of corr(y,\hat{exp(xb)}).



Might need to try both the overall coverage and stock-level coverage as RHS vars.


outreg2 , tex(frag) will let me add in extraneous stats

*/

cap log close

local logfile "NLS_explantory_regressions_${vintage_string}.smcl"
log using ${my_results}/`logfile', replace
global linear_table1 ${my_tables}/linear_table1.tex
global poisson_table1 ${my_tables}/poisson_table1.tex


local in_dataset "${my_results}/ols_tested_mergedGDP_${vintage_string}.dta" 
est drop _all
use `in_dataset', clear









/* for any FE models, we should mark-out any stocks that always have a price=0 */
/*I'm marking out all of the GBW haddock, it's always has a price=0. and GBE cod in 2012 as a major outlier */
gen markin=1
replace markin=0 if fishing_year==2012 & stockname=="GBE_cod"
*replace markin=0 if stockname=="GBW_haddock"
local ifconditional 
local ifconditional "if markin==1"


/*********************************************************************************************/
/*********************************************************************************************/
/* LINEAR models -- Really don't like these, except as a robustness check, intuition, and comparisons to better models .*/
/*********************************************************************************************/
/*********************************************************************************************/

/* lags as an IV for current values 
ivregress 2sls  badj acl_change ib8.stockcode (live_price utilization=lag_utilization lag_live_price) `ifconditional', vce(robust)
est store IV_base
predict b_iv, xb
*/

/*I fiddled around with doing a hausman withouth the vce(robust) option. If RE is efficient, then we can use it instead of FE. I don't know that believe it's efficiency give the likely heteroskedasticity (eyeballed); .*/ 
regress  badj acl_change lag_live_price lag_utilization `ifconditional', vce(robust)
estimates title: OLS
est store linear
predict bols, xb

/*(r2_o r2_w r2_b)*/
outreg2 using ${linear_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) adds( ll, e(ll), rmse, e(rmse) ) addtext(stock effects, No)


/* lags as a proxy for current values*/
xtreg  badj acl_change lag_live_price lag_utilization `ifconditional', fe vce(robust)
estimates title: Linear FE
est store linearFE
predict bFE, xbu

outreg2 using ${linear_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) replace adds(R2O, e(r2_o), R2W, e(r2_w), ll, e(ll), rmse, e(rmse) ) addtext(stock effects, FE)

/* Random Effects  as a proxy for current values*/
xtreg  badj acl_change lag_live_price lag_utilization `ifconditional', re vce(robust)
estimates title: Linear RE
est store linearRE
predict bRE, xbu
outreg2 using ${linear_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) adds(R2O, e(r2_o), R2W, e(r2_w), rmse, e(rmse) ) addtext(stock effects, RE)

/* hausman test for RE vs FE after robust SE*/
xtoverid 




/*********************************************************************************************/
/*********************************************************************************************/
/************ NON-LINEAR models --I like these a bit better **********************************/
/*********************************************************************************************/
/*********************************************************************************************/




/*********************************************************************************************/
/************************* POISSON ***********************************************************/
/*********************************************************************************************/


poisson badj acl_change lag_live_price lag_utilization `ifconditional', vce(cluster stockcode)
estimates title: Poisson Pooled
est store poisson_pooled
predict b_poisson, n


/* wooldridge suggests the correlation between the predictions and the data as the basis for r^2 */

qui corr b_poisson badj if e(sample)
mat correl=r(C)
local R2poi=correl[2,1]^2

di "Wooldridge R2 is" `R2poi'



qui estat ic
mat IC=r(S)
mat AIC=IC[1,5]
local AIC=AIC[1,1]
mat BIC=IC[1,6]
local BIC=BIC[1,1]

outreg2 using ${poisson_table1}, tex(frag) replace keep(acl_change lag_live_priceGDP lag_utilization) adds(R2W, `R2poi', ll, e(ll),AIC, `AIC', BIC, `BIC') addtext(FE, No)
/*********************************************************************************************/
/* a poisson with robust SE's is a GLM and useful for non-negative outcomes -- this is basically equivalent to xtpoisson, fe*/
/*********************************************************************************************/
poisson badj acl_change  lag_live_price lag_utilization ib8.stockcode `ifconditional', vce(robust)
estimates title: Poisson FE
est store poissonFE
predict b_poissonFE, n

/* wooldridge suggests the correlation between the predictions and the data as the basis for r^2 */
qui corr b_poissonFE badj if e(sample)
mat correl=r(C)
local R2poi=correl[2,1]^2

di "Wooldridge R2 is" `R2poi'

qui estat ic
mat IC=r(S)
mat AIC=IC[1,5]
local AIC=AIC[1,1]
mat BIC=IC[1,6]
local BIC=BIC[1,1]


outreg2 using ${poisson_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) adds(R2W, `R2poi', ll, e(ll), AIC, `AIC', BIC, `BIC') addtext(FE, Yes)

/*********************************************************************************************/
/*********** Same as above, but adding total target coverage level****************************/
/*********************************************************************************************/


poisson badj acl_change  lag_live_price lag_utilization ib8.stockcode totaltargetcoveragelevel `ifconditional', vce(robust)
estimates title: Poisson FE
est store poissonFE_target
predict b_poissonFE_target, n



/* wooldridge suggests the correlation between the predictions and the data as the basis for r^2 */

qui corr b_poissonFE_target badj if e(sample)
mat correl=r(C)
local R2poi=correl[2,1]^2

di "Wooldridge R2 is" `R2poi'


qui estat ic
mat IC=r(S)
mat AIC=IC[1,5]
local AIC=AIC[1,1]
mat BIC=IC[1,6]
local BIC=BIC[1,1]


outreg2 using ${poisson_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) adds(R2W, `R2poi', ll, e(ll), AIC, `AIC', BIC, `BIC') addtext(FE, Yes)
/*********************************************************************************************/
/* Test down the FEs to save some DOF*/
/*********************************************************************************************/

est restore poissonFE
est replay


test 2.stockcode
test 3.stockcode, accum
test 7.stockcode, accum
test 9.stockcode, accum
test 10.stockcode, accum
test 14.stockcode, accum
test 17.stockcode, accum
/* */
poisson badj acl_change  lag_live_price lag_utilization ibn.stockcode `ifconditional', vce(robust) noconstant
test 1.stockcode==3.stockcode 
test 1.stockcode=6.stockcode,accum
test 1.stockcode=7.stockcode, accum
test 1.stockcode==11.stockcode, accum
test 1.stockcode==16.stockcode, accum
test 1.stockcode==17.stockcode, accum

poisson badj acl_change  lag_live_price lag_utilization i(2 4 5 8 9 10 12 13 14 15).stockcode `ifconditional', vce(robust) 
/* 4, 5, and 13 are the same too */
gen sc2=stockcode
replace sc2=4 if inlist(sc2,5,13)
poisson badj acl_change  lag_live_price lag_utilization i(2 4 8 9 10 12 14 15).sc2 `ifconditional', vce(robust) 


gen sc3=sc2
replace sc3=8 if sc3==14
poisson badj acl_change  lag_live_price lag_utilization i(2 4 8 12 15).sc3 `ifconditional', vce(robust) 

/* 4, 5 and 13 are bundled together.  
8 and 14 are bundled together
1, 3, 6, 7, 11, 16, 17 are bundled together 
2, 12, 15 are different 
*/



poisson badj acl_change  lag_live_price lag_utilization i(1 4 5 6 11 12 13 15 16).stockcode `ifconditional', vce(robust) noconstant
estimates title: Poisson Half
est store poisson_half
predict b_poissonhalf, n


qui corr b_poisson badj if e(sample)
mat correl=r(C)
local R2poi=correl[2,1]^2

di "Wooldridge R2 is" `R2poi'

qui estat ic
mat IC=r(S)
mat AIC=IC[1,5]
local AIC=AIC[1,1]
mat BIC=IC[1,6]
local BIC=BIC[1,1]

outreg2 using ${poisson_table1}, tex(frag) keep(acl_change lag_live_priceGDP lag_utilization) adds(R2W, `R2poi', ll, e(ll), AIC, `AIC', BIC, `BIC') addtext(FE, Some)

/*
esttab poisson_pooled poissonFE  poisson_half using ${poisson_table1},  b se label r2 ar2 pr2 replace keep(acl_change lag_live_priceGDP lag_utilization _cons)
*/

/*IV poisson model with endogenous covariates
ivpoisson gmm badj acl_change ib8.stockcode (live_price utilization=lag_live_price lag_utilization) `ifconditional', vce(robust)
est store ivpoisson
predict b_ivp, n
*/

/* a Tobit is reasonable (ish)
tobit  badj acl_change ib8.stockcode live_price utilization `ifconditional', ll(0) vce(robust)
predict b_tobit, xb
est store tobit_base
*/

/* lags as a proxy for current values*/
tobit  badj acl_change  lag_live_price lag_utilization `ifconditional', ll(0)  vce(robust)
est store tobit
predict b_tobit, xb

tobit  badj acl_change  lag_live_price lag_utilization totaltargetcoveragelevel `ifconditional', ll(0)  vce(robust)
est store tobit_target
predict b_tobit_target, xb

tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode  `ifconditional', ll(0) vce(cluster stockcode)
est store tobitFE
predict b_tobitFE , xb



tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode totaltargetcoveragelevel `ifconditional', ll(0) vce(cluster stockcode)
est store tobitFE_target
predict b_tobitFE_target , xb

tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode totaltargetcoveragelevel c.DDFUEL_R#i0.distance `ifconditional', ll(0) vce(cluster stockcode)


/*
tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode CV `ifconditional', ll(0) vce(cluster stockcode)
tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode coveragerate `ifconditional', ll(0) vce(cluster stockcode)
tobit  badj acl_change lag_live_price lag_utilization ib8.stockcode realizedcoveragelevel `ifconditional', ll(0) vce(cluster stockcode)
*/
poisson badj acl_change  lag_live_price lag_utilization ib8.stockcode realizedcoveragelevel `ifconditional', vce(robust)
poisson badj acl_change  lag_live_price lag_utilization ib8.stockcode totaltargetcoveragelevel `ifconditional', vce(robust)



/* and IHS specification might work, if I can IHS everything */
log close
