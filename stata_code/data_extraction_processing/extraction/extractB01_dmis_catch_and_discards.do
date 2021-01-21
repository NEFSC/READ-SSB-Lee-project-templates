#delimit;

/* Send this to character
leave out sector_id==2
select trip_id, stock_id, discard from APSD.T_SSB_DISCARD@garfo_nefsc where DISCARD>0

And then join this to the live landings in APSD.T_SSB_CATCH.  




*/
clear;
odbc load,  exec("select trip_id, stock_id, sum(discard) as discard from APSD.T_SSB_DISCARD@garfo_nefsc where DISCARD>0 group by trip_id, stock_id;") $mysole_conn;
bysort trip_id stock_id: assert _N==1;
save $data_external/dmis_discards_$vintage_string.dta, replace;


clear;
odbc load,  exec("select T.trip_id, t.trip_date, t.mult_year, t.permit, t.mult_mri, c.STOCK_ID, sum(c.landed) as landed , sum(c.pounds) as pounds, sum(nvl(DLR_LIVE,0)) as dlr_live, 
	sum(nvl(DLR_LANDED,0)) as dlr_landed, sum(nvl(DLR_DOLLAR,0)) as dlr_dollar, sum(nvl(DOLLAR_SSB,0)) as dollar_ssb from APSD.t_ssb_trip@garfo_nefsc T, APSD.t_ssb_catch@garfo_nefsc C
where C.trip_id=T.trip_id
and C.fishery_group in ('GROUND', 'OTHER2')
and T.groundfish_permit is not null
and T.sector_id <> 2
and C.secgearfish <> 'CAR'
group by t.trip_id, t.trip_date, t.mult_year, t.permit, t.mult_mri, c.stock_id;") $mysole_conn;
drop if stock_id=="OTHER";
renvars, lower;
save $data_external/dmis_trip_catch_universe_$vintage_string.dta, replace;

#delimit ;
preserve;
keep trip_id;
duplicates drop;
tempfile trips;
save `trips',replace;

restore;
keep stock_id;
duplicates drop;
cross using `trips';

order trip stock;
sort trip stock;

merge 1:1 trip_id stock_id using  $data_external/dmis_trip_catch_universe_$vintage_string.dta;
assert _merge~=2;
cap drop _merge;
/* fill down characteristics*/
sort trip_id trip_date;
bysort trip_id (trip_date): replace trip_date=trip_date[1] if trip_date==.;
bysort trip_id (mult_year): replace mult_year=mult_year[1] if mult_year==.;

bysort trip_id (permit): replace permit=permit[1] if permit==.;
bysort trip_id (mult_mri): replace mult_mri=mult_mri[1] if mult_mri==.;

merge 1:1 trip_id stock_id using $data_external/dmis_discards_$vintage_string.dta, keep(1 3);
drop _merge;
/* right here */
gen dropme=0;
replace dropme=1 if landed==. &pounds==. & dlr_live==. & dlr_landed==. & dlr_dollar==. & discard==.;
drop if dropme==1;
foreach var of varlist landed pounds dlr_live dlr_landed dlr_dollar dollar_ssb discard{;

replace `var'=0 if `var'==.;
};


gen stockcode=.;


replace stockcode=1 if strmatch(stock_id,"YELCCGM");
replace stockcode=2 if strmatch(stock_id,"CODGBE");
replace stockcode=3 if strmatch(stock_id,"CODGBW");
replace stockcode=4 if strmatch(stock_id,"HADGBE");
replace stockcode=5 if strmatch(stock_id,"HADGBW");
replace stockcode=6 if strmatch(stock_id,"FLWGB");
replace stockcode=7 if strmatch(stock_id,"YELGB");

replace stockcode=8 if strmatch(stock_id,"CODGMSS");
replace stockcode=9 if strmatch(stock_id,"HADGM");
replace stockcode=10 if strmatch(stock_id,"FLWGMSS");
replace stockcode=11 if strmatch(stock_id,"PLAGMMA");
replace stockcode=12 if strmatch(stock_id,"POKGMASS");
replace stockcode=13 if strmatch(stock_id,"REDGMGBSS");
replace stockcode=14 if strmatch(stock_id,"YELSNE");
replace stockcode=15 if strmatch(stock_id,"HKWGMMA");
replace stockcode=16 if strmatch(stock_id,"WITGMMA");
replace stockcode=17 if strmatch(stock_id,"FLWSNEMA");
/*I'm adding on stockcods for halibut, ocean pout, n windowpane, s windowpane and wolffish 
I'm starting them in the 100s.*/
replace stockcode=101 if strmatch(stock_id,"HALGMMA");
replace stockcode=102 if strmatch(stock_id,"OPTGMMA");
replace stockcode=103 if strmatch(stock_id,"FLGMGBSS");
replace stockcode=104 if strmatch(stock_id,"FLDSNEMA");
replace stockcode=105 if strmatch(stock_id,"WOLGMMA");
replace stockcode=999 if strmatch(stock_id,"OTHER");

save $data_external/dmis_trip_catch_discards_universe_$vintage_string.dta, replace;


