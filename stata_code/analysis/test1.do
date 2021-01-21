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

local regression_table ${my_tables}/regression_table.tex

sysuse auto

scatter price mpg
graph export "${my_images}/scatterplot.png", replace as(png)
/* save this to a place */

regress price mpg rep78
est store regress1


regress price mpg rep78 weight
est store regress2



esttab regress1 regress2 using `regression_table',  b se label nostar replace
