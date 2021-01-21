# This decsribes how /what to run.
rm(list=ls())
#### Set things up
my_projdir<-"C:/Users/Min-Yang.Lee/Documents/project_templates/"

#this reads in paths and libraries
# Be careful, there's are a few masked objects (packages with commands with the same name)

source(file.path(my_projdir,"project_logistics","R_paths_libraries.R"))


dofile<-"test1.do"
#dofile<-"test2.do"

full.path.dofile<-file.path(stata_codedir,analysis,dofile)
cmd<-paste0('"',stataexe, '" /e do "',full.path.dofile,'"')



#  stata needs to save a log file, it will do so in the "active directory"
getwd()

system(cmd, wait=TRUE)
