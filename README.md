# Project Template

A small repository that will get you set up an organized project and get data off the NEFSC oracle servers.  This repository contains:

1. Cloning from Github
1. A folder structure and some utilities that will (hopefully) help you keep things organized
1. Getting Data
    1. Sample code for extracting data from oracle using stata.
    1. Sample code for extracting data from oracle using R.
1. Sample code for using R to call stata.
1. Little bits of code from my ACE price project, in case it's useful.

Please help make this a valuable up-to-date resource.  To add your knowledge:
1.   [Fork](https://docs.github.com/en/github/getting-started-with-github/fork-a-repo) - It's in the top right of github.
1.   Make your changes  - click the file you want to edit and then the little pencil on the right side.  ![Here's a picture](/images/fork_edit.jpg)
1.   [Pull Request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork) so the changes get into the document.



# Prelude
Look on my code, ye Mighty, and despair!

# Cloning from Github and other setup
Min-Yang is using Rstudio to write .Rmd or .md documentation. He is also using Rstudio's git version control to commit/push/pull from github. It works reasonably well.  You will also need to install git.  You might need to create a personal access token and save it using gitcreds: gitcreds_set()

The easist thing to do is to clone this repository to a place on your computer. [Here's a starting guide](https://cfss.uchicago.edu/setup/git-with-rstudio/).  Don't put spaces in the name.  Cloning the repository will set up many, but not all of the folders.

Min-Yang put the project into:
```
C:/Users/Min-Yang.Lee/Documents/project_templates
```
Pay attention to where you put this, you will need it later.

# Overview and Folder structure

This is mostly borrowed from the world bank's EDB. https://dimewiki.worldbank.org/wiki/Stata_Coding_Practices
Please use forward slashes (that is C:/path/to/your/folder) instead of backslashes for unix/mac compatability. I'm forgetful about this. 

I keep each project in a separate folder.  A stata do file containing folder names get stored as a macro in stata's startup profile.do.  This lets me start working on any of my projects by opening stata and typing: 
```
do $my_project_name
```
Rstudio users using projects don't have to do anything for paths.


Here's more: [project_logistics.md](https://github.com/minyanglee/READ-SSB-Lee-project-templates/blob/main/documentation/project_logistics.md) 

# Getting Data
Oracle usernames, passwords, server addresses, and other credentials cannot be stored on github.  Therefore, our general approach will be to
1. Put your username, password, and other into a small piece of code
2. Run that code before you need to extract data (perhaps every time you start Stata or R).
3. That's it.

This approach keeps account names, passwords, and other things separate. It also increases reproducability - other users just need to have their own piece of code that contains their credentials.

## ODBC Setup
You'll have to get someone from ITD to setup your ODBC connections. It should looks something like this.

![ODBC driver pic](https://github.com/NEFSC/READ-SSB-Lee-project-templates/blob/main/images/odbc_drivers.png) 

![ODBC DSN pic](https://github.com/NEFSC/READ-SSB-Lee-project-templates/blob/main/images/odbc_dsn.png) 




## Getting Data with Stata and  ODBC
1.  Open up /stata_code/sample/odbc_connection_macro_sample.do. 
1.  Delete or Comment out the Operating system section that is irrelevant to you.  Enter your own information (oracle username and password).  
1.  Rename and save it in a place you can find it. Min-Yang put it into 
```
C:/Users/Min-Yang.Lee/Documents/common/odbc_setup_macros.do
```
You can certainly put it into the repository, but if you do that, make sure to add it to the .gitignore so it is never uploaded to github. Regardless of where you put it, remember where it is, you will need it later.


### Set up your profile.do

1. Open up /stata_code/sample/sample_profile.do.
1. Enter and modify with your own information (username,directories).  You will want the project_template global macro to point to the "project_logistics/folder_setup_globals.do" that is in your project directory (for me this is C:/Users/Min-Yang.Lee/Documents/project_templates\stata_code/project_logistics/folder_setup_globals.do
1. Save it as "C:\ado\profile.do".  [Here is the stata manual](https://www.stata.com/manuals15/gsub.pdf) about this.


### Set up the rest of the project. 
1. Open up "project_logistics/run_this_once-folder_setup.do"
1.  Add an "if" statement analogous to lines 15-18.  Put this below minyang's if statement.  Change the directory to match the one you used when you initially cloned this repository.
1. Open up "project_logistics/folder_setup_globals.do"
1.  Add an "if" statement analogous to lines 14-18. Put this below minyang's if statement.  Change the directory to match the one you used when you initially cloned this repository.  Change the quietly do line to run the bit of code that sets up your odbc connections.
1. start stata. Type
```
do $project_template 
do "/${my_codedir}/project_logistics/run_this_once_folder_setup.do" /*this line only needs to be run once*/
```


You can also set up folders in R by using the file 

"R_code/project_logistics/R_paths_libraries_setup.R"



### Sample code for extracting data from oracle using stata

do "/${extraction_code}/extract_from_sole.do"

should extract a table from sole. 



## Getting Data with R and RODBC
Code to extract data from oracle using R is here:

```
/R_code/data_extraction_processing/extraction/rodbc_extraction.R
```
To extract data: 

1. Rename /R_code/project_logistics/R_code/R_credentials_sample.R to R_credentials.R.
1. Fill in your id and password
1. Change the first line of  /R_code/project_logistics/R_code/R_paths_libraries_setup.R to point to your project directory. Source .
1. Make the same change to /R_code/data_extraction_processing/extraction/rodbc_extraction.R. Source.



# Sample code for using R to call stata.

This is in Rmd_stata_integration.Rmd. You should need to change only two lines of code:

1.  Line 12 of the Rmd_stata_integration.Rmd should be changed to the directory where you cloned this repository locally.
1.  Line 14 of stata_code/analysis/test1.do should also be changed to the same directory.
1.  Line 14 of stata_code/analysis/wrapper32.do should be changed to the same directory.

Sorry, I'm not slick enough to pass a little arguement through to a stata do file.



### Other Sample code for  stata
I've included some other code to get data into stata, including getting data from St. Louis Federal Reserve.  I've also left some bits of code that assemble and process data.

Also, take a look here: https://github.com/cameronspeir/NOAA-Foreign-Fishery-Trade-Data-API to get data from the NOAA Foreign fishery trade .



# Problems  

1. A little janky on setting up directories, that's life.


# NOAA Requirements
“This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.”


1. who worked on this project:  Min-Yang
1. when this project was created: Jan, 2021 
1. what the project does: Helps people get organized.  Shows how to get data from NEFSC oracle 
1. why the project is useful:  Helps people get organized.  Shows how to get data from NEFSC oracle 
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](https://github.com/minyanglee/READ-SSB-Lee-project-templates/blob/main/license.md)
