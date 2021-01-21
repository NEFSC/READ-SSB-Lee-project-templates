/* this is a wrapper to do all my data-importing . This code is data downloading and minimal processing. 
Some of this code may take a long time. Other parts may require VPN.*/
/* read in quarterly and yearly coefficients from Chad's hedonic model. Clean up a little bit */
version 15.1
#delimit cr
pause off
/*extract and process ACE price data
This is done in R 
run the aceprice_project_wrapper.R) 
*/



/*extract psc data */
do "${extraction_code}/extractA02_psc_extractor.do"

/*Assemble Annual ACLs */
do "${extraction_code}/extractA03S_acl_import.do"


/*extract diesel price data */
do "${extraction_code}/extractA04_diesel_no2_FRED.do"
do "${extraction_code}/extractA05_external_data_FRED.do"





/****DMIS****************************************/
/*extract catch and discard data 
Takes a long while
Requires VPN*/
do "${extraction_code}/extractB01_dmis_catch_and_discards.do"


/****process DMIS to get monthly quota usage and prices*/
do "${processing_code}/A_dmis/assembleA01_construct_quota_usage.do"
do "${processing_code}/A_dmis/assembleA02_construct_dmis_prices.do"
do "${processing_code}/A_dmis/assembleA03_construct_monthly_quota_available.do"



/* stockarea mapping 
make a dataset containing the stocks and their corresponding areas*/
do "${processing_code}/C_stockbasics/assembleC01_stockarea_mapping.do"

/*make a dataset that uses an definition to determine requires stocks. */
do "${processing_code}/C_stockbasics/assembleC02_construct_required_stocks.do"

/*make a keyfile dataset for stock codes */
do "${processing_code}/C_stockbasics/assembleC03_stock_codes.do"

/* these might depend on stock codes */
do "${extraction_code}/extractA06_observer_coverage.do"
do "${extraction_code}/extractA07_observer_coverage_by_stock"

