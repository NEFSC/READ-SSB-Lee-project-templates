/* make a small dataset of stockareas */

local outfile ${data_main}/stock_area_definitions_${vintage_string}.dta


clear
input str20(code species stockarea stockcode)
z1 	 "Yellowtail Flounder" 	 CCGOM	 YELCCGM
z2 	 Cod 	 GB-East	 CODGBE
z3 	 Cod 	 GB-West 	 CODGBW
z4 	 Haddock 	 GB-East 	 HADGBE
z5 	 Haddock 	 GB-West 	 HADGBW
z6 	 "Winter Flounder" 	 GB 	 FLWGB
z7 	 Yellowtail 	 GB 	 YELGB
z8 	 Cod 	 GOM 	 CODGMSS
z9 	 Haddock 	 GOM 	 HADGM
z10 	 "Winter Flounder" 	 GOM 	 FLWGMSS
z11 	 Plaice 	 Unit 	 PLAGMMA
z12 	 Pollock 	 Unit 	 POKGMASS
z13 	 Redfish 	 Unit 	 REDGMGBSS
z14 	 "Yellowtail Flounder" 	 SNEMA 	 YELSNE
z15 	 "White Hake" 	 Unit 	 HKWGMMA
z16 	 "Witch Flounder" 	 Unit 	 WITGMMA
z17 	 "Winter Flounder" 	 SNEMA 	 FLWSNEMA
end
compress

/* all the 600+ stat areas are grouped together in to SNE, so I'm just going to shorthand them as one */

/* there are 19 stat areas, plus the combined 600*/
expand 20
sort code
local statareas 511/515 521 522 525 526 533 534 537/539 541/543 561 562 600
egen statarea=fill( `statareas' `statareas')

gen stockmarker=0
replace stockmarker=1 if stockcode=="YELCCGM" & inlist(statarea, 511,512,513,514,515,521)
replace stockmarker=1 if stockcode=="CODGBE" & inlist(statarea, 561,562)
replace stockmarker=1 if stockcode=="HADGBE" & inlist(statarea, 561,562)
replace stockmarker=1 if stockcode=="CODGBW" & inlist(statarea, 522,525,542,543,521,526,541,542,537,538,533,534,539, 541,600)
replace stockmarker=1 if stockcode=="HADGBW" & inlist(statarea, 522,525,542,543,521,526,541,542,537,538,533,534,539, 541,600)
replace stockmarker=1 if stockcode=="FLWGB" & inlist(statarea, 522,525,561,562,542,543)
replace stockmarker=1 if stockcode=="CODGMSS" & inlist(statarea, 511,512,513,514,515)
replace stockmarker=1 if stockcode=="HADGM" & inlist(statarea, 511,512,513,514,515)
replace stockmarker=1 if stockcode=="FLWGMSS" & inlist(statarea, 511,512,513,514,515)


replace stockmarker=1 if stockcode=="YELSNE" & inlist(statarea, 521,526,541,542,537,538,533,534,541,600)
replace stockmarker=1 if stockcode=="FLWSNEMA" & inlist(statarea, 521,526,541,542,537,538,533,534,541,600)
replace stockmarker=1 if stockcode=="YELGB" & inlist(statarea, 522,525,551,552,561,562)

/*
https://www.nefsc.noaa.gov/saw/sasi/uploads/2017_YEL_GB_FIG_all_figures.pdf*/

replace stockmarker=1 if stockarea=="Unit"

save `outfile', replace
