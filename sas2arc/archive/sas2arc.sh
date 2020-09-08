#!/bin/sh
# This is a shell archive, meaning:
# 1. Remove everything above the #! /bin/sh line.
# 2. Save the resulting text in a file.
# 3. Execute the file with /bin/sh (not csh) to create the files:
#           sas2arc.txt
#           sas2arc.inc
#           sas2arc.sas
#           Class.lsp 
#           Classmss.lsp
#      
#      
#       
# This archive created: June 7, 1999 
cat >sas2arc.txt <<'CUT HERE............'
SAS2ARC: A SAS Macro to create an Arc data file from a SAS data set. 
Arc is  the regression package described in R. D. Cook and S. Weisberg
(1999),  "Applied Regression Including Computing and Graphics," Wiley.


OS:             UNIX
                WINDOWS version also available
SAS VERSION     6.12
DATE:           06/05/99
SOURCE:         http://www-personal.umich.edu/~agalecki/
Prepared by:
            Andrzej Galecki M.D.,Ph.D.
            Geriatrics Research and Training Center
            Institute of Gerontology
            University of Michigan
            300 North Ingalls
            Ann Arbor, MI 48109-2007
and
            Yiqun Zhang
            Department of Biostatistics
            University of Michigan
            Ann Arbor, MI 48109-2029

Authors are ready to assist users in the implementation of this macro
whenever possible.

            E-mail: agalecki@umich.edu
            tel. 734-936-2138

The University of Michigan Institute of Gerontology gives
general permission for this SAS2ARC macro to be copied and distributed to
interested users free of charge. However neither the author nor the
Institute of Gerontology at the University of Michigan can be
responsible for any errors herein or for the consequences of using this
program.

General description
-------------------
SAS2ARC.SAS is a SAS macro designed to transform SAS data sets into
datasets in Arc format.  The distribution consists of five files:

sas2arc.txt - this file.
sas2arc.inc - declaration of macros.
sas2arc.sas - an example of macro invocation.
Class.lsp   - an example of output file for use by Arc program.
Classmss.lsp- another example of the output file.

stored in a shell archive file sas2arc.unx. Execute this file with /bin/sh
(not csh) to create the files listed above.

Usage
-----
The file sas2arc.sas provides an example of the use of this macro. The first
50 lines of that file create a SAS dataset called `class' with variables named
name, height, weight, age, and gender.  SAS2Arc can write this dataset onto a
file that can be read by Arc, as follows.  First, the macro must be included
in the SAS session:

%include 'sas2arc.inc';

Next, we create the data file:

%sas2arc(data=class);

Macro variables 
---------------
The sas2arc macro accepts several variables, as follows:

DATA        - REQUIRED name of the SAS dataset.
FILE        - OPTIONAL output file name for Arc data. If FILE is not 
              specified, the output will be the input SAS data set name 
              with a .lsp extension.
ARCDATA     - OPTIONAL Arc dataset name. If ARCDATA not specified then 
              Arc dataset name is the same as SAS dataset name.
              See the file Class.lsp for an example.
DESCRIPT    - Description about the data set you want to output to the Arc
              dataset file. By default description is:
              Created from SAS dataset <Input SAS dataset>.  This can be any 
              not quoted text string that provides a description of the
              dataset.
MISSING     - specifies missing character in Arc data. By default the missing
              value character is a ?.  The SAS missing value character "."
              CANNOT be used by Arc.

The file sas2arc.sas provides a complete example.

Translating Arc datasets to SAS datasets
----------------------------------------
It is also possible to go the other way, and translate Arc datasets to SAS
datasets.  If you are using version 1.00 of Arc, you will need to download the
most recent version of updates.lsp from www.stat.umn.edu/arc; the changes will
be part of version 1.1 when it is released.

	1.  Start Arc, and load the data file of interest.
	2.  Select the item "Display data" from the dataset menu.
	3.  Check the box for "Save data in an interchange file."  After pushing
OK, select a file name for the interchange file.
   4.  The interchange file will have variable names in the first row, and
values in succeeding rows, with ? used as a missing value character.  Strings
will have "_" substituted for " ", so, for example, Los Angeles becomes
Los_Angeles.  Strings are not quoted.  This file can be used with SAS or most
any other statistical package.
CUT HERE............

cat >sas2arc.sas <<'CUT HERE............'

dm "log;clear; output; clear";

proc format;
   value gender 0='F'
                1='M';
run;
/* Data used in the following examples */
   data class;
      input name $ height weight age gender;
      cards;
   Alfred  69.0 112.5 14 1
   Alice   56.5  84.0 13 0
   Barbara 65.3  98.0 13 0
   Chris   62.8 102.5 14 1
   Henry   63.5 102.5 14 1
   James   57.3  83.0 12 1
   Jane    59.8  84.5 12 0
   Janet   62.5 112.5 15 0
   Jeffrey 62.5  84.0 13 1
   John    59.0  99.5 12 1
   Joyce   51.3  50.5 11 0
   Judy    64.3  90.0 14 0
   Louise  56.3  77.0 12 0
   Mary    66.5 112.0 15 0
   Philip  72.0 150.0 16 1
   Robert  64.8 128.0 12 1
   Ronald  67.0 133.0 15 1
   Thomas  57.5  85.0 11 1
   William 66.5 112.0 15 1
   ;
run;


/* Dataset with missing values */
data classmss(keep=name -- weight gender);
   set class;
   if name="Thomas" then name=""; 
   if weight< 80 then weight=.;
   if name="Chris" then gender=.;
   format gender gender.;
run;

proc contents data=class out=cont noprint;
run;

proc print data=cont;
run;


%include 'sas2arc.inc';

/* class.lsp is created */
%sas2arc(data=class);

/* classmss.lsp  */
%sas2arc(data=classmss,
         arcdata=DATAMISS,
         descript= Dataset with missing values);
CUT HERE............

cat >sas2arc.inc <<'CUT HERE............'

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


CUT HERE............

cat > Class.lsp <<'CUT HERE............'

dataset=class
begin description
Created from SAS dataset: class
end description
begin variables
Col 0 = NAME = NAME
Col 1 = HEIGHT = HEIGHT
Col 2 = WEIGHT = WEIGHT
Col 3 = AGE = AGE
Col 4 = GENDER = GENDER
end variables
begin data
(
"Alfred" 69 112.5 14 1
"Alice" 56.5 84 13 0
"Barbara" 65.3 98 13 0
"Chris" 62.8 102.5 14 1
"Henry" 63.5 102.5 14 1
"James" 57.3 83 12 1
"Jane" 59.8 84.5 12 0
"Janet" 62.5 112.5 15 0
"Jeffrey" 62.5 84 13 1
"John" 59 99.5 12 1
"Joyce" 51.3 50.5 11 0
"Judy" 64.3 90 14 0
"Louise" 56.3 77 12 0
"Mary" 66.5 112 15 0
"Philip" 72 150 16 1
"Robert" 64.8 128 12 1
"Ronald" 67 133 15 1
"Thomas" 57.5 85 11 1
"William" 66.5 112 15 1
)

CUT HERE............

cat > Classmss.lsp << 'CUT HERE ............'
 
dataset=DATAMISS
begin description
Dataset with missing values
end description
begin variables
Col 0 = NAME = NAME
Col 1 = HEIGHT = HEIGHT
Col 2 = WEIGHT = WEIGHT
Col 3 = GENDER = GENDER
end variables
begin data
(
"Alfred" 69 112.5 "M"
"Alice" 56.5 84 "F"
"Barbara" 65.3 98 "F"
"Chris" 62.8 102.5  ? 
"Henry" 63.5 102.5 "M"
"James" 57.3 83 "M"
"Jane" 59.8 84.5 "F"
"Janet" 62.5 112.5 "F"
"Jeffrey" 62.5 84 "M"
"John" 59 99.5 "M"
"Joyce" 51.3  ? "F"
"Judy" 64.3 90 "F"
"Louise" 56.3  ? "F"
"Mary" 66.5 112 "F"
"Philip" 72 150 "M"
"Robert" 64.8 128 "M"
"Ronald" 67 133 "M"
 ? 57.5 85 "M"
"William" 66.5 112 "M"
)
