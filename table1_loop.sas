


*****************************************************************************************************************
                                                                                                     
   DESCRIPTION: Loop over %table1 macro (created by Debra Goldman). Must create global macro vars before
                running this macro. See table1-loop-example.SAS for example of how to use.
 
---------------------------------------------------------------------------------------------------------------
                                        
   LANGUAGE:    SAS, VERSION 9.4                                  
                                                                   
   NAME:        Stephanie Lobaugh                               
   DATE:        2/18/2021: Created
                                                                   
****************************************************************************************************************;

* Macro library;
libname gitmacs "C:\Users\lobaughs\GitHub\macros";
options mstored sasmstore = gitmacs;


%macro loop_table1(ds =, rowvarlist =, rowvarfmtlist =, typelist =, tablename_set =,
                   groupvar_set =, include_missing_set =, groupvarfmt_set =, contstat_set = 1, testlist =) 
	   / source store;
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
		    tablename = &tablename_set, 
			include_miss = &include_missing_set,
		    comboformat = 1,
			contstat = &contstat_set,
			order = internal,
			%if %length(&groupvar) > 0 %then %do;
			    groupvar = &groupvar_set,
	            groupvarformat = &groupvarfmt_set,
            	%if %length(&testlist) > 0 %then %do; test = %scan(&testlist, &i, " "), %end;
			%end;
		    nameformat = $varname.);
%end;
%mend loop_table1;





