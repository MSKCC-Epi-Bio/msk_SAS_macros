# msk_SAS_macros
SAS macros for MSK project use

## To load all MSK SAS macros and templates
FILENAME mskmacros URL "https://github.com/slobaugh/create_msk_SAS_project/blob/main/utility.sas";  
%INCLUDE mskmacros;  

## To load a specific MSK SAS macro or template
%LET mymacro = table1;  
%LET myversion = v1.0;  
FILENAME mv URL "http://raw.githubusercontent.com/slobaugh/msk_SAS_macros/&mymacro._&myversion./&mymacro..sas";  
%INCLUDE mv;  
