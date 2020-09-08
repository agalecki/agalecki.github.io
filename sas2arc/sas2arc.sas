
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
