
libname gitmacs "C:\Users\lobaughs\GitHub\macros";
options mstored sasmstore = gitmacs;

/**********************
Macro for the creation of table 1 for either continuous and categorical data and the option to include a
grouping/stratification lion
1/25/19: right now, only non-parametric tests included
Unless specified with internal order, the macro always puts Unknown/NA at bottom, and No/Negative below other values
automatically includes sample size at the top of the table if it doesn't yet exist 

parameters:
 required (variables must be listed in macro statement):
	data 		    = dataset to pull data from 
	rowvartype      = 1: categorical stats; 2: continuous summary stats
	rowvarformat    = format of variable. both numeric and character formats will work. 
				      note: can also use formats such as 5.0 for count data or $ formats for categorical data
					  numeric can be set to percentn, integer, decimal etc.
optional but recommended to list (variables can be left out of macro statement and macro will still run):
	table_name		= provide table name from create table1 macro above. If not provided, defaults to table1_combined
					  as in create table name macro 
	groupvar 		= grouping variable. If blank, it runs single column. If variable listed, it will provide an overall
				  	  and values stratified by this grouping variable. default is to provide columnar proportion (see below)
	grouprvarformat = grouping variable format. Will apply this format to variable. If group variable is not provided,
					  this variable is not needed. 
optional with defaults (variables can be left out of macro statement and macro will still run):
	grouppercent = percentage type included in combined variable
				   all percents will be available in the dataset
				   1=column percent; 2=row percent; 0=overall percent
				   default is 1, column percent 
	test 		 = test for statistical significance
					0 = do not test; 1 = test
					default is 1, test for significance
	include_miss = 1: include missing values; 0: exclude missing values. 
			       default is 1 (include missing) 
				   if missing are excluded, also excludes the following
				   for character variables:
					 ("-999","999","-888","888","missing","unknown","n/a","na");
					for numeric variables: 
						(-999,999,-888,888)	
	contcount    = 1: include N for continuous var in category label for non-grouped data or as a secondary row
					 for grouped data. label is not an option for grouped data ; 0: exclude print
                   note that the frequency will still be included in the output dataset
				   2: include the N as a secondary row with N= as the variable value
			       default is 1 (include N with Median(range) / Median (IQR))
	contstat    = 1 for median and range in combined var; 2 for median and  IQR in combined variable
				   3 for mean and SD
			       default is 1 (use median and  range) or anything other than 0 will produce the range 
				   note that all stats are included in output dataset. this simply refers to combined presentation

	order	     = order of categorical variable output
                   freq for descending frequency; internal for unformatted; external for formatted order
                   data for data order 
  				   default is freq (order by descending frequency) 
	comboformat	 = format of combined variable. applies to categorical variables
				   1: percent to 1 decimal and 2 spaces between freq and pct;
				   2: percent to integer with % sign with 2 spaces between freq and pct;
				   3: percent to 1 decimal with % sign with 2 spaces betweens freq and pct;
                   4: percent to 1 decimal with one space between freq and pct
				   default is 1 ( N  (PCT.1))
	view		 = output of table
				   1: output table; 0 or any other value, no table
				   default is blank
				   
	nameformat	 = give variable format name for dataset
				   default is blank (no format)
				   

***********************/
%macro table1(data=,rowvar=,rowvartype=,rowvarformat=,tablename=,
				groupvar=,groupvarformat=,grouppercent=1,test=0,
			  	include_miss=1,order=freq,comboformat=1,
				contcount=1,contstat=1,
			  	view=,nameformat=)
				/store source;
%put "NOTE: variables in data must be numeric and require a format applied (rowvarformat) in order to show text in table" ;
/*indicator if grouping variable had been included*/
%if %length(&groupvar) = 0 %then %do;
/*	create a dummy format or use 5.0 if no format was provided*/
	%if %length(&rowvarformat)=0  %then %do;
		%IF %INDEX(&data,.) %THEN %DO;
			%LET mylib = %SCAN(&data,1,.);
			%LET myds = %SCAN(&data,2,.);
		%END;
		%ELSE %DO;
			%LET mylib = WORK;
			%LET myds = &data;
		%END;

		proc sql noprint;
		select format into :rowvarformat
		from dictionary.columns
		where memname="%UPCASE(&myds)"
		 and libname="%UPCASE(&mylib)" and upcase(name)="%upcase(&rowvar)";
		 quit;
		%if %length(&rowvarformat)=0  %then %do;
			proc format;
			 value $dummyf "1"="1";
			run;
			data _null_;
			set &data;
			if vtype(&rowvar)='N' then call symput('rowvarformat','5.0');
			else if vtype(&rowvar)='C' then call symput('rowvarformat',"$dummyf.");
			run;
		%end;
	%end;
	%IF %length(&tablename)>0  %THEN %DO;
		proc sql;
		 select min(sum(case when rowvar_name = 'sample_size' then 1 else 0 end),1) into :ss_exist
		 from &tablename;
		quit;
	%end;
	%else %do;
		proc sql;
		 select min(sum(case when rowvar_name = 'sample_size' then 1 else 0 end),1) into :ss_exist
		 from table1_combined;
		quit;
	%end;
	%if &&ss_exist = 0 %then %do;
		proc sql;
		create table samplesize_v1 as
		select count(*) as frequency, "sample_size" as rowvar_name
		from &data;
		quit;
		data samplesize_v2;
		set samplesize_v1;
		combo = trim(left(frequency));
		rowvar_type = 0;
		run;
		%IF %length(&tablename)>0   %THEN %DO;
			proc append base=&tablename data=samplesize_v2 force nowarn; run;
		%end;
		%ELSE %DO;
			proc append base=table1_combined data=samplesize_v2 force nowarn; run;
		%end;		
		proc datasets nolist;
		delete samplesize_v1 samplesize_v2;
		run; quit;
	%end;
	
	/*if variable is count or categorical variable*/
	%if &rowvartype = 1 %then %do;
		%if &include_miss = 1 %then %do;
			ods output OneWayFreqs=cat_sumstat_v1;
			proc freq data=&data order=&order;
			 tables &rowvar/norow nocum plots=none missing ;
			 format &rowvar &rowvarformat;
			run;
		%end;
		%else %if &include_miss = 0 %then %do;
			%if %index(&rowvarformat,"$")<=0 %then %do;
				ods output OneWayFreqs=cat_sumstat_v1;
				proc freq data=&data order=&order;
				 tables &rowvar/norow nocum plots=none;
				 format &rowvar &rowvarformat;
/*				 where &rowvar not in (-999,999,-888,888);*/
				run;
			%end;
			%else %do;
				ods output OneWayFreqs=cat_sumstat_v1;
				proc freq data=&data order=&order;
				 tables &rowvar/norow nocum plots=none;
				 format &rowvar &rowvarformat;
				 where lowcase(&rowvar) not in ("-999","999","-888","888","missing","unknown","n/a","na");
				run;
			%end;
		%end;
		data cat_sumstat_v2;
		set  cat_sumstat_v1;
		 rowvar_value=put(&rowvar,&rowvarformat.);
		 rowvar_name=("&rowvar");
		 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || ")";
		 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,1))) || "%)";
		 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || "%)";
		 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(Percent,0.1))) || ")";
		 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
		 else if rowvar_value in ("No","None","Negative") then order = 2; 
		 else order =1;
		 rowvar_type = &rowvartype;
		 rowvar_raw = &rowvar;
		 keep rowvar_value  frequency percent combo rowvar_name order rowvar_type rowvar_raw;
		run;
		%if %quote(&order) ne internal %then %do;
			proc sort data=cat_sumstat_v2;
			by order; 
            run;
		%end;
/*		removes warning for variable length check*/
		options varlenchk=nowarn;
		%IF %length(&tablename)>0   %THEN %DO;
			proc append base=&tablename data=cat_sumstat_v2 force nowarn; run;
		%end;
		%ELSE %DO;
			options varlenchk=nowarn;
			proc append base=table1_combined data=cat_sumstat_v2 force nowarn; run;
		%end;
		proc datasets library=work nolist;
		 delete cat_sumstat_v1 cat_sumstat_v2;
		run;quit;
	%end;
	%if &rowvartype=2 %then %do;
		proc means data=&data n median min max q1 q3 mean std;
		 var &rowvar;
		 output out=cont_sumstat_v1 n=frequency median=median_raw min=min max=max q1=q1 q3=q3 mean=mean_raw std=std;
		run;
		%if &contcount=1 %then %do;
			%if &contstat = 1 or (&contstat ne 2 and &contstat ne 3) %then %do;
				data cont_sumstat_v2;
				set cont_sumstat_v1;
				 rowvar_value = "Median (Range)" || " (N=" || trim(left(frequency)) || ")";
				 rowvar_name = ("&rowvar") ;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(min,&rowvarformat))) 
						     || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_value rowvar_name combo median range iqr frequency mean std rowvar_type rowvar_raw;
				run;
			%end;
			%else %if &contstat = 2 %then %do;
				data cont_sumstat_v2;
				set cont_sumstat_v1;
				 rowvar_value = "Median (IQR)" || " (N=" || trim(left(frequency)) || ")";
				 rowvar_name = ("&rowvar") ;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(q1,&rowvarformat))) 
						     || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_value rowvar_name combo median range iqr frequency mean std rowvar_type rowvar_raw;
				run;
			%end;
			%else %if &contstat = 3 %then %do;
				data cont_sumstat_v2;
				set cont_sumstat_v1;
				 rowvar_value = "Mean (SD)" || " (N=" || trim(left(frequency)) || ")";
				 rowvar_name = ("&rowvar") ;
				 combo = trim(left(put(mean_raw,&rowvarformat))) || " (" || trim(left(put(std,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_value rowvar_name combo median range iqr frequency mean std rowvar_type rowvar_raw;
			    run;
			%end;
		%end;
		%if &contcount=2 %then %do;
				%if &contstat = 1 or (&contstat ne 2 and &contstat ne 3) %then %do;
					data cont_sumstat_v2;
					set cont_sumstat_v1;
					 rowvar_value = "Median (Range)";
					 rowvar_name = ("&rowvar") ;
					 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(min,&rowvarformat))) 
							     || "-" || trim(left(put(max,&rowvarformat))) || ")";
					 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
					 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
					 median = put(median_raw,&rowvarformat);
				 	 mean = put (mean_raw,&rowvarformat);
					 rowvar_type = &rowvartype;
					output;
					 rowvar_value = "N =";
					 rowvar_name = ("&rowvar") ;
					 combo= put(trim(left(frequency)),5.0);
					 rowvar_type = &rowvartype;
					output;
					keep rowvar_value rowvar_name combo median range iqr frequency rowvar_type;
					run;
				%end;
				%else %if &contstat = 2 %then %do;
					data cont_sumstat_v2;
					set cont_sumstat_v1;
					 rowvar_value = "Median (IQR)";
					 rowvar_name = ("&rowvar") ;
					 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(q1,&rowvarformat))) 
							     || "-" || trim(left(put(q3,&rowvarformat))) || ")";
					 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
					 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
					 median = put(median_raw,&rowvarformat);
				 	 mean = put (mean_raw,&rowvarformat);
					 rowvar_type = &rowvartype;
					output;
					 rowvar_value = "N =";
					 rowvar_name = ("&rowvar") ;
					 combo= put(trim(left(frequency)),5.0);
					 rowvar_type = &rowvartype;
					output;
					keep rowvar_value rowvar_name combo median range iqr frequency rowvar_type;
					run;
				%end;
				%else %if &contstat = 3 %then %do;
					data cont_sumstat_v2;
					set cont_sumstat_v1;
					 rowvar_value = "Mean (SD)";
					 rowvar_name = ("&rowvar") ;
					 combo = trim(left(put(mean_raw,&rowvarformat))) || " (" || trim(left(put(std,&rowvarformat))) || ")";
				 	 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 	 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
					 median = put(median_raw,&rowvarformat);
				 	 mean = put (mean_raw,&rowvarformat);
					 rowvar_type = &rowvartype;
					output;
					 rowvar_value = "N =";
					 rowvar_name = ("&rowvar") ;
					 combo= put(trim(left(frequency)),5.0);
					 rowvar_type = &rowvartype;
					output;
					keep rowvar_value rowvar_name combo median range iqr frequency rowvar_type;
					run;
				%end;
		%end;
		%else %if &contcount = 0 %then %do;
			%if &contstat = 1 or (&contstat ne 2 and &contstat ne 3) %then %do;
				data cont_sumstat_v2;
				set cont_sumstat_v1;
				 rowvar_value = "Median (Range)" ;
				 rowvar_name = ("&rowvar") ;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(min,&rowvarformat))) 
						     || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				keep rowvar_value rowvar_name combo median range iqr frequency rowvar_type;
				run;
			%end;
			%else %if &contstat = 2 %then %do;
			data cont_sumstat_v2;
			set cont_sumstat_v1;
			 rowvar_value = "Median (IQR)";
			 rowvar_name = ("&rowvar") ;
			 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(q1,&rowvarformat))) 
					     || "-" || trim(left(put(q3,&rowvarformat))) || ")";
			 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
			 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
			 median = put(median_raw,&rowvarformat);
			 mean = put (mean_raw,&rowvarformat);
			 rowvar_type = &rowvartype;
			keep rowvar_value rowvar_name combo median range iqr frequency rowvar_type;
			run;
			%end;
			%else %if &contstat = 3 %then %do;
				data cont_sumstat_v2;
				set cont_sumstat_v1;
				 rowvar_value = "Mean (SD)" ;
				 rowvar_name = ("&rowvar") ;
				 combo = trim(left(put(mean_raw,&rowvarformat))) || " (" || trim(left(put(std,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				keep rowvar_value rowvar_name combo median range iqr frequency mean std rowvar_type;
			    run;
			%end;
		%end;
		options varlenchk=nowarn;
		%IF %length(&tablename)>0   %THEN %DO;
			proc append base=&tablename data=cont_sumstat_v2 force nowarn; run;
		%end;
		%ELSE %DO;
			options varlenchk=nowarn;
			proc append base=table1_combined data=cont_sumstat_v2 force nowarn; run;
		%end;
		proc datasets library=work nolist;
		 delete cont_sumstat_v1 cont_sumstat_v2;
		run;quit;
	%end;
	%if &view=1 and %length(&tablename)>0 %then %do;
		%if %length(&nameformat)>0 %then %do;
			proc report data=&tablename headline  missing;
			column rowvar_name rowvar_value (combo dummyvar) ;
			define rowvar_name/group order=data '' format=&nameformat;
			define rowvar_value/ group order=data '' style=[textalign=right];
			define combo/display 'N (%)' style=[textalign=center];
			define dummyvar/computed noprint ;
			compute dummyvar;
				dummyvar=1;
			endcomp;
			where combo ne "";
			run;
		%end;
		%else %do;
			%IF %INDEX(&data,.) %THEN %DO;
				%LET mylib = %SCAN(&data,1,.);
				%LET myds = %SCAN(&data,2,.);
			%END;
			%ELSE %DO;
				%LET mylib = WORK;
				%LET myds = &data;
			%END;
			proc sql noprint;
			create table tmp_label as
			select name, label 
			from dictionary.columns
			where memname="%UPCASE(&myds)" and libname="%UPCASE(&mylib)" and label ne "";
			quit;
			data tmp_label2;
			set tmp_label;
			label_trunc = tranwrd(label,"'","");
			format_text = "'"|| trim(left(lowcase(name))) || "' ='" || trim(left(label_trunc)) || "'";
			run;
			proc sql noprint;
			select format_text
			into :varlabel separated by " "
			from tmp_label2;
			quit;
			proc format;
			value $varlabelf &varlabel;
			run;
			proc datasets library = work nolist;
			delete tmp_label tmp_label2; run; quit;
			proc report data=&tablename headline  missing;
			column rowvar_name rowvar_value (combo dummyvar) ;
			define rowvar_name/group order=data '' format=$varlabelf.;
			define rowvar_value/ group order=data '' style=[textalign=right];
			define combo/display 'N (%)' style=[textalign=center];
			define dummyvar/computed noprint ;
			compute dummyvar;
				dummyvar=1;
			endcomp;
			where combo ne "";
			run;
		%end;
	%end;
	%else %if &view=1 and %length(&tablename)=0 %then %do;
		%if %length(&nameformat)>0 %then %do;
			proc report data=table1_combined headline  missing;
			column rowvar_name rowvar_value (combo dummyvar) ;
			define rowvar_name/group order=data '' format=&nameformat;
			define rowvar_value/ group order=data '' style=[textalign=right];
			define combo/display 'N (%)' style=[textalign=center];
			define dummyvar/computed noprint ;
			compute dummyvar;
				dummyvar=1;
			endcomp;
			where combo ne "";
			run;
		%end;
		%else %do;
			%IF %INDEX(&data,.) %THEN %DO;
				%LET mylib = %SCAN(&data,1,.);
				%LET myds = %SCAN(&data,2,.);
			%END;
			%ELSE %DO;
				%LET mylib = WORK;
				%LET myds = &data;
			%END;
			proc sql noprint;
			create table tmp_label as
			select name, label 
			from dictionary.columns
			where memname="%UPCASE(&myds)" and libname="%UPCASE(&mylib)" and label ne "";
			quit;
			data tmp_label2;
			set tmp_label;
			label_trunc = tranwrd(label,"'","");
			format_text = "'"|| trim(left(lowcase(name))) || "' ='" || trim(left(label_trunc)) || "'";
			run;
			proc sql noprint;
			select format_text
			into :varlabel separated by " "
			from tmp_label2;
			quit;
			proc format;
			value $varlabelf &varlabel;
			run;
			proc datasets library = work nolist;
			delete tmp_label tmp_label2; run; quit;
			proc report data=table1_combined headline  missing;
			column rowvar_name rowvar_value (combo dummyvar) ;
			define rowvar_name/group order=data '' format=$varlabelf.;
			define rowvar_value/ group order=data '' style=[textalign=right];
			define combo/display 'N (%)' style=[textalign=center];
			define dummyvar/computed noprint ;
			compute dummyvar;
				dummyvar=1;
			endcomp;
			where combo ne "";
			run;
		%end;
	%end;
	%else %return;
%end;
%else %if %length(&groupvar)>0 %then %do;
	proc sort data=&data;
	 by &groupvar;
	run;
	%IF %length(&tablename)>0  %THEN %DO;
		proc sql;
		 select min(sum(case when rowvar_name = 'sample_size' then 1 else 0 end),1) into :ss_exist
		 from &tablename;
		quit;
	%end;
	%else %do;
		proc sql;
		 select min(sum(case when rowvar_name = 'sample_size' then 1 else 0 end),1) into :ss_exist
		 from table1_combined;
		quit;
	%end;
	%if &&ss_exist = 0 %then %do;
		proc sql;
		create table total_samplesize_v1 as
		select count(*) as frequency, "sample_size" as rowvar_name,"All Patients" as groupvar_value
		from &data;
		quit;
		data total_samplesize_v2;
		set total_samplesize_v1;
		combo = trim(left(frequency));
		groupvar_name=("&groupvar");
		run;
		ods output OneWayFreqs=samplesize_v1;
		proc freq data=&data;
		tables &groupvar/nocum plots=none;
		format &groupvar &groupvarformat;
		run;
		data samplesize_v2;
		set samplesize_v1;
		length groupvar_name $ 50;
		length groupvar_value $ 50;
		 groupvar_value=put(&groupvar,&groupvarformat.);
		 rowvar_name="sample_size";
		 groupvar_name=("&groupvar");
		 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || ")";
		 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,1))) || "%)";
		 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || "%)";
		 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(Percent,0.1))) || ")";
		 rowvar_type = 0;
		 groupvar_raw = &groupvar;
		 keep groupvar_value groupvar_name frequency percent combo rowvar_name rowvar_type groupvar_raw;
		run;
		%IF %length(&tablename)>0   %THEN %DO;
			proc append base=&tablename data=total_samplesize_v2 force nowarn; run;
			proc append base=&tablename data=samplesize_v2 force nowarn; run;
		%end;
		%ELSE %DO;
			proc append base=table1_combined data=total_samplesize_v2 force nowarn; run;
			proc append base=table1_combined data=samplesize_v2 force nowarn; run;
		%end;		
		proc datasets nolist;
		delete samplesize_v1 samplesize_v2 total_samplesize_v1 total_samplesize_v2;
		run; quit;
	%end;

	%if &rowvartype = 1 %then %do;
		%if &test = 1 %then %do;
			%if &include_miss = 1 %then %do;
				/*test is run without the missing included while the summary stats are taken from second run of proc freq*/
				proc freq data=&data order=&order;
				 tables &rowvar*&groupvar/plots=none nocum exact;
				 output out = exacttest_v1 fisher ;
				 %if %sysfunc(find(&rowvarformat,%str($))) > 0 %then %do;
				 	 where not missing(&rowvar) and not missing(&groupvar);
				 %end;
				 %if %sysfunc(find(&rowvarformat,%str($))) = 0 %then %do;
					 where &rowvar ne . and not missing(&groupvar) and &rowvar not in (-888,-999,888,999);
				 %end;
				 format &rowvar &rowvarformat &groupvar &groupvarformat;
				run;
				ods output crosstabfreqs=cat_sumstat_v1;
				proc freq data=&data order=&order;
				 tables &rowvar*&groupvar/plots=none nocum missing;
				 format &rowvar &rowvarformat &groupvar &groupvarformat;
				run;
			%end;
			%else %if &include_miss = 0 %then %do;
				%if %index(&rowvarformat,"$")<=0 and %index(&groupvarformat,"$")<=0 %then %do;
					ods output crosstabfreqs=cat_sumstat_v1;
					proc freq data=&data order=&order;
				 	tables &rowvar*&groupvar/plots=none nocum exact;
				 	output out = exacttest_v1 fisher ;
					where not missing(&rowvar) and not missing(&groupvar) 
					/*and &rowvar not in (-888,-999,888,999) */
				 	/*and &groupvar not in (-888,-999,888,999)*/
					;
				 	format &rowvar &rowvarformat &groupvar &groupvarformat;
					run;
				%end;
				%else %do;
					ods output crosstabfreqs=cat_sumstat_v1;
					proc freq data=&data order=&order;
				 	tables &rowvar*&groupvar/plots=none nocum exact;
				 	output out = exacttest_v1 fisher ;
						lowcase(&rowvar) not in ("-888","-999","888","999","unknown","na","n/a") 
				 		and lowcase(&groupvar) not in ("-888","-999","888","999","unknown","na","n/a") ;
				 	format &rowvar &rowvarformat &groupvar &groupvarformat;
					run;
				%end;
			%end;
			%if &grouppercent = 1 or &grouppercent = . %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					colpercent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(ColPercent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value
					 frequency colpercent combo rowpercent percent order rowvar_type rowvar_raw groupvar_raw;
				run;
			%end;
			%else %if &grouppercent = 2 %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					rowpercent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if 	 &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(rowPercent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value
					 frequency colpercent combo rowpercent percent order rowvar_type rowvar_raw groupvar_raw;
				run;
			%end;
			%else %if &grouppercent = 0 %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					percent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(Percent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value
					 frequency colpercent combo rowpercent percent order rowvar_type rowvar_raw groupvar_raw;
				run;
			%end;
			proc sort data=cat_sumstat_v3;
			by order;
			run;
			data exacttest_v2;
			set exacttest_v1;
			 pvalue=xp2_fish;
			keep pvalue;
			run;
			data cat_merge_v1;
			merge cat_sumstat_v3 exacttest_v2;
			run;
			/*	removes warning for variable length check*/
			options varlenchk=nowarn;
			%IF %length(&tablename)>0 %THEN %DO;
					proc append base=&tablename data=cat_merge_v1 force nowarn; run;
			%end;
			%ELSE %DO;
				proc append base=table1_combined data=cat_merge_v1 force nowarn; run;
			%end;
			proc datasets library=work nolist;
			 delete cat_sumstat_v1 cat_sumstat_v2 cat_sumstat_v3 cat_merge_v1 exacttest_v1 exacttest_v2;
			run; quit;
		%end;	
		%if &test = 0 %then %do;
			%if &include_miss = 1 %then %do;
				ods output crosstabfreqs=cat_sumstat_v1;
				proc freq data=&data order=&order;
				 tables &rowvar*&groupvar/plots=none nocum missing;
				 format &rowvar &rowvarformat &groupvar &groupvarformat;
				run;
			%end;
			%else %if &include_miss = 0 %then %do;
				%if %index(&rowvarformat,"$")<=0 and %index(&groupvarformat,"$")<=0 %then %do;
					ods output crosstabfreqs=cat_sumstat_v1;
					proc freq data=&data order=&order;
				 	tables &rowvar*&groupvar/plots=none nocum;
					where not missing(&rowvar) and not missing(&groupvar) 
/*					and &rowvar not in (-888,-999,888,999) */
/*				 	and &groupvar not in (-888,-999,888,999)*/
					;
				 	format &rowvar &rowvarformat &groupvar &groupvarformat;
					run;
				%end;
				%else %do;
					ods output crosstabfreqs=cat_sumstat_v1;
					proc freq data=&data order=&order;
				 	tables &rowvar*&groupvar/plots=none nocum;
						lowcase(&rowvar) not in ("-888","-999","888","999","unknown","na","n/a") 
				 		and lowcase(&groupvar) not in ("-888","-999","888","999","unknown","na","n/a") ;
				 	format &rowvar &rowvarformat &groupvar &groupvarformat;
					run;
				%end;
			%end;
			%if &grouppercent = 1 or (&grouppercent ne 2 and &grouppercent ne 0) %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					colpercent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(ColPercent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(ColPercent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value order
					 frequency colpercent combo rowpercent percent rowvar_type rowvar_raw groupvar_raw;
				run;

				* FLAG;
				proc print data = cat_sumstat_v2 noobs; run;
				proc print data = cat_sumstat_v3 noobs; run;

			%end;
			%else %if &grouppercent=2 %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					rowpercent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if 	 &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(rowPercent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(rowPercent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value order
					 frequency colpercent combo rowpercent percent rowvar_type rowvar_raw groupvar_raw;
				run;
			%end;
			%else %if &grouppercent=0 %then %do;
				data cat_sumstat_v2;
				set cat_sumstat_v1;
				 if _type_= 11 or _type_=10 then output;
				run;
				data cat_sumstat_v3;
				set cat_sumstat_v2;
				 length rowvar_name $ 50;
				 length groupvar_name $ 50;
				 length groupvar_value $ 50;
				 rowvar_value=put(&rowvar,&rowvarformat.);
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if _type_=10 then do; 
					percent=percent; 
					groupvar_value="All Patients"; 
					groupvar_raw = 100;
				 end;
				 if &comboformat=1 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || ")";
				 else if &comboformat=2 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,1))) || "%)";
				 else if &comboformat=3 then combo=trim(left(frequency)) || "  (" || trim(left(round(Percent,0.1))) || "%)";
				 else if &comboformat=4 then combo=trim(left(frequency)) || " (" || trim(left(round(Percent,0.1))) || ")";
				 rowvar_name=("&rowvar");
				 groupvar_name=("&groupvar");
				 if rowvar_value in ("Unknown","Missing","Not Applicable","NA","N/A") then order = 999;
				 else if rowvar_value in ("No","None","Negative") then order = 2; 
			 	 else order =1;
				 rowvar_type = &rowvartype;
				 rowvar_raw = &rowvar;
				keep rowvar_name rowvar_value groupvar_name groupvar_value order
					 frequency colpercent combo rowpercent percent rowvar_type rowvar_raw groupvar_raw;
				run;
			%end;
			proc sort data=cat_sumstat_v3;
			by order;
			run;
			/*	removes warning for variable length check*/
			options varlenchk=nowarn;
			%IF %length(&tablename)>0 %THEN %DO;
					proc append base=&tablename data=cat_sumstat_v3 force nowarn; run;
			%end;
			%ELSE %DO;
				proc append base=table1_combined data=cat_sumstat_v3 force nowarn; run;
			%end;
			proc datasets library=work nolist;
			 delete cat_sumstat_v1 cat_sumstat_v2 cat_sumstat_v3;
			run; quit;
		%end;
	%end;
	%if &rowvartype=2 %then %do;
		proc means data=&data n median min max q1 q3 mean std nmiss;
		 var &rowvar;
		 by &groupvar;
		 output out=cont_sumstat_v1 n=frequency median=median_raw min=min max=max q1=q1 q3=q3 nmiss=nmiss mean=mean_raw std=std;
		 format &groupvar &groupvarformat;
		run;
		proc means data=&data n median min max q1 q3 mean std nmiss;
		 var &rowvar;
		 output out=cont_sumstat_all_v1 n=frequency median=median_raw min=min max=max q1=q1 q3=q3 nmiss=nmiss  mean=mean_raw std=std;
		run;
		/*prevent actual missing group from being grouped with All Patients*/
		data cont_sumstat_all_v2;
		set cont_sumstat_all_v1;
		 all=1;
		run;
		data cont_sumstat_v2;
		 set cont_sumstat_v1 cont_sumstat_all_v2;
		run;
		%if &contcount=1 %then %do;
			%if &contstat = 1 or (&contstat ne 2 and &contstat ne 3) %then %do;
				data cont_sumstat_v3;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Median (Range)";
				 groupvar_name = ("&groupvar");
				 groupvar_value=put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(min,&rowvarformat))) 
						  || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Missing";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= "(" || trim(left(nmiss)) || ")";
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N =";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= put(trim(left(frequency)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Total";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 total = frequency + nmiss;
				 combo= put(trim(left(total)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				keep rowvar_value rowvar_name combo median range iqr frequency groupvar_name groupvar_value rowvar_type
					groupvar_raw;
				run;
			%end;
			%else %if &contstat = 2 %then %do;
				data cont_sumstat_v3;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Median (IQR)";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(q1,&rowvarformat))) 
					     || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Missing";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= "(" || trim(left(nmiss)) || ")";
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N =";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= put(trim(left(frequency)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Total";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 total = frequency + nmiss;
				 combo= put(trim(left(total)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				keep rowvar_value rowvar_name combo median range iqr frequency groupvar_name groupvar_value rowvar_type
					groupvar_raw;
				run;
			%end;
			%else %if &contstat = 3 %then %do;
				data cont_sumstat_v3;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Mean (SD)";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(mean_raw,&rowvarformat))) || " (" || trim(left(put(std,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Missing";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= "(" || trim(left(nmiss)) || ")";
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N =";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo= put(trim(left(frequency)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "N Total";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 total = frequency + nmiss;
				 combo= put(trim(left(total)),5.0);
				 rowvar_type = &rowvartype;
				 output;
				keep rowvar_value rowvar_name combo median range iqr frequency groupvar_name groupvar_value rowvar_type
					groupvar_raw;
				run;
			%end;

		%end;
		%else %if &contcount = 0 %then %do;
			%if &contstat = 1 or (&contstat ne 2 and &contstat ne 3) %then %do;
				data cont_sumstat_v3;
				length groupvar_value $ 50;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Median (Range)";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(min,&rowvarformat))) 
						     || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				keep rowvar_value rowvar_name combo median range iqr frequency nmiss groupvar_name groupvar_value 
					rowvar_type groupvar_raw all;
				run;
			%end;
			%else %if &contstat = 2 %then %do;
				data cont_sumstat_v3;
				length groupvar_value $ 50;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Median (IQR)";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(median_raw,&rowvarformat))) || " (" || trim(left(put(q1,&rowvarformat))) 
					     || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				keep rowvar_value rowvar_name combo median range iqr frequency nmiss groupvar_name groupvar_value 
					rowvar_type groupvar_raw;
				run;
			%end;
			%else %if &contstat = 3 %then %do;
				data cont_sumstat_v3;
				length groupvar_value $ 50;
				set cont_sumstat_v2;
				length groupvar_value $ 50;
				 rowvar_name = ("&rowvar") ;
				 rowvar_value = "Mean (SD)";
				 groupvar_name = ("&groupvar");
				 groupvar_value = put(&groupvar,&groupvarformat.);
				 groupvar_raw = &groupvar;
				 if all=1 then do;
					groupvar_value = "All Patients";
					groupvar_raw = 100;
				 end;
				 combo = trim(left(put(mean_raw,&rowvarformat))) || " (" || trim(left(put(std,&rowvarformat))) || ")";
				 range = " (" || trim(left(put(min,&rowvarformat))) || "-" || trim(left(put(max,&rowvarformat))) || ")";
				 iqr   = " (" || trim(left(put(q1,&rowvarformat))) || "-" || trim(left(put(q3,&rowvarformat))) || ")";
				 median = put(median_raw,&rowvarformat);
				 mean = put (mean_raw,&rowvarformat);
				 rowvar_type = &rowvartype;
				keep rowvar_value rowvar_name combo median range iqr frequency nmiss groupvar_name groupvar_value rowvar_type
					groupvar_raw;
				run;
			%end;
		%end;
		%if &test = 1 or &test ne 0 %then %do;
			proc npar1way data=&data wilcoxon;
			 class &groupvar;
			 var &rowvar;
			where not missing(&groupvar);
			format &groupvar &groupvarformat;
			output out=wilcoxontest_v1 wilcoxon;
			run;
			data wilcoxontest_v2;
			set wilcoxontest_v1;
			if p2_wil ne . then pvalue=p2_wil; else if p_kw ne . then pvalue=p_kw;
			keep pvalue;
			run; 
			data cont_merge_v1;
			merge cont_sumstat_v3 wilcoxontest_v2;
			run;
			options varlenchk=nowarn;
			%IF %length(&tablename)>0 %THEN %DO;
				proc append base=&tablename data=cont_merge_v1 force nowarn; run;
			%end;
			%ELSE %DO;
				proc append base=table1_combined data=cont_merge_v1 force nowarn; run;
			%end;
			proc datasets library=work nolist;
			 delete cont_sumstat_v1 cont_sumstat_v2 cont_sumstat_v3 wilcoxontest_v1 wilcoxontest_v2 cont_merge_v1
					cont_sumstat_all_v1 cont_sumstat_all_v2;
			run;quit;
		%end;
		%else %if &test = 0 %then %do;
			%IF %length(&tablename)>0 %THEN %DO;
				proc append base=&tablename data=cont_sumstat_v3 force nowarn; run;
			%end;
			%ELSE %DO;
				proc append base=table1_combined data=cont_sumstat_v3 force nowarn; run;
			%end;
			proc datasets library=work nolist;
			 delete cont_sumstat_v1 cont_sumstat_v2 cont_sumstat_v3 cont_sumstat_all_v1 cont_sumstat_all_v2;
			run;quit;
		%end;
	%end;
	%if &view=1 %then %do;
		%if &test = 1 %then %do;
			proc sql;
	   		select count(fmtname)
			into :fexists 
	   		from dictionary.formats
	   		where upcase(fmtname)="PVAL_32P";
	   		quit;
			%if &&fexists = 0 %then %do;
				proc format;
				 value pval_32p low-<0.001="<.001" .001-<0.06=[5.3] 0.06<-0.95=[5.2] 0.95<-high=">0.95";
				run;
			%end;
			proc sql;
	   		select count(fmtname)
			into :fwexists 
	   		from dictionary.formats
	   		where upcase(fmtname)="PVAL_FW";
	   		quit;
			%if &&fwexists = 0 %then %do;
				proc format;
				 value pval_fw 0-<0.05='bold' 0.05-high='light'; 
				run;
			%end;
			%if %length(&tablename)>0 %then %do;
				%if %length(&nameformat)>0 %then %do;
					proc report data=&tablename headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo ("p-value" pvalue dummyvar) ;
					define rowvar_name/group order=data '' format=&nameformat;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted ;
					define combo/display 'N (%)' style=[textalign=center];
					define pvalue/'' sum format=pval_32p. style=[fontweight=pval_fw.];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
				%else %do;
					%IF %INDEX(&data,.) %THEN %DO;
						%LET mylib = %SCAN(&data,1,.);
						%LET myds = %SCAN(&data,2,.);
					%END;
					%ELSE %DO;
						%LET mylib = WORK;
						%LET myds = &data;
					%END;
					proc sql noprint;
					create table tmp_label as
					select name, label 
					from dictionary.columns
					where memname="%UPCASE(&myds)" and libname="%UPCASE(&mylib)" and label ne "";
					quit;
					data tmp_label2;
					set tmp_label;
					label_trunc = tranwrd(label,"'","");
					format_text = "'"|| trim(left(lowcase(name))) || "' ='" || trim(left(label_trunc)) || "'";
					run;
					proc sql noprint;
					select format_text
					into :varlabel separated by " "
					from tmp_label2;
					quit;
					proc format;
					value $varlabelf &varlabel;
					run;
					proc datasets library = work nolist;
					delete tmp_label tmp_label2; run; quit;
					proc report data=&tablename headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo ("p-value" pvalue dummyvar) ;
					define rowvar_name/group order=data '' format=$varlabelf;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted;
					define combo/display 'N (%)' style=[textalign=center];
					define pvalue/'' sum format=pval_32p. style=[fontweight=pval_fw.];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
			%end;
			%if %length(&tablename)=0 %then %do;
				%if %length(&nameformat)>0 %then %do;
					proc report data=table1_combined headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo ("p-value" pvalue dummyvar) ;
					define rowvar_name/group order=data '' format=&nameformat;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted ;
					define combo/display 'N (%)' style=[textalign=center];
					define pvalue/'' sum format=pval_32p. style=[fontweight=pval_fw.];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
				%else %do;
					proc report data=table1_combined headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo ("p-value" pvalue dummyvar) ;
					define rowvar_name/group order=data '' format=$varlabelf.;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted;
					define combo/display 'N (%)' style=[textalign=center];
					define pvalue/'' sum format=pval_32p. style=[fontweight=pval_fw.];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
			%end;
		%end;
		%if &test = 0 %then %do;
			%if %length(&tablename)>0 %then %do;
				%if %length(&nameformat)>0 %then %do;
					proc report data=&tablename headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo (dummyvar) ;
					define rowvar_name/group order=data '' format=&nameformat;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted ;
					define combo/display 'N (%)' style=[textalign=center];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
				%else %do;
					%IF %INDEX(&data,.) %THEN %DO;
						%LET mylib = %SCAN(&data,1,.);
						%LET myds = %SCAN(&data,2,.);
					%END;
					%ELSE %DO;
						%LET mylib = WORK;
						%LET myds = &data;
					%END;
					proc sql noprint;
					create table tmp_label as
					select name, label 
					from dictionary.columns
					where memname="%UPCASE(&myds)" and libname="%UPCASE(&mylib)" and label ne "";
					quit;
					data tmp_label2;
					set tmp_label;
					label_trunc = tranwrd(label,"'","");
					format_text = "'"|| trim(left(lowcase(name))) || "' ='" || trim(left(label_trunc)) || "'";
					run;
					proc sql noprint;
					select format_text
					into :varlabel separated by " "
					from tmp_label2;
					quit;
					proc format;
					value $varlabelf &varlabel;
					run;
					proc datasets library = work nolist;
					delete tmp_label tmp_label2; run; quit;
					proc report data=&tablename headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo (dummyvar) ;
					define rowvar_name/group order=data '' format=$varlabelf.;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted;
					define combo/display 'N (%)' style=[textalign=center];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
			%end;
			%if %length(&tablename)=0 %then %do;
				%if %length(&nameformat)>0 %then %do;
					proc report data=table1_combined headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo (dummyvar) ;
					define rowvar_name/group order=data '' format=&nameformat;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted ;
					define combo/display 'N (%)' style=[textalign=center];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
				%else %do;
					%IF %INDEX(&data,.) %THEN %DO;
						%LET mylib = %SCAN(&data,1,.);
						%LET myds = %SCAN(&data,2,.);
					%END;
					%ELSE %DO;
						%LET mylib = WORK;
						%LET myds = &data;
					%END;
					proc sql noprint;
					create table tmp_label as
					select name, label 
					from dictionary.columns
					where memname="%UPCASE(&myds)" and libname="%UPCASE(&mylib)" and label ne "";
					quit;
					data tmp_label2;
					set tmp_label;
					label_trunc = tranwrd(label,"'","");
					format_text = "'"|| trim(left(lowcase(name))) || "' ='" || trim(left(label_trunc)) || "'";
					run;
					proc sql noprint;
					select format_text
					into :varlabel separated by " "
					from tmp_label2;
					quit;
					proc format;
					value $varlabelf &varlabel;
					run;
					proc datasets library = work nolist;
					delete tmp_label tmp_label2; run; quit;
					proc report data=table1_combined headline nowindows missing;
					column rowvar_name rowvar_value groupvar_value,combo (pvalue dummyvar) ;
					define rowvar_name/group order=data '' format=$varlabelf.;
					define rowvar_value/ group order=data '' style=[textalign=right];
					define groupvar_value/across  '' order=formatted;
					define combo/display 'N (%)' style=[textalign=center];
					define dummyvar/computed noprint ;
					compute dummyvar;
						dummyvar=1;
					endcomp;
					where combo ne "";
					run;
				%end;
			%end;
		%end;

	%end;
	%else %return;
%end;

%mend table1;

