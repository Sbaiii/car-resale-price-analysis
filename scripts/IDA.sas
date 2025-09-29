/* Generated Code (IMPORT) */
/* Source File: car_resale_prices.csv */
/* Source Path: /home/u64178372/sasuser.v94/DataManagement */
/* Code generated on: 5/4/25, 12:45 AM */

%web_drop_table(CARSDATA.CAR);


FILENAME REFFILE '/home/u64178394/DataManagement/car_resale_prices.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=CARSDATA.CAR;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=CARSDATA.CAR;
RUN;


%web_open_table(CARSDATA.CAR);

/*View structure of the dataset */
proc contents data=CARSDATA.CAR;
    title 'Structure of Raw Dataset - CARSDATA.CAR';
run;

/*Count total number of rows */
proc sql;
    select count(*) as Total_Records from CARSDATA.CAR;
quit;

/*Calculate number of actual rows */
proc sql;
    select 
        count(*) as Total_Records,
        count(distinct catx('|', full_name, resale_price, registered_year, engine_capacity, insurance, transmission_type, kms_driven, owner_type, 
        fuel_type, max_power, seats, mileage, body_type, city)) as Total_Actual_Records,
        calculated Total_Records - calculated Total_Actual_Records as Total_Duplicated_Rows
    from CARSDATA.CAR;
quit;

PROC SQL;
    SELECT
        COUNT(*) as Total_Records,
        COUNT ('|', full_name, resale_price, registered_year, engine_capacity, insurance, transmission_type,  kms_driven, owner_type, fuel_type, max_power, seats, mileage, body_type, city)) AS Total_Actual_Records,
        CALCULATED Total_Records - CALCULATED Total_Actual_Records AS Total_Duplicated_Rows
    from CARSDATA.CAR;
QUIT;

/*Count number of missing values for each column */
/* Create a format to flag missing values */
proc format;
    value $missfmt ' '='Missing' other='Not Missing'; /*This sets a custom values for Character Variables*/
	value  missfmt  . ='Missing' other='Not Missing'; /*This sets a custom values for Numerical Variables*/
run;

/* Apply format and count missing vs not missing for all variables */
proc freq data=CARSDATA.CAR;
    format _CHAR_ $missfmt. _NUMERIC_ missfmt.; /*This tells SAS to follow format that you have set*/
    tables _ALL_ / missing nocum nopercent; /*This tells SAS to include missing values, no cumulative counts & no percentage counts*/
    title 'Missing Values for All Columns';
run;

/*Frequency count for categorical variables */
proc freq data=CARSDATA.CAR;
    tables fuel_type transmission_type owner_type city body_type;
    title 'Frequency Counts for Categorical Attributes';
run;

/*Initial Data Analysis*/
/* STEP 1: resale price*/
/* STEP A: Clean and convert resale_price to numeric values */
data carsdata.car_clean1;
    set carsdata.car;

    length resale_price 8;

    if not missing(resale_price) then do;
        temp_price = upcase(strip(translate(resale_price, '', ','))); /* Remove commas and extra spaces */
        
        if index(temp_price, 'LAKH') > 0 then do;
            temp_val = compress(temp_price, ,'kd');
            resale_price = input(temp_val, best32.) * 100000;
        end;
        else if index(temp_price, 'CR') > 0 then do;
            temp_val = compress(temp_price, ,'kd');
            resale_price = input(temp_val, best32.) * 10000000;
        end;
        else do;
            temp_val = compress(temp_price, ,'kd');
            resale_price = input(temp_val, best32.);
        end;
    end;

    drop temp_price temp_val;
run;

PROC PRINT DATA=CARSDATA.CAR_clEAN1;
    VAR full_name resale_price;
RUN;

/* Descriptive Statistics */
proc means data=carsdata.car_clean1 n mean median min max std nmiss maxdec=2;
    var resale_price;
    title "Descriptive Statistics for Resale Price";
run;

/*Checking what are the currency values available*/
data resale_currency_check;
    set carsdata.car;

    /* Create a cleaned-up uppercase version of resale_price for analysis */
    clean_resale_price = upcase(strip(resale_price));
run;

proc freq data=resale_currency_check;
    tables clean_resale_price / nocum nopercent;
run;

/* STEP B: Create resale price bins */
data carsdata.car_binned;
    set carsdata.car_clean1;

    length sort_order 8;

    if resale_price < 500000 then sort_order = 1;
    else if resale_price < 1000000 then sort_order = 2;
    else if resale_price < 2000000 then sort_order = 3;
    else if resale_price < 5000000 then sort_order = 4;
    else sort_order = 5;
run;

/* STEP C: Define custom format for resale price ranges */
proc format;
    value pricefmt
        1 = '< 5L'
        2 = '5L – 10L'
        3 = '10L – 20L'
        4 = '20L – 50L'
        5 = '> 50L';
run;

/* STEP D: Create bar chart of resale price bins */
proc sgplot data=carsdata.car_binned;
    vbar sort_order / datalabel;
    xaxis label="Resale Price Range (Lakhs)"
          type=discrete 
          values=(1 2 3 4 5)
          valueformat=pricefmt.;
    yaxis label="Count of Cars";
    format sort_order pricefmt.;
    title "Bar Chart of Cars by Resale Price Range";
run;

/* STEP E: Create boxplot for resale_price to identify outliers */
proc sgplot data=carsdata.car_clean1;
    vbox resale_price /
        fillattrs=(color=lightblue)
        lineattrs=(color=navy);
    yaxis type=log label="Resale Price (Log Scale)";
    title "Boxplot of Resale Prices (with Outliers)";
run;

/* View the cleaned structure */
proc contents data=CARSDATA.CAR_CLEAN1;
    title 'Structure of Cleaned Dataset';
run;

/* STEP 2: registered_year */
DATA CARSDATA.REGISTERED_CLEAN;
    SET CARSDATA.CAR; /* Load original dataset */

    LENGTH actual_registered_year 8; /* New numeric year column (8 bytes = ~15 digits precision) */

    /* Temporary variables */
    retain year_regex; /* Keep the compiled regex pattern across rows */

    IF _N_ = 1 THEN
        /* Match 4-digit year starting with 19xx or 20xx */
        year_regex = PRXPARSE('/\b(20\d{2}|19\d{2})\b/');

    /* Step A Try extracting year from 'registered_year' */
    IF NOT MISSING(registered_year) THEN DO;
        temp_reg = UPCASE(STRIP(registered_year));
        IF PRXMATCH(year_regex, temp_reg) THEN DO;
            CALL PRXSUBSTR(year_regex, temp_reg, pos, len);
            IF pos > 0 THEN DO;
                numeric_year_str = SUBSTR(temp_reg, pos, len);
                actual_registered_year = INPUT(numeric_year_str, 4.);
            END;
        END;
    END;

    /* Step B: If 'actual_registered_year' still missing, extract year from 'full_name' */
    IF MISSING(actual_registered_year) THEN DO;
        temp_name = UPCASE(STRIP(full_name));
        IF PRXMATCH(year_regex, temp_name) THEN DO;
            CALL PRXSUBSTR(year_regex, temp_name, pos2, len2);
            IF pos2 > 0 THEN DO;
                numeric_year_str2 = SUBSTR(temp_name, pos2, len2);
                actual_registered_year = INPUT(numeric_year_str2, 4.);
            END;
        END;
    END;

    /* Clean up temporary variables */
    DROP temp_reg temp_name pos len numeric_year_str pos2 len2 numeric_year_str2 year_regex;
RUN;

/* === Descriptive Statistics === */
proc means data=CARSDATA.REGISTERED_CLEAN n mean median min max std nmiss;
    var actual_registered_year;
    title "Descriptive Statistics for Registered Year";
run;

/* === Frequency Distribution (for Mode Insight) === */
proc freq data=CARSDATA.REGISTERED_CLEAN;
    tables actual_registered_year / nocum nopercent;
    title "Frequency of Registered Years";
run;


/* Bar Chart of Registered Years */
proc sgplot data=CARSDATA.REGISTERED_CLEAN;
    vbar actual_registered_year / datalabel;
    xaxis label="Year of Registration";
    yaxis label="Number of Cars";
    title "Bar Chart of Registered Years";
run;

/*STEP 3: engine_capacity*/
/*Cleaning*/
data carsdata.engine_clean;
    set carsdata.car;

    length engine_cc 8 status $12;

    if not missing(engine_capacity) then do;
        temp_engine = compress(engine_capacity, , 'kd');
        engine_cc = input(temp_engine, best32.);
        status = 'Valid';
    end;
    else do;
        engine_cc = .;
        status = 'Missing';
    end;

    drop temp_engine;
run;

/*Categorize*/
data carsdata.engine_binned;
    set carsdata.engine_clean;

    length engine_bin $20;
    length sort_order 8;

    if not missing(engine_cc) then do;
        if engine_cc < 800 then do;
            engine_bin = '< 800cc'; sort_order = 1;
        end;
        else if engine_cc < 1000 then do;
            engine_bin = '800–999cc'; sort_order = 2;
        end;
        else if engine_cc < 1300 then do;
            engine_bin = '1000–1299cc'; sort_order = 3;
        end;
        else if engine_cc < 1600 then do;
            engine_bin = '1300–1599cc'; sort_order = 4;
        end;
        else if engine_cc < 2000 then do;
            engine_bin = '1600–1999cc'; sort_order = 5;
        end;
        else if engine_cc < 3000 then do;
            engine_bin = '2000–2999cc'; sort_order = 6;
        end;
        else do;
            engine_bin = '3000cc and above'; sort_order = 7;
        end;
    end;
    else do;
        engine_bin = 'Missing'; sort_order = 8;
    end;
run;

proc contents data = carsdata.engine_binned;

proc sql;
    create table carsdata.engine_summary as
    select sort_order, engine_bin, count(*) as car_count
    from carsdata.engine_binned
    group by sort_order, engine_bin
    order by sort_order;
quit;

/*Descriptive Statistics*/
proc means data=carsdata.engine_clean n mean median min max std nmiss;
    var engine_cc;
    title "Descriptive Statistics for Engine Capacity (cc)";
run;

proc univariate data=carsdata.engine_clean;
    var engine_cc;
    title "Descriptive Statistics and IQR for Engine Capacity";
run;

proc univariate data=carsdata.engine_clean noprint;
    var engine_cc;
    output out=percentiles_summary
        pctlpts = 0 25 50 75 100
        pctlpre = P_;
run;

proc print data=percentiles_summary;
    title "Selected Percentiles (0th, 25th, 50th, 75th, 100th) of Engine Capacity";
run;


/*Bar Chart */
proc sgplot data=carsdata.engine_summary;
    title "Engine Capacity Distribution";
    vbarparm category=engine_bin response=car_count / datalabel;
    xaxis discreteorder=data label="Engine Capacity Range";
    yaxis label="Number of Cars";
run;

proc gchart data=engine_status_count;
    pie status / sumvar=count
                 type=sum
                 slice=outside
                 value=inside
                 percent=arrow
                 coutline=black;
    title "Pie Chart: Valid vs Missing Engine Capacity";
run;
quit;

/* Boxplot to detect outliers */
proc sgplot data=carsdata.engine_clean;
    where not missing(engine_cc);
    vbox engine_cc /
        fillattrs=(color=lightblue)
        lineattrs=(color=navy);
    yaxis label="Engine Capacity (cc)";
    title "Boxplot: Outlier Detection for Engine Capacity";
run;

/* STEP 4 */
/* Create frequency count for insurance values including missing*/
proc freq data=carsdata.car noprint;
    tables insurance / missing out=insurance_status_count;
run;

proc freq data=carsdata.car;
    tables insurance / missing nocum nopercent;
    title "Frequency Distribution of Insurance Types";
run;

/*Pie Chart */
proc gchart data=insurance_status_count;
    pie insurance / sumvar=count
                    type=sum
                    slice=outside
                    value=inside
                    percent=arrow
                    coutline=black;
    title "Pie Chart: Distribution of Insurance Types";
run;
quit;

/* STEP 5*/
/* Create frequency count for transmission type */
proc freq data=carsdata.car;
    tables transmission_type / nocum nopercent;
    title "Transmission Type Frequency Table";
run;

proc template;
    define statgraph transmission_type_pie;
        begingraph;
            entrytitle "Pie Chart of Transmission Types";
            layout region;
                piechart category=transmission_type response=count /
                    datalabellocation=outside
                    datalabelcontent=all;
            endlayout;
        endgraph;
    end;
run;

proc sgrender data=trans_count template=transmission_type_pie;
run;

/* STEP 6: kms_driven */
/* Cleaning */
data carsdata.kms_clean;
    set carsdata.car;

    length kms_numeric 8;

    /* Step 1: Remove all non-digit characters */
    cleaned_kms = prxchange('s/[^0-9]//o', -1, kms_driven);

    /* Step 2: Convert to numeric if cleaned value is not missing */
    if not missing(cleaned_kms) then
        kms_numeric = input(cleaned_kms, best32.);
    else
        kms_numeric = .;

    drop cleaned_kms;
run;

/*Descriptive Statistics*/
proc means data=carsdata.kms_clean n mean median min max std nmiss;
    var kms_numeric;
    title "Descriptive Statistics for KMS Driven";
run;

/* Binning */
data carsdata.kms_binned;
    set carsdata.kms_clean;

    length kms_range $20;
    length sort_order 8;

    if not missing(kms_numeric) then do;
        if kms_numeric < 10000 then do;
            kms_range = '< 10,000'; sort_order = 1;
        end;
        else if kms_numeric < 20000 then do;
            kms_range = '10,000–19,999'; sort_order = 2;
        end;
        else if kms_numeric < 50000 then do;
            kms_range = '20,000–49,999'; sort_order = 3;
        end;
        else if kms_numeric < 100000 then do;
            kms_range = '50,000–99,999'; sort_order = 4;
        end;
        else if kms_numeric < 150000 then do;
            kms_range = '100,000–149,999'; sort_order = 5;
        end;
        else if kms_numeric < 200000 then do;
            kms_range = '150,000–199,999'; sort_order = 6;
        end;
        else do;
            kms_range = '200,000 and above'; sort_order = 7;
        end;
    end;
    else do;
        kms_range = 'Missing'; sort_order = 8;
    end;
run;

/* Summary Table */
proc sql;
    create table carsdata.kms_summary as
    select sort_order, kms_range, count(*) as car_count
    from carsdata.kms_binned
    group by sort_order, kms_range
    order by sort_order;
quit;

/* Bar Chart */
proc sgplot data=carsdata.kms_summary;
    title "KMS Driven Distribution";
    vbarparm category=kms_range response=car_count / datalabel;
    xaxis discreteorder=data label="KMS Driven Range";
    yaxis label="Number of Cars";
run;

/* Detecting Outliers */
/* Boxplot */
proc sgplot data=carsdata.kms_clean;
    title "Boxplot of KMS Driven";
    vbox kms_numeric / datalabel=kms_numeric;
    yaxis label="Kilometers Driven";
run;

/*Scatter Plot*/
data carsdata.kms_clean_indexed;
    set carsdata.kms_clean;
    obs_num = _N_;
run;

proc means data=carsdata.kms_clean_indexed noprint;
    var kms_numeric;
    output out=mean_kms mean=mean_kms;
run;

data _null_;
    set mean_kms;
    call symputx('mean_kms', mean_kms);  /* Store mean value in macro variable */
run;

proc sgplot data=carsdata.kms_clean_indexed;
    title "Scatter Plot of KMS Driven";

    scatter x=obs_num y=kms_numeric / 
        markerattrs=(symbol=CircleFilled color=blue);

    refline &mean_kms / axis=y lineattrs=(color=red thickness=2) label="Mean";
    
    xaxis label="Observation Number";
    yaxis label="Kilometers Driven";
run;

/* STEP 7: owner_type */
/* Frequency count (descriptive statistics) */
proc freq data=carsdata.car;
    tables owner_type / nocum nopercent;
    title "Frequency Distribution of Owner Type";
run;

proc sql;
    create table carsdata.owner_summary as
    select owner_type, count(*) as count
    from carsdata.car
    group by owner_type;
quit;

proc gchart data=carsdata.owner_summary;
    pie owner_type / sumvar=count
                    type=sum
                    slice=outside
                    value=inside
                    percent=arrow
                    coutline=black;
    title "Pie Chart: Owner Type Distribution";
run;
quit;

/* STEP 8: fuel_type */
/* Frequency count (descriptive statistics) */
proc freq data=carsdata.car;
    tables fuel_type / nocum nopercent;
    title "Frequency Distribution of Fuel Type";
run;

proc sql;
    create table carsdata.fuel_summary as
    select fuel_type, count(*) as count
    from carsdata.car
    group by fuel_type;
quit;

proc gchart data=carsdata.fuel_summary;
    pie fuel_type / sumvar=count
                    type=sum
                    slice=outside
                    value=inside
                    percent=arrow
                    coutline=black;
    title "Pie Chart: Fuel Type Distribution";
run;
quit;

/*STEP 9: max_power*/
/* Cleaning */
data carsdata.power_clean;
    set carsdata.car;

    length max_power_numeric 8 status $10;

    if not missing(max_power) then do;
        cleaned_power = compress(max_power, , 'kd'); /* Remove non-digits, dot retained */
        max_power_numeric = input(cleaned_power, best32.);
        status = 'Valid';
    end;
    else do;
        max_power_numeric = .;
        status = 'Missing';
    end;

    drop cleaned_power;
run;

/*Descriptive Statistics */
proc means data=carsdata.power_clean n mean median min max std nmiss;
    var max_power_numeric;
    title "Descriptive Statistics for Max Power";
run;

proc univariate data=carsdata.power_clean;
    var max_power_numeric;
    title "Univariate Statistics for Max Power";
run;

proc univariate data=carsdata.power_clean noprint;
    var max_power_numeric;
    output out=percentiles_summary
        pctlpts = 0 25 50 75 100
        pctlpre = P_;
run;

proc print data=percentiles_summary;
    title "Selected Percentiles (0th, 25th, 50th, 75th, 100th) of Engine Capacity";
run;

/*Binning */
data carsdata.power_binned;
    set carsdata.power_clean;

    length power_bin $20;
    length sort_order 8;

    if not missing(max_power_numeric) then do;
        if max_power_numeric < 50 then do;
            power_bin = '< 50 bhp'; sort_order = 1;
        end;
        else if max_power_numeric < 75 then do;
            power_bin = '50–74 bhp'; sort_order = 2;
        end;
        else if max_power_numeric < 100 then do;
            power_bin = '75–99 bhp'; sort_order = 3;
        end;
        else if max_power_numeric < 150 then do;
            power_bin = '100–149 bhp'; sort_order = 4;
        end;
        else if max_power_numeric < 200 then do;
            power_bin = '150–199 bhp'; sort_order = 5;
        end;
        else do;
            power_bin = '200 bhp and above'; sort_order = 6;
        end;
    end;
    else do;
        power_bin = 'Missing'; sort_order = 7;
    end;
run;

proc sql;
    create table carsdata.power_summary as
    select sort_order, power_bin, count(*) as car_count
    from carsdata.power_binned
    group by sort_order, power_bin
    order by sort_order;
quit;

proc sgplot data=carsdata.power_summary;
    title "Max Power Distribution";
    vbarparm category=power_bin response=car_count / datalabel;
    xaxis discreteorder=data label="Max Power Range";
    yaxis label="Number of Cars";
run;

proc sgplot data=carsdata.power_clean;
    title "Boxplot of Max Power";
    vbox max_power_numeric / datalabel max_power_numeric;
    yaxis label="Max Power (bhp)";
run;

/*Outliers */
proc means data=carsdata.power_indexed noprint;
    var max_power_numeric;
    output out=power_stats mean=mean_bhp;
run;

data _null_;
    set power_stats;
    call symputx('mean_bhp', mean_bhp);
run;

proc sgplot data=carsdata.power_indexed;
    title "Scatter Plot of Max Power with Mean Line";
    scatter x=obs_id y=max_power_numeric /
        markerattrs=(symbol=circlefilled color=blue size=4)
        transparency=0.3;
    refline &mean_bhp / axis=y lineattrs=(color=red thickness=2)
        label="Mean Max Power";
    xaxis label="Car Index (Observation Number)";
    yaxis label="Max Power (bhp)";
run;


/* STEP 10: seats */
/* Cleaning */
data carsdata.seats_clean;
    set carsdata.car;

    length seats_numeric 8 status $10;

    if not missing(seats) then do;
        seats_numeric = input(seats, best32.);
        status = 'Valid';
    end;
    else do;
        seats_numeric = .;
        status = 'Missing';
    end;
run;

/* Descriptive Statistics */
proc means data=carsdata.seats_clean n mean median min max std nmiss;
    var seats_numeric;
    title "Descriptive Statistics for Number of Seats";
run;


/* Mode (Most common number of seats) */
proc freq data=carsdata.seats_clean;
    tables seats_numeric / nocum nopercent;
    title "Frequency of Number of Seats";
run;

/* Bar Chart: Distribution of Seat Counts */
/* Count the number of each seat value and calculate percentage */
proc freq data=carsdata.seats_clean noprint;
    where not missing(seats_numeric);
    tables seats_numeric / out=seats_count;
run;

/* Frequency count of each seat value */
proc freq data=carsdata.seats_clean noprint;
    where not missing(seats_numeric);
    tables seats_numeric / out=seats_count;
run;

/* Bar chart showing the count of cars per seat number */
proc sgplot data=seats_count;
    vbar seats_numeric / response=count 
                        datalabel 
                        datalabelattrs=(size=10 weight=bold);
    xaxis label="Number of Seats";
    yaxis label="Number of Cars" values=(0 to 18000 by 2000);
    title "Distribution of Cars by Number of Seats";
run;

/*Boxplot*/
proc sgplot data=carsdata.seats_clean;
    title "Boxplot: Outlier Detection for Seats";
    vbox seats / fillattrs=(color=lightblue) lineattrs=(color=navy);
    yaxis label="Number of Seats";
run;



/* STEP 11: Mileage - Corrected Version */

/* Cleaning the mileage column - preserving decimals */
data carsdata.mileage_clean;
    set carsdata.car;

    length mileage_numeric 8 status $10;

    if not missing(mileage) then do;
        /* Keep digits and decimal point only */
        cleaned_mileage = prxchange('s/[^0-9.]//', -1, mileage);
        mileage_numeric = input(cleaned_mileage, best32.);
        status = 'Valid';
    end;
    else do;
        mileage_numeric = .;
        status = 'Missing';
    end;

    drop cleaned_mileage;
run;

/* Descriptive statistics */
proc means data=carsdata.mileage_clean n mean median min max std nmiss;
    var mileage_numeric;
    title "Descriptive Statistics for Mileage";
run;

/* Descriptive Statistics + Percentiles for Mileage */
proc univariate data=carsdata.mileage_clean;
    var mileage_numeric;
    title "Descriptive Statistics and Percentiles for Mileage";
run;

/* Extract 0th, 25th, 50th, 75th, and 100th percentiles for mileage */
proc univariate data=carsdata.mileage_clean noprint;
    var mileage_numeric;
    output out=mileage_percentiles
        pctlpts = 0 25 50 75 100
        pctlpre = P_;
run;

/* Display the percentile summary */
proc print data=mileage_percentiles;
    title "Selected Percentiles (0th, 25th, 50th, 75th, 100th) of Mileage";
run;

/* Bin mileage into ranges with proper ordering */
data carsdata.mileage_binned;
    set carsdata.mileage_clean;

    length mileage_bin $20;
    length sort_order 8;

    if not missing(mileage_numeric) then do;
        if mileage_numeric < 10 then do;
            mileage_bin = '< 10 km/l'; sort_order = 1;
        end;
        else if mileage_numeric < 15 then do;
            mileage_bin = '10–14.9 km/l'; sort_order = 2;
        end;
        else if mileage_numeric < 20 then do;
            mileage_bin = '15–19.9 km/l'; sort_order = 3;
        end;
        else if mileage_numeric < 25 then do;
            mileage_bin = '20–24.9 km/l'; sort_order = 4;
        end;
        else do;
            mileage_bin = '> 25+ km/l'; sort_order = 5;
        end;
    end;
    else do;
        mileage_bin = 'Missing'; sort_order = 6;
    end;
run;

/* Create summary data for the chart */
proc sql;
    create table carsdata.mileage_summary as
    select 
        mileage_bin,
        sort_order,
        count(*) as car_count
    from carsdata.mileage_binned
    group by mileage_bin, sort_order
    order by sort_order;
quit;


/* Bar chart to show number of cars per mileage range */
proc sgplot data=carsdata.mileage_summary;
    title "Mileage Distribution";
    vbarparm category=mileage_bin response=car_count / datalabel;
    xaxis discreteorder=data label="Mileage Range (km)";
    yaxis label="Number of Cars";
run;

/*Scatter Plot */
/* STEP 1: Calculate Mean Mileage */
proc means data=carsdata.mileage_clean mean noprint;
    var mileage_numeric;
    output out=mileage_stats mean=mean_mileage;
run;

data _null_;
    set mileage_stats;
    call symputx('mean_mileage', mean_mileage); /* Save mean as macro variable */
run;

/* STEP 2: Create Indexed Dataset for Scatter Plot */
data carsdata.mileage_indexed;
    set carsdata.mileage_clean;
    rownum + 1; /* Create index for x-axis */
run;

/* STEP 3: Scatter Plot with Mean Line */
proc sgplot data=carsdata.mileage_indexed;
    title "Scatter Plot of Mileage Values with Mean Line";
    scatter x=rownum y=mileage_numeric / 
        markerattrs=(symbol=circlefilled color=blue size=6);
    refline &mean_mileage / 
        lineattrs=(color=red thickness=2 pattern=solid) 
        label="Mean Mileage";
    xaxis label="Row Number (Car Index)";
    yaxis label="Mileage (km/l)";
run;



/* STEP 12: body_type */
/* Frequency Table for Body Type */
proc freq data=carsdata.bodytype_clean;
    tables body_type_cleaned / nocum nopercent;
    title "Frequency of Body Type";
run;

/* Pie Chart for Body Type */
proc gchart data=bodytype_counts;
    pie body_type_cleaned / sumvar=count
                           type=sum
                           slice=outside
                           value=inside
                           percent=arrow
                           coutline=black;
    title "Pie Chart: Distribution of Body Type";
run;
quit;


/* STEP 13: body_type */
/* Cleaning */
data carsdata.bodytype_clean;
    set carsdata.car;

    length body_type_cleaned $50 status $10;

    if not missing(body_type) then do;
        body_type_cleaned = strip(body_type);
        status = 'Valid';
    end;
    else do;
        body_type_cleaned = '';
        status = 'Missing';
    end;
run;

/* Frequency Table for Body Type */
proc freq data=carsdata.bodytype_clean;
    tables body_type_cleaned / nocum nopercent;
    title "Frequency of Body Type";
run;

/* Pie Chart for Body Type */
proc freq data=carsdata.bodytype_clean noprint;
    where not missing(body_type_cleaned);
    tables body_type_cleaned / out=bodytype_counts;
run;

proc gchart data=bodytype_counts;
    pie body_type_cleaned / sumvar=count
                           type=sum
                           slice=outside
                           value=inside
                           percent=arrow
                           coutline=black;
    title "Pie Chart: Distribution of Body Type";
run;
quit;


/* STEP 14: City - Cleaning */
data carsdata.city_clean;
    set carsdata.car;

    length city_cleaned $100 status $10;

    if not missing(city) then do;
        city_cleaned = strip(city);
        status = 'Valid';
    end;
    else do;
        city_cleaned = 'Missing';
        status = 'Missing';
    end;
run;

/* Frequency Table for City */
proc freq data=carsdata.city_clean;
    tables city_cleaned / nocum nopercent;
    title "Frequency of City";
run;

/* Summary Table: Count of Cars per City */
proc sql;
    create table all_cities as
    select city_cleaned, count(*) as car_count
    from carsdata.city_clean
    group by city_cleaned;
quit;

/* Sort cities by car_count descending for ordered bar chart */
proc sort data=all_cities out=all_cities_sorted;
    by descending car_count;
run;

/* Bar Chart for All Cities (Ordered from Highest to Lowest) */
proc sgplot data=all_cities_sorted;
    vbar city_cleaned / response=car_count datalabel;
    xaxis label="City" discreteorder=data fitpolicy=thin;
    yaxis label="Number of Cars";
    title "All Cities by Car Count (Highest to Lowest)";
run;

























