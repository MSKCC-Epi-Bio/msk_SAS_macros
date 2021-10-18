# Documentation: Table1loop SAS Macro
#### Macro Name: TABLE1LOOP
#### Created Date/Author: Feb. 2021/Stephanie Lobaugh (Note: Debra Goldman is the author of the table1 macro that is called within the table1_loop macro)
#### Last Update Date/Person: 2021-10-01/Stephanie Lobaugh
#### Other Contributors: Hannah Kalvin
#### Working Environment: SAS 9.4 English version


## Contact 
Stephanie Lobaugh lobaughs@mskcc.org 


## Purpose: 
To produce a descriptive statistics summary table for each variable in the dataset. The frequency, including # of missing value will be generated for categorical variables; and summary statistics (n, mean, median, Q1, Q3, min, max, standard deviation, # of missing) for numerical variables.  This macro creates descriptive statistics one variable at a time and requires a separate macro call for each variable.


## Notes: 
In order to use this macro, variables must be numeric; to print items that are character, create format that can be applied in table1 macro call. Nonparametric testing is the default. If you would like to not call each variable individually, see table1_loop macro documentation.


## Parameters:
| Macro variable | 	Description  |	Required |
| -------------- |:-------------:| :---------:|

## Usage Example
