local infile ${data_main}/stock_area_definitions_${vintage_string}.dta
local outfile ${data_main}/required_stocks_${vintage_string}.dta
use `infile', clear

keep if stockmarker~=0

levelsof stockcode, local(stocks)

foreach l of local stocks{
	tempfile new5555
	local dsp1 `"`dsp1'"`new5555'" "'  
	preserve
	levelsof statarea if stockcode=="`l'", local(myloc) separate(",")
	keep if inlist(statarea, `myloc')
	keep stockcode
	duplicates drop
	rename stockcode required
	gen stockcode="`l'"
	quietly save `new5555', replace
	restore
}

clear

append using `dsp1'
order stockcode required
rename stockcode stock_id
notes: This will contain rows where stock_id==required. This may or may not be intended.
save  `outfile', replace
