/* depends on estout */

/* pass in project, image, table folder macros */

version 15.1
#delimit cr

pause off
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
global today_date_string = subinstr(trim("`date'"), " " , "_", .)

global vintage_string $today_date_string 

global my_projdir "C:/Users/Min-Yang.Lee/Documents/READ-SSB-MLee-project_templates"
global stata_codedir "${my_projdir}/stata_code"
global my_images "${my_projdir}/images"
global my_tables "${my_projdir}/tables"

global regression_table ${my_tables}/regression_tableB.tex

do "${stata_codedir}/analysis/test3.do"

do "${stata_codedir}/analysis/test2.do"
