# Documentation: Table1loop SAS Macro
#### Macro Name: TABLE1LOOP
#### Created Date/Author: Feb. 2021/Stephanie Lobaugh (Note: Debra Goldman is the author of the table1 macro that is called within the table1_loop macro)
#### Last Update Date/Person: 2021-10-01/Stephanie Lobaugh
#### Other Contributors: Hannah Kalvin
#### Working Environment: SAS 9.4 English version


## Contact 
Stephanie Lobaugh lobaughs@mskcc.org 
Hannah Kalvin kalvinh@mskcc.org 

## Purpose: 
To produce a descriptive statistics summary table for each variable in the dataset. The frequency, including # of missing value will be generated for categorical variables; and summary statistics (n, mean, median, Q1, Q3, min, max, standard deviation, # of missing) for numerical variables.  

## Notes: 
In order to use this macro, variables must be numeric; to print items that are character, create format that can be applied in the macro call. Nonparametric testing is the default.


## Parameters:
| Macro variable | 	Description  |	Required  |  Default  |
| -------------- |:-------------:| :---------:|:---------:|
|DS	|The name of the data set to be analyzed. Must be a single value	| Yes	| |
|ROWVARLIST	| Row variables for which descriptive statistics will be computed. Must be a list of values separated by a single space stored in a global macro variable E.g. height weight agecat |	Yes	| |
|ROWVARFMTLIST |	format of variable. both numeric and character formats will work. note: can also use formats such as 5.0 for count data or $ formats for categorical data. numeric can be set to percentn, integer, decimal etc. Must be a list of values separated by a single space stored in a global macro variable E.g. 8.0 8.0 agecat. |	Yes	| |
|TYPELIST	| 1: categorical; 2: continuous Must be a list of values separated by a single space stored in a global macro variable E.g. 1 1 2	| Yes	| |
|COMBOFORMAT_SET |	Format of combined variable. applies to categorical variables. 1: percent to 1 decimal and 2 spaces between freq and pct; 2: percent to integer with % sign with 2 spaces between freq and pct; 3: percent to 1 decimal with % sign with 2 spaces betweens freq and pct; 4: percent to 1 decimal with one space between freq and pct. Must be a single value |	No |	1 |
|TABLENAME_SET	| provide table name to store output from calling the macro. Must be a single value |	No |	Table1_combined |
|ORDER_SET |	Order of categorical variable output. freq for descending frequency; internal for unformatted; external for formatted order data for data order. Must be a single value |	No |	internal |
|GROUPVAR_SET	| Must be a single value e.g. arm |	No	| |
|GROUPVARFMT_SET|	Must be a single value e.g. arm.	| Yes	| |
|GROUPPERCENT_SET|	Must be a single value e.g. 1	| Yes	| 1 |
|TESTLIST |	test for statistical significance. 0 = do not test; 1 = test. Must be a list of values separated by a single space stored in a global macro variable E.g. 1 1 0 | Yes (unless TEST_SET is defined)	| |
|TEST_SET |	test for statistical significance. 0 = do not test; 1 = test. Must be a single value e.g. 0	| Yes (unless TESTLIST is defined) |	0 |
| INCLUDE_MISSING_SET |	1: include missing values; 0: exclude missing values. default is 1 (include missing) if missing are excluded, also excludes the following- for character variables: ("-999","999","-888","888","missing","unknown","n/a","na"); for numeric variables:  (-999,999,-888,888). note: if missing values are included, then they are included in the denominator when calculating % for categorical variables. Must be a single value e.g. 0 |	Yes |	0 |
|CONTCOUNT_SET |	1: include N for continuous var in category label for non-grouped data or as a secondary row for grouped data. label is not an option for grouped data ; 0: exclude print. note that the frequency will still be included in the output dataset; 2: include the N as a secondary row with N= as the variable value. Must be a single value e.g. 1 |	Yes |	1 |
|CONTSTAT_SET	| 1 for median and range in combined var; 2 for median and  IQR in combined variable; 3 for mean and SD. note that all stats are included in output dataset. this simply refers to combined presentation. Must be a single value e.g. 1	| Yes	| 1 (or anything other than 0 will produce the range) |
|NAMEFORMAT_SET |	give variable format name for dataset. Must be a single value e.g. $varname.	|No	 |Blank (i.e. no format) |

## Usage Example
```{sas}
*include utility for MSK template and macros;
FILENAME utility URL "https://raw.githubusercontent.com/MSKCC-Epi-Bio/create_msk_SAS_project/main/utility.sas";
%INCLUDE utility;

data mydata;
	set "C:\Users\lobaughs\GitHub\SAS\sample_data.sas7bdat";
run;

* Create formats to use in macro call;
proc format;
	value married 0 = "No            " 
				  1 = "Yes" 
				  . = "Missing";

    value $varname "age" = "Age                    "
				   "parity" = "Parity"
				   "married" = "Marital status"
			       "cd4" = "CD4"
				   "sample_size" = "Sample size" ;
run;

* Define global macro vars to pass through macro;
%Let myrowvarlist = age parity married cd4;
%Let myrowvarfmtlist = 8.0 8.0 married. 8.0;
%Let mytypelist = 2 2 1 2;
%Let mytestlist = 1 1 0 1;

%table1_loop(ds = mydata, 
		   rowvarlist = &myrowvarlist, 
           rowvarfmtlist = &myrowvarfmtlist, 
           typelist = &mytypelist, 
		   comboformat_set = 1,
           tablename_set = mydescriptives,
		   order_set = internal,
           groupvar_set = arm, 
           groupvarfmt_set = $30., 
           grouppercent_set = 1,
           testlist = &mytestlist,
           include_missing_set = 1, 
           contcount_set = 1,
           contstat_set = 1,
		   nameformat_set = $varname.);

* Format table for proc report;
data mydescriptives2;
	set mydescriptives;
    by rowvar_name notsorted rowvar_value notsorted;
    retain cnt;
	retain order 0;

	* Create variable to use in proc report to make sure the p-value prints with the first row associated with each variable;
	if rowvar_value not in("Median (Range)","Mean (SD)","N Missing","Missing","N =","N Total","Median (IQR)") then do;
	    if first.rowvar_name then cnt = 0;
		if first.rowvar_value then cnt = cnt+1;
	end;

	else do;
		if rowvar_value in("Median (Range)","Mean (SD)","Median (IQR)") then cnt = 1;
		if rowvar_value = "N =" then cnt = 2;
		if rowvar_value = "N Total" then cnt = 3;
		if rowvar_value in("N Missing","Missing") then cnt = 99;
	end;

	* Create variable to use for shading every other row in proc report when presenting results;
	rowvar_value = strip(rowvar_value);
	if first.rowvar_name then order = order+1;
run;

* define an escapechar so that footnotes can be used in proc report;
ods escapechar = "^";

* Present descriptives using proc report;
proc report data = mydescriptives2 headline nowindows missing
	style(report) = [rules = none frame = void fontfamily = Arial font_size = 11pt];
	where combo ne "" and rowvar_value ne "N Total";
	Title "Table 1. Patient Characteristics";
	column rowvar_name 
		   cnt 
		   rowvar_value 
		   ("Arm" groupvar_value), 
		        ("N (%)" dummy combo) 
		   ("p-value^{super 1}" pvalue)
                order;
	define rowvar_name / group order = data '' style = [font_weight = bold] format = $varname.;
	define cnt / group order = data '' noprint;
	define rowvar_value / group order = data '' style = [textalign = right];
	define groupvar_value / across '' order = data;
	define dummy / computed noprint;
	define combo / display '' style = [textalign = center];
	define pvalue / sum '' style = [textalign = right];
	define order / group order = data noprint;

	compute order;
		if mod(order, 2) gt 0 then call define(_ROW_, 'STYLE', 'style = [background = LIGHTGRAY]');
	endcomp;

	compute after / style = {just = l foreground = black font_weight = bold bordertopwidth = 1 bordertopcolor = black};
		line "1. Statistical tests performed: Kruskal-Wallis test, Fisher's exact test.";
	endcomp;
run; Title;

```
