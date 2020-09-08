
%macro sas2arc(data=,
               file=,
               arcdata=,
               descript=,
               missing=?);

%if %length(&descript) = 0  %then %do;
%let descript = Created from SAS dataset: &data;
%end;

%let dt1 = %scan(&data,1,"(");
%let i=0;
%do %while (%scan(&dt1,&i+1,".") ne );
%let i=%eval(&i+1);
%end;
%put i=&i;
%let dsn = %scan(&dt1,&i,".");
%put dt1 &dt1 &dsn;
%if %length(&arcdata)=0 %then %do;
%let arcdata=&dsn;
%end;

%if %length(&file)=0 %then %do;
%let file=%str("&dsn..lsp");
%end;


data _null_;
file &file ;
put "dataset=&arcdata"/
"begin description"/
"&descript";
put 'end description' /
'begin variables';
;
run;


proc contents data=&data
out=dict;
run;

proc sort data=dict;
by varnum;
run;

data _null_;
file &file mod;
set dict end=last;
coln=_n_-1;
if label ne '' then
put 'Col ' coln '= ' name '= ' label ;
if label eq '' then
put 'Col ' coln '= ' name '= ' name ;
if last then put 'end variables';
run;

data _null_;
file &file mod;
put 'begin data' / '('
    ;
run;

/* Based on the dictionary
   create _temp_.inc
*/

data _null_;
set dict end=last;
file '_temp_.inc';
_cmiss_="&missing";
_xfile_=symget('file');
if _n_=1 then put "data _null_;" /
  "set &data;" /
  "file  " _xfile_ "mod;" /
;

/*

   Type   Type2
      1     1    Format:  BEST or w.d
      1     2    Numeric var with character format
      2     3

*/

type2=type+1;

if type=1 then do;
 if upcase(format) in ('BEST') and formatl>0
     then type2=1;
 if format=' ' then type2=1;
end;

put '* Type2=' type2 ';';
/* Consider numeric vars. type2=1. */
if type2=1 then do;
put 'if ' name '= . then put " ' _cmiss_ '" @;';

put 'if ' name ' ne . then put ' name ' @;';
end;

if type2=2 then do;
put 'if ' name '= . then put " ' _cmiss_ '" @;';

put 'if ' name ' ne . then put '
     "'""' " name "+(-1) "  "'""'" " +1 @;";
end;

if type2=3 then do;
put 'if ' name ' eq " " then put " '
                   _cmiss_ '" @;';
put 'if ' name ' ne " " then put '
     "'""' " name "+(-1) "  "'""'" " +1 @;";
end;
if mod(_n_, 10)=0 or last then do;
 put 'put; ';  end;
if last then  put 'run;';
run;

%include '_temp_.inc' ;

data _null_;
file &file mod;
put  ')' /;
run;
%mend sas2arc;
