/* Set of SAS macros used to perform
   interval mapping for dichotomous phenotypes
*/ 


/* Unpacks dataset. */
%macro unpack(dt,dtu);
data &dtu;
  set &dt;
  subject_no=_n_;
  like=0;
  /* First record */
  indx=0;
  select(y);
   when(0) yu=1;
   when(1) yu=0;
  end;
  output;

  /* Second record */
  indx=1;
  select(y);
   when(0) yu=0;
   when(1) yu=1;
  end;
  output;
  drop y;
run;

Title "Unpacked data: &dtu";
proc print;
run;
%mend unpack;

%macro info;
 chromosome      = &chromosome;                          
 marker_left     = &marker_left;                          
 marker_right    = &marker_right;                         
 rec_fraction    = &rec_fraction;                         
 rec_fraction4   = &rec_fraction4;                       
 interval_length4= &interval_length4;                    
 marker_put_xdistfromleft = &marker_put_xdistfromleft;  
 cum_putxdist    = &cum_putxdist;
 put_no          = &put_no;
 analysis_no     = &analysis_no;
 source          = &analysis_no;
%mend info;

%macro haldane(x);
/* x is a distance measured in cM */
 0.5*(1 - exp(-2*&x/100));
%mend haldane;

%macro ksi;
/* Input argument rx
       contains recombination fractions: ra and rb.
   Global arguments:
      xflank indicates two var names containing flanking markers coded 0 or 1
      rxdist recombination fraction for the entire interval.
   Result:  Vector of mixture probabilities.
*/

mfl =%scan(&xflank,1);   /* Left  flanking marker */ 
mfr =%scan(&xflank,2);   /* Right flanking marker */

if (mfl=0 & mfr=0)  then  do;
   ksi0 = (1-ra)*(1-rb)/(1-r);  /* P(000) | 0X0 */
   ksi1 =  ra * rb /(1-r);      /* P(010) | 0X0 */
   end;

if (mfl=0 & mfr=1) then  do;
   ksi0 = (1-ra)*rb/r;          /* P(001) | 0X1 */
   ksi1 = ra*(1-rb)/r;          /* P(011) | 0X1 */
   end;

if (mfl=1 & mfr=0) then  do;
   ksi0 =  ra*(1-rb)/r;         /* P(100) | 1X0 */
   ksi1 =  (1-ra)*rb/r;         /* P(110) | 1X0 */
   end;


if (mfl=1 & mfr=1) then  do;
   ksi0 =  ra*rb /(1-r);          /* P(101) | 1X1 */
   ksi1 =  (1-ra)*(1-rb)/(1-r);   /* P(111) | 1X1 */
   end;
%mend ksi;


%macro logistic(x);
exp(&x)/(1+exp(&x));
%mend logistic;


%macro nlin(dt,nr);    /* nr=0 for null model and nr=1 for full model */

/* Maximum likelihood using PROC NLIN */
proc nlin data=&dt  maxsubit=100 method=newton
    sigsq=1 ;
    by perm_no;
array  ksi{2} ksi0 ksi1;

parms b0 = 0
     %if (&nr) %then b1=0;;
r       = %haldane(&xdist);    /* dist in cM */
ra      = %haldane(&xa);
rb      = %haldane(&xb);
%ksi;

array  eta{2} eta0 eta1;      /* Linear predictor */
eta0=b0;
eta1=b0
    %if (&nr) %then +b1;;
/* phi conditional probabilities:
    phi01= P(Y=1 | putative marker=0)
    phi00= P(Y=0 | putative marker=0)
    phi11= P(Y=1 | putative marker=1)
    phi10= P(Y=0 | putative marker=1)
*/
    phi01=%logistic(eta0);
    phi00=1-phi01;
    phi11=%logistic(eta1);
    phi10=1-phi11;

/* mu joint probabilities */

   mu01   = ksi0*phi01;
   mu00   = ksi0*phi00;
   mu11   = ksi1*phi11;
   mu10   = ksi1*phi10;

/* Coarsening matrix into marginal probabilities: p+0, p+1*/
   predv = mu00 + mu10;                /* P(Y=0) */
   if indx=1 then predv = 1-predv;     /* P(Y=1) */
   ll   = yu*log(predv) - predv;
   model.like = sqrt(-2*ll);
ods output EstSummary = estsum;
ods output ParameterEstimates = estmts;
run;

data estsum;
  set estsum;
  keep Label1 nValue1 perm_no;
  if Label1="Objective";
run;

Title  "Markerl: &marker_left  Summary"; 
Title2 "Distance: &marker_put_xdistfromleft"; 
proc print data=estsum;
run;

Title  "Markerl: &marker_left  Estimates"; 
Title2 "Distance: &marker_put_xdistfromleft"; 
proc print data=estmts;
run;
%mend nlin;

%macro putative_marker;

%let xdist   =&interval_length4;                /* dist in cM */

%let xflank  = m&marker_left  m&marker_right;  /* genotypes at left 
                                                  and right flanking marker*/

%let xa      = &marker_put_xdistfromleft;



%let xb      = (&xdist -  &xa);  /* xb is a distance in cM from the right
                                         flanking marker */




Title "Null model";
%nlin(&data,0);   *null model;
data estsum0;
  set estsum(keep=nValue1 perm_no);
  rename nValue1=_2loglik0;
run;

proc datasets lib=work;
 delete estsum estmts;
quit;

Title "Alternative model";
%nlin(&data,1); *alternative  model;
data estsum1;
  set estsum(keep=nValue1);
  rename nValue1=_2loglik1;
run;

proc datasets lib=work;
 delete estsum estmts;
quit;

data loglik;   /* 
  merge estsum0 estsum1;
  %info;
  G_statistics   =_2loglik0 -_2loglik1;
  Gp_value  =  1 - probchi(G_statistics,1);
  lod_score =0.5*G_statistics/log(10);  
run;

%mend putative_marker;
