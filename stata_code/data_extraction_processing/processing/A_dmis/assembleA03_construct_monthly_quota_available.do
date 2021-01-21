version 15.1
#delimit cr

local acl_data ${data_external}/annual_acls_${vintage_string}.dta

local acl_data  $data_external/annual_catch_and_acl_$vintage_string.dta

local usage_data ${data_external}/dmis_monthly_quota_usage_${vintage_string}.dta

use `acl_data', replace
cap drop sector_livemt_catch
gen sector_live_pounds=sector_livemt*2204.62

keep fishing_year stockcode stock sector_live_pounds
tempfile quota_pounds
save `quota_pounds', replace


use `usage_data'
drop if fishing_year<=2009
replace stockcode=103 if strmatch(stock_id,"FLGMGBSS")
qui summ fishing_year
local maxyr=`r(max)'
/* mismatches 
1. DMIS is updated through May/June 2019 -- but I only have 
starting quota quota data through 2018. 
2. GBE and GBW cod and haddock are unresolved
	right now, I'm coding quotas as GBE
	usage is coded as GBE and GBW.
*/


merge m:1 stockcode fishing_year using `quota_pounds'
drop if fishing_year>`maxyr'
assert inlist(stockcode,98,99)| fishing_year==2009 if _merge==2
assert inlist(stockcode,98,99)==0 if _merge==3


drop if _merge==2
drop _merge
sort stockcode fishing_year month_of_fy
egen id=group(stockcode fishing_year)

xtset id month
gen quota_remaining_eom=sector_live_pounds-cumulative
gen quota_remaining_bom=l1.quota_remaining_eom
replace quota_remaining_bom=sector_live_pounds if month_of_fy==1 & quota_remaining_bom==.
gen fraction_remaining_eom=quota_remaining_eom/sector_live_pounds
gen fraction_remaining_bom=quota_remaining_bom/sector_live_pounds
drop id sector_live_pounds
save  ${data_main}/monthly_quota_available_$vintage_string.dta, replace
