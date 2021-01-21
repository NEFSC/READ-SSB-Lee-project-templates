#delimit;

clear;
odbc load,  exec("select * from cfspp;") $mysole_conn;
save $data_internal/cfspp_test_$vintage_string.dta, replace;



