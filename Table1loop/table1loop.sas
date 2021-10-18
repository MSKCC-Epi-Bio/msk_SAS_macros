
*****************************************************************************************************************
                                                                                                     
   DESCRIPTION: Loop over %table1 macro (created by Debra Goldman). Must create global macro vars before
                running this macro. See table1-loop-example.SAS for example of how to use.
 
-------------------------------------------------------------------------------------------------------------
                                        
   LANGUAGE:    SAS, VERSION 9.4                                  
                                                                   
   NAME:        Stephanie Lobaugh                               
   DATE:        2/18/2021: Created
                                                                   
****************************************************************************************************************;

* Call in macro version (repo tag). Will print to the log so user is aware which version of the macro they are using
  each time the macro is called;
FILENAME version URL "https://raw.githubusercontent.com/MSKCC-Epi-Bio/create_msk_SAS_project/main/version.sas";
%INCLUDE version;

%macro table1_loop(ds =, 
				   rowvarlist =, 
                   rowvarfmtlist =, 
                   typelist =, 
				   comboformat_set = 1,
                   tablename_set =,
				   order_set = internal,
                   groupvar_set =, 
                   groupvarfmt_set =, 
                   grouppercent_set = 1,
                   testlist =,
                   test_set = 0,
                   include_missing_set = 0, 
                   contcount_set = 1,
                   contstat_set = 1,
				   nameformat_set =);

* Create table shell to store results before iterations begin;
%IF %length(&tablename_set)>0 %THEN %DO;
	data &tablename_set;
		length rowvar_value $ 50;
		length rowvar_name $ 50;
		length groupvar_value $ 50;
		length groupvar_name $ 50;
		length combo $ 50;
		length range $ 30;
		length iqr $ 30; 
		length mean $ 30;
		length median $ 30;
		frequency=.;
		percent=.;
		colpercent=.;
		rowpercent=.;
		rowvar_value="";
		rowvar_name="";
		groupvar_value="";
		groupvar_name="";
		combo="";
		total=.;
		median="";
		mean = "" ;
		std = . ; 
		range = ""; 
		iqr = "";
		pvalue=.;
		rowvar_type=.;
		rowvar_raw = . ; 
		groupvar_raw = . ; 
	run;
%END;
%ELSE %DO;
	data table1_combined;
		length rowvar_value $ 50;
		length rowvar_name $ 50;
		length groupvar_value $ 50;
		length groupvar_name $ 50;
		length combo $ 50;
		length range $ 30;
		length iqr $ 30; 
		length mean $ 30;
		length median $ 30;
		frequency=.;
		percent=.;
		colpercent=.;
		rowpercent=.;
		rowvar_value="";
		rowvar_name="";
		groupvar_value="";
		groupvar_name="";
		combo="";
		total=.;
		median="";
		mean = "" ;
		std = . ; 
		range = ""; 
		iqr = "";
		pvalue=.;
		rowvar_type = .;
		rowvar_raw = . ; 
		groupvar_raw = . ;
	run;
%END;

%local i;
%do i = 1 %to %sysfunc(countw(&rowvarlist));
proc odstext;
	p "Row format for %scan(&&rowvarlist, &i, " ") = %scan(&&rowvarfmtlist, &i, " ")" 
	/ style = [fontsize = 11pt fontfamily = Arial];	
run;
	%table1(data = &ds, 
		    rowvar = %scan(&rowvarlist, &i, " "), 
		    rowvartype = %scan(&typelist, &i, " "), 
		    rowvarformat = %scan(&rowvarfmtlist, &i, " "), 
			%if %length(&tablename_set)>0 %then %do;
		    	tablename = &tablename_set, 
			%end;
			%if %length(&tablename_set)=0 %then %do;
		    	tablename = table1_combined, /* default from %table1 macro */
			%end;
			include_miss = &include_missing_set,
		    comboformat = &comboformat_set,
			contcount = &contcount_set,
			contstat = &contstat_set,
			order = &order_set,
			%if %length(&groupvar) > 0 %then %do;
			    groupvar = &groupvar_set,
	            groupvarformat = &groupvarfmt_set,
				grouppercent = &grouppercent_set,
            	%if %length(&testlist) > 0 %then %do; 
					test = %scan(&testlist, &i, " "), 
				%end;
				%if %length(&testlist) = 0 %then %do;
					test = &test_set,
				%end;
			%end;
		    nameformat = &nameformat_set,
			deletedat = 1);
%end;

* Print macro version (repo tag) to the log so user is aware which version of the macro they are using;
%put ATTENTION! Using Table 1 Loop SAS Macro ('%table1_loop') Version: &version;
%put ATTENTION! Version corresponds with the GitHub repository tag;

%mend table1_loop;




