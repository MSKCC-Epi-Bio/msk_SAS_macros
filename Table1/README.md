# Documentation: table1 SAS Macro
#### Macro Name: TABLE1 
#### Created Date/Author: October. 2021/Hannah Kalvin & Stephanie Lobaugh 
#### Last Update Date/Person: Oct 1, 2021/Hannah Kalvin & Stephanie Lobaugh 
#### Other Contributors: Debra Goldman (original author)
#### Current Version (reflected in tag on github): table1_v1.0
#### Working Environment: SAS 9.4 


## Contact 
Hannah Kalvin kalvinh@mskcc.org 
Stephanie Lobaugh lobaughs@mskcc.org 


## Purpose: 
To produce a descriptive statistics summary table for each variable in the dataset. The frequency, including # of missing value will be generated for categorical variables; and summary statistics (n, mean, median, Q1, Q3, min, max, standard deviation, # of missing) for numerical variables.  This macro creates descriptive statistics one variable at a time and requires a separate macro call for each variable.


## Notes: 
In order to use this macro, variables must be numeric; to print items that are character, create format that can be applied in table1 macro call. Nonparametric testing is the default. If you would like to not call each variable individually, see table1_loop macro documentation.
Parameters:
