# msk_SAS_macros
SAS macros for MSK project use

## To load all MSK SAS macros and templates  
Run the following code in SAS *(Note that the most recent version of each macro and template will be loaded)*:  
FILENAME mskm URL "https://raw.githubusercontent.com/MSKCC-Epi-Bio/create_msk_SAS_project/main/utility.sas";  
%INCLUDE mskm;  

## To load a specific MSK SAS macro or template  
Run the following code in SAS (*Note that you must specify the specific version that you want to load)*:  
%LET myfolder = Table1;  
%LET mymacro = table1;  
%LET myversion = v1.0;  
FILENAME mv URL "https://raw.githubusercontent.com/MSKCC-Epi-Bio/msk_SAS_macros/&myversion./&myfolder./&mymacro..sas";  
%INCLUDE mv;   
