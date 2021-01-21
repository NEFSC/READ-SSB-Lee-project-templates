/*construct a keyfile for stock codes.
*/


version 15.1
#delimit cr
pause on
local quota_data ${data_main}/monthly_quota_available_${vintage_string}.dta

local savename ${data_main}/stock_codes_${vintage_string}.dta


use `quota_data', replace
replace stock="GOM Cod" if strmatch(stock,"GOM cod")
keep stock_id stockcode stock
duplicates drop
compress
notes stock_id: stock_id comes from DMIS
notes stock: this is just decoding the stockcode variable



recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(nespp3)
gen stockarea="Unit"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)

notes stockarea: this is the name of the stock area. The stock areas are not necessarily the same across species
compress
sort stockcode stock
bysort stockcode (stock): keep if _n==_N
bysort stockcode: assert _N==1
save `savename', replace
