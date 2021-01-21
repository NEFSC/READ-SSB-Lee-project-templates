/* depends on estout */

/* pass in project, image, table folder macros */


sysuse auto

scatter price mpg
graph export "${my_images}/scatterplotB.png", replace as(png)
/* save this to a place */

regress price mpg rep78
est store regress1


regress price mpg rep78 weight
est store regress2



esttab regress2 regress1  using ${regression_table},  b se label nostar replace
