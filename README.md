# msk_SAS_macros
SAS macros for MSK project use

# To load all MSK SAS macros
FILENAME mskmacros URL "https://github.com/slobaugh/create_msk_SAS_project/blob/main/utility.sas";
%INCLUDE mskmacros;

# To load a specific MSK SAS macro
%LET mymacro = table1
FILENAME macroname URL "http://raw.githubusercontent.com/slobaugh/&mymacro..sas/main/&mymacro..sas";
%INCLUDE macroname;
