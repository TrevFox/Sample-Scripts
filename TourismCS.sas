/* Create Library */
%let path=~/ECRB94/data;
%let outpath=~/ECRB94/output;
libname cr "&path";

/* Cleaning Tourism Data */
data cr.cleaned_tourism(drop=_1995-_2013);	*only want 2014 data for this project;
	length Country_Name $ 55 Tourism_Type $ 20;	*creating new columns for splicing summary data;
	retain Country_Name '' Tourism_Type '';
	set cr.tourism;	*input dataset;

	if A ^=. then
		Country_Name=Country;	*extracting country name from summary column;

	if lowcase(Country) in ('inbound tourism', 'outbound tourism') then
		Tourism_Type=propcase(Country);	*splitting out tourism types from summary column;

	if Country_Name ^=Country and propcase(Country) ^=Tourism_Type;	*output only remaining summary data;

	if Series='..' then
		Series='';	*clean missing char values;
	Series=upcase(Series); *make sure all codes are uppercase;

	if _2014='..' then
		_2014='.';	*clean missing numeric values;
		
	/* Creating numeric column to store dollar values and calculating actual values
		based on conversion multiplier taken from Country summary column*/ 

	if scan(upcase(Country), -1, ' ')='THOUSANDS' then
		do;
			Y2014=input(_2014, comma6.)*1000;
			Category=scan(Country, 1, '-', 'r');
		end;
	else if scan(upcase(Country), -1, ' ')='MN' then
		do;
			Y2014=input(_2014, comma6.)*1000000;
			Category=cat(scan(Country, 1, '-', 'r'), ' - US$');
		end;
	format Y2014 comma20.;	*format for readability;
	drop A COUNTRY _2014;	*drop unnecassery columns;
run;

/* Create Custom format to label Continents by name from lookup code in country_info table */

proc format;
	value ContinentIDs 1='North America' 2='South America' 3='Europe' 4='Arfica' 
		5='Asia' 6='Oceania' 7='Antartica';
run;

proc sort data=cr.cleaned_tourism(rename=(Country_Name=Country));	*sort and rename column for merge;
	by Country;
run;

proc sort data=cr.country_info out=cr.country_sorted;	*sort for merge;
	by Country;
run;

/* Create final cleaned table from merging on sorted country_info table with custom format 
	to get Continent names and removing nonmatching observations to see Countries without tourism data */ 

data cr.final_tourism cr.no_country_found(keep=Country);
	merge cr.cleaned_tourism(in=t) cr.country_sorted(in=c);
	by Country;

	if t=1 and c=1 then
		output cr.final_tourism;

	if (t=1 and c=0) and first.Country=1 then
		output cr.no_country_found;
	format Continent ContinentIds.;
run;

