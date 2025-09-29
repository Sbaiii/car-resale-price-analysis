/* ============================================================================
   1. Display the first 300 rows of the cleaned dataset for verification purposes
   ============================================================================ */
proc print data=carsdata.FINAL_STEP18_REORDERED (obs=300);
    title "Cleaned Dataset";
run;








/* ============================================================================
  2.  Generate descriptive statistics (mean, median, std, etc.) 
   for the selected numeric variables to understand their distribution
   ============================================================================ */

/* Step 1: Simple Random Sampling (10,000 observations) */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs             /* Simple Random Sampling */
    sampsize=10000         /* Sample size: 10,000 */
    seed=123;              /* Fixed seed for reproducibility */
run;

/* Step 2: Descriptive Statistics on the Sample */
proc means data=cars_sample_10k 
    mean median std var min max p25 p75 maxdec=2;
    var 
        price year engine_cc mileage_km owner_number 
        power_bhp seats mileage_kmpl;
    title "Descriptive Statistics for 10,000 Sampled Observations";
run;







/* ============================================================================
   3. BRAND VARIABLE ANALYSIS
   This section focuses on analyzing the 'brand' variable and its related insights.
   ============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Distribution of Car Brands
   Purpose: Visualize how many cars belong to each brand using a vertical bar chart.
---------------------------------------------------------------------------- */
/* Step 1: Simple Random Sample of 10,000 */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Bar Chart of Car Brand Distribution */
proc sgplot data=cars_sample_10k;
    title "Distribution of Car Brands (Sample of 10,000)";
    vbar brand / datalabel categoryorder=respdesc;
run;



/* ----------------------------------------------------------------------------
   <2. Frequency Distribution of Resale Price
   Purpose: Although this directly analyzes 'price', it provides insight into 
   how resale price is distributed across brands, helping assess brand value.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Plot histogram of resale price */
proc sgplot data=cars_sample_10k;
    title "Histogram of Resale Price (Sample of 10,000)";
    histogram price / binwidth=200000 binstart=0 scale=count;
    xaxis label="Resale Price (in units)" grid values=(0 to 3000000 by 200000);
    yaxis label="Frequency" grid;
run;



/* ----------------------------------------------------------------------------
   <3. Value Ranges of Numeric Attributes
   Purpose: View the min and max values of relevant numeric variables that could
   be compared across different brands for more detailed brand-based analysis.
---------------------------------------------------------------------------- */
/* Step 1: Create 10,000-sample */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Run min-max summary on the sample */
proc means data=cars_sample_10k 
    min max maxdec=2;
    var 
        price year engine_cc mileage_km owner_number 
        power_bhp seats mileage_kmpl;
    title "Value Ranges of Numeric Attributes (Sample of 10,000)";
run;




/* ============================================================================
  4. YEAR VARIABLE ANALYSIS
   This section analyzes the manufacturing year of cars (originally 'year_merged').
   ============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Distribution of Car Manufacturing Years
   Purpose: Visualize the number of cars manufactured in each year.
---------------------------------------------------------------------------- */
/* Step 1: Take a random sample of 10,000 rows */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Bar chart showing distribution of car registration years */
proc sgplot data=cars_sample_10k;
    title "Distribution of Year (Sample of 10,000)";
    vbar year / datalabel categoryorder=respasc;
run;



/* ----------------------------------------------------------------------------
   <2A. Frequency Table of Car Manufacturing Years
   Purpose: Display the count of cars for each year without cumulative or percent info.
---------------------------------------------------------------------------- */
/* Step 1: Take a 10,000-observation random sample */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Frequency table for the 'year' variable */
proc freq data=cars_sample_10k;
    tables year / nocum nopercent;
    title "Frequency Table of Year (Sample of 10,000)";
run;



/* ----------------------------------------------------------------------------
   <2B. Create a Binned Year Group Column for Visualization
   Purpose: Group car years into 5-year bins for better comparison in charts.
---------------------------------------------------------------------------- */
/* Step 1: Take a 10,000-row sample */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Create year groupings in 5-year intervals */
data year_binned_sample;
    set cars_sample_10k;
    year_group = put(floor(year / 5) * 5, 4.) || "-" || put(floor(year / 5) * 5 + 4, 4.);
run;


/* ----------------------------------------------------------------------------
   <2C. Visualize Car Counts by 5-Year Bins
   Purpose: Show how car manufacturing is distributed over time ranges.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Create year groups in 5-year bins */
data year_binned_sample;
    set cars_sample_10k;
    year_group = put(floor(year / 5) * 5, 4.) || "-" || put(floor(year / 5) * 5 + 4, 4.);
run;

/* Step 3: Plot distribution of cars by year groups */
proc sgplot data=year_binned_sample;
    title "Distribution of Cars by 5-Year Ranges (Sample of 10,000)";
    vbar year_group / datalabel categoryorder=respasc;
    xaxis label="Year Range (5-Year Bins)" discreteorder=data;
    yaxis label="Frequency" grid;
run;



/* ----------------------------------------------------------------------------
   <3. Minimum and Maximum of Year
   Purpose: Identify the earliest and latest car manufacturing years in the dataset.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Calculate min and max of year */
proc means data=cars_sample_10k
    min max maxdec=0;
    var year;
    title "Value Range of Year (Sample of 10,000)";
run;








/* ============================================================================
   5.ENGINE CAPACITY ANALYSIS
   This section focuses on exploring the distribution and statistics of engine size.
   The original variable 'engine_capacity' is now renamed to 'engine_cc'.
   ============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Distribution: Histogram of Engine Capacity using 200cc bins
   Purpose: Show how engine sizes are distributed across the dataset.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Histogram on sample */
proc sgplot data=cars_sample_10k;
    title "Histogram of Engine Capacity (200cc Bins, Sample of 10,000)";
    histogram engine_cc / binwidth=200 binstart=0 scale=count;
    xaxis label="Engine Capacity (cc)" grid values=(0 to 3000 by 200);
    yaxis label="Frequency" grid;
run;



/* ----------------------------------------------------------------------------
   <2A. Frequency Table (Grouped by 200cc bins)
   Purpose: Categorize engine sizes into 200cc ranges and count frequencies.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Create engine capacity bins */
data engine_binned_sample;
    set cars_sample_10k;
    if engine_cc < 3000 then do;
        bin_start = floor(engine_cc / 200) * 200;
        engine_bin = cats(put(bin_start, 4.), "-", put(bin_start + 199, 4.));
    end;
    else engine_bin = "3000+";
run;

/* Step 3: Frequency table of engine capacity bins */
proc freq data=engine_binned_sample;
    tables engine_bin / nocum;
    title "Frequency Table of Engine Capacity (200cc Bins, Sample of 10,000)";
run;



/* ----------------------------------------------------------------------------
   <2B. Binned Bar Chart of Engine Capacity
   Purpose: Visualize the grouped engine size data with bar heights showing frequency.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Create 200cc bins for engine capacity */
data engine_binned_sample;
    set cars_sample_10k;
    if engine_cc < 3000 then do;
        bin_start = floor(engine_cc / 200) * 200;
        engine_bin = cats(put(bin_start, 4.), "-", put(bin_start + 199, 4.));
    end;
    else engine_bin = "3000+";
run;

/* Step 3: Bar chart for engine capacity bins */
proc sgplot data=engine_binned_sample;
    title "Distribution of Engine Capacity (200cc Bins, Sample of 10,000)";
    vbar engine_bin / datalabel categoryorder=respasc;
    xaxis label="Engine Capacity (cc range)" discreteorder=data;
    yaxis label="Frequency" grid;
run;



/* ----------------------------------------------------------------------------
   <3. Descriptive Statistics and Value Range for Engine Capacity
   Purpose: Show basic statistical summary for engine sizes.
---------------------------------------------------------------------------- */
/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Descriptive statistics for engine_cc */
proc means data=cars_sample_10k
    min max mean median std var p25 p75 maxdec=2;
    var engine_cc;
    title "Value Range and Descriptive Statistics of Engine Capacity (Sample of 10,000)";
run;








/* ============================================================================
   6.INSURANCE VARIABLE ANALYSIS
   One-hot encoded columns: insurance_comp, insurance_tp, insurance_unk
   This section analyzes the type of insurance associated with each car.
   ============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Descriptive Statistics for One-Hot Encoded Insurance Types
   Purpose: Show proportion (mean), variability (std/var), and value ranges 
   for each insurance type using binary (0/1) indicators.
---------------------------------------------------------------------------- */

/* Step 1: Sample 10,000 observations */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k
    method=srs
    sampsize=10000
    seed=123;
run;

/* Step 2: Descriptive stats for insurance one-hot encoded variables */
proc means data=cars_sample_10k
    mean std var min max p25 p75 maxdec=2;
    var insurance_comp insurance_tp insurance_unk;
    title "Descriptive Statistics for Insurance (One-Hot Encoded, Sample of 10,000)";
run;


/* ----------------------------------------------------------------------------
   <2. Total Count of Cars by Insurance Type
   Purpose: Count the number of cars that fall into each insurance category
   by summing the one-hot columns (1 = presence).
---------------------------------------------------------------------------- */
proc means data=cars_sample_10k noprint;
    var insurance_comp insurance_tp insurance_unk;
    output out=insurance_summary_sample (drop=_TYPE_ _FREQ_) sum=;
run;


/* ----------------------------------------------------------------------------
   <3. Transpose Summary Table for Plotting
   Purpose: Reshape the dataset from wide to long format so that each insurance
   type appears as a row for visualization.
---------------------------------------------------------------------------- */
proc transpose data=insurance_summary_sample out=insurance_plot_sample;
    var insurance_comp insurance_tp insurance_unk;
run;


/* ----------------------------------------------------------------------------
   <4. Visualization of Insurance Types
   Purpose: Create a vertical bar chart with colored bars to represent the 
   distribution of different insurance types in the dataset.
---------------------------------------------------------------------------- */
proc sgplot data=insurance_plot_sample;
    title "Distribution of Insurance Types (Sample of 10,000)";
    vbar _NAME_ / response=COL1 datalabel group=_NAME_;
    xaxis label="Insurance Type";
    yaxis label="Number of Cars";
run;


/* ----------------------------------------------------------------------------
   <5. Pie Chart to Show Proportions
   Purpose: Visualize the proportion of each insurance type as a percentage.
---------------------------------------------------------------------------- */
proc gchart data=insurance_plot_sample;
    pie _NAME_ / sumvar=COL1 value=inside percent=inside slice=outside;
    title "Insurance Type Proportions (Pie Chart, Sample of 10,000)";
run;








/* ============================================================================
   7. TRANSMISSION VARIABLE ANALYSIS (SAMPLE OF 10,000)
   One-hot encoded columns: trans_manual, trans_auto
   This section analyzes the types of transmission used in cars.
============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Sample 10,000 Rows from the Dataset
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=cars_sample_10k_trans
    method=srs
    sampsize=10000
    seed=456;
run;


/* ----------------------------------------------------------------------------
   <2. Descriptive Statistics for Transmission Types
   Purpose: Calculate frequency proportions, variance, and range of binary values.
---------------------------------------------------------------------------- */
proc means data=cars_sample_10k_trans 
    mean std var min max p25 p75 maxdec=2;
    var trans_manual trans_auto;
    title "Descriptive Statistics for Transmission Types (Sample of 10,000)";
run;


/* ----------------------------------------------------------------------------
   <3. Total Count of Cars by Transmission Type
   Purpose: Count the number of cars with each transmission type.
---------------------------------------------------------------------------- */
proc means data=cars_sample_10k_trans noprint;
    var trans_manual trans_auto;
    output out=trans_summary_sample (drop=_TYPE_ _FREQ_) sum=;
run;


/* ----------------------------------------------------------------------------
   <4. Transpose the Summary Table for Plotting
   Purpose: Convert from wide to long format for visualization.
---------------------------------------------------------------------------- */
proc transpose data=trans_summary_sample out=trans_plot_sample;
    var trans_manual trans_auto;
run;


/* ----------------------------------------------------------------------------
   <5. Bar Chart: Distribution of Transmission Types
   Purpose: Visualize the count of cars by transmission type with distinct colors.
---------------------------------------------------------------------------- */
proc sgplot data=trans_plot_sample;
    title "Distribution of Transmission Types (Sample of 10,000)";
    vbar _NAME_ / response=COL1 datalabel group=_NAME_;
    xaxis label="Transmission Type";
    yaxis label="Number of Cars";
run;








/* ============================================================================
   8. MILEAGE VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variable: mileage_km
   This section analyzes the mileage distribution of cars in kilometers.
============================================================================ */


/* ----------------------------------------------------------------------------
   <1. Sample 10,000 Rows from the Cleaned Mileage Dataset
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.mileage_cleaned
    out=mileage_sample_10k
    method=srs
    sampsize=10000
    seed=789;
run;


/* ----------------------------------------------------------------------------
   <2. Descriptive Statistics for Mileage
   Purpose: Calculate key statistics including mean, median, min, max, variance,
            standard deviation, and percentiles to understand mileage spread.
---------------------------------------------------------------------------- */
proc means data=mileage_sample_10k 
    mean median std var min max p25 p75 maxdec=2;
    var mileage_km;
    title "Descriptive Statistics for Mileage (in kilometers, Sample of 10,000)";
run;


/* ----------------------------------------------------------------------------
   <3. Histogram with Normal Curve
   Purpose: Visualize the mileage distribution and check for skewness.
---------------------------------------------------------------------------- */
proc sgplot data=mileage_sample_10k;
    title "Mileage Distribution (km, Sample of 10,000)";
    histogram mileage_km / nbins=10 fillattrs=(color=lightblue) outline;
    density mileage_km / type=normal lineattrs=(color=red thickness=2);
    xaxis label="Mileage (in kilometers)";
    yaxis label="Frequency";
run;


/* ----------------------------------------------------------------------------
   <4. Box Plot of Mileage
   Purpose: Visualize mileage distribution, identify outliers, and assess skewness.
---------------------------------------------------------------------------- */
proc sgplot data=mileage_sample_10k;
    title "Box Plot of Mileage (in kilometers, Sample of 10,000)";
    vbox mileage_km / fillattrs=(color=lightblue) lineattrs=(color=black);
    yaxis label="Mileage (km)" grid;
run;








/* ============================================================================
   9. OWNER NUMBER VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variable: owner_number
   This section analyzes how many previous owners each car had.
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=owner_sample_10k
    method=srs
    sampsize=10000
    seed=456;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Get summary statistics to understand the distribution.
---------------------------------------------------------------------------- */
proc means data=owner_sample_10k 
    n mean std min max maxdec=0;
    var owner_number;
    title "Descriptive Statistics for Owner Number (Sample of 10,000)";
run;

/* ----------------------------------------------------------------------------
   <3> Frequency Table
   Purpose: Count how many cars had 0, 1, 2, 3, or 4 previous owners.
---------------------------------------------------------------------------- */
proc freq data=owner_sample_10k;
    tables owner_number / nocum;
    title "Frequency Distribution of Owner Number (Sample of 10,000)";
run;

/* ----------------------------------------------------------------------------
   <4> Bar Chart of Owner Numbers (Sorted & Colorful)
   Purpose: Visualize owner counts in descending order using grouped bars.
---------------------------------------------------------------------------- */

/* Step A: Summarize owner_number counts */
proc sql;
    create table owner_summary_10k as
    select owner_number, count(*) as count
    from owner_sample_10k
    group by owner_number
    order by count desc;
quit;

/* Step B: Plot sorted, colorful bar chart */
proc sgplot data=owner_summary_10k;
    title "Owner Number Distribution (Sorted by Frequency, Sample of 10,000)";
    vbar owner_number / response=count datalabel 
        categoryorder=respdesc 
        group=owner_number groupdisplay=cluster;
    xaxis label="Number of Previous Owners";
    yaxis label="Number of Cars";
run;









/* ============================================================================
   10. FUEL TYPE VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variables: fuel_petrol, fuel_diesel, fuel_cng, fuel_lpg, fuel_electric
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=fuel_sample_10k
    method=srs
    sampsize=10000
    seed=789;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Understand proportions and variation for each fuel type.
---------------------------------------------------------------------------- */
proc means data=fuel_sample_10k 
    mean std min max maxdec=2;
    var fuel_petrol fuel_diesel fuel_cng fuel_lpg fuel_electric;
    title "Descriptive Statistics for Fuel Types (One-Hot Encoded, Sample of 10,000)";
run;

/* ----------------------------------------------------------------------------
   <3> Total Count of Cars by Fuel Type
   Purpose: Summarize how many cars use each fuel type.
---------------------------------------------------------------------------- */
proc means data=fuel_sample_10k noprint;
    var fuel_petrol fuel_diesel fuel_cng fuel_lpg fuel_electric;
    output out=fuel_summary_10k(drop=_TYPE_ _FREQ_) sum=;
run;

/* ----------------------------------------------------------------------------
   <4> Transpose and Label for Plotting
---------------------------------------------------------------------------- */
proc transpose data=fuel_summary_10k out=fuel_plot_10k;
    var fuel_petrol fuel_diesel fuel_cng fuel_lpg fuel_electric;
run;

data fuel_plot_labeled_10k;
    set fuel_plot_10k;
    length fuel_label $15;
    if _NAME_ = "fuel_petrol"   then fuel_label = "Petrol";
    else if _NAME_ = "fuel_diesel"   then fuel_label = "Diesel";
    else if _NAME_ = "fuel_cng"      then fuel_label = "CNG";
    else if _NAME_ = "fuel_lpg"      then fuel_label = "LPG";
    else if _NAME_ = "fuel_electric" then fuel_label = "Electric";
run;

/* ----------------------------------------------------------------------------
   <5> Sort by Count
---------------------------------------------------------------------------- */
proc sort data=fuel_plot_labeled_10k out=fuel_sorted_10k;
    by descending COL1;
run;

/* ----------------------------------------------------------------------------
   <6> Bar Chart: Fuel Type Distribution (Sorted & Colorful)
---------------------------------------------------------------------------- */
proc sgplot data=fuel_sorted_10k;
    title "Fuel Type Distribution (Sorted by Count, Sample of 10,000)";
    vbar fuel_label / response=COL1 datalabel 
        group=fuel_label groupdisplay=cluster 
        categoryorder=respdesc;
    xaxis label="Fuel Type";
    yaxis label="Number of Cars";
run;








/* ============================================================================
   11. POWER VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variable: power_bhp
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=power_sample_10k
    method=srs
    sampsize=10000
    seed=234;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Summarize central tendency, dispersion, and range of power values.
---------------------------------------------------------------------------- */
proc means data=power_sample_10k 
    n mean median std min max p25 p75 qrange maxdec=2;
    var power_bhp;
    title "Descriptive Statistics for Power (BHP) – Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <3> Histogram of Power (Filtered View)
   Purpose: Focus only on reasonable BHP values (e.g., ≤ 500)
---------------------------------------------------------------------------- */
proc sgplot data=power_sample_10k;
    where power_bhp > 0 and power_bhp <= 500;
    title "Distribution of Power (BHP ≤ 500) – Sample of 10,000";
    histogram power_bhp / nbins=30 fillattrs=(color=cx88B0F7);
    density power_bhp / type=normal lineattrs=(color=red thickness=2);
    xaxis label="Brake Horsepower (BHP)" min=0 max=500;
    yaxis label="Frequency";
run;

/* ----------------------------------------------------------------------------
   <4> Boxplot of Power (Filtered View)
   Purpose: Display BHP distribution clearly without distortion by outliers.
---------------------------------------------------------------------------- */
proc sgplot data=power_sample_10k;
    where power_bhp > 0 and power_bhp <= 500;
    title "Boxplot of Power (BHP ≤ 500) – Sample of 10,000";
    vbox power_bhp / 
        fillattrs=(color=lightgreen) 
        lineattrs=(color=darkgreen thickness=2)
        whiskerattrs=(color=gray) 
        outlierattrs=(symbol=CircleFilled color=red);
    yaxis label="Brake Horsepower (BHP)" min=0 max=500;
run;









/* ============================================================================
   12. SEATS VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variable: seats
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=seats_sample_10k
    method=srs
    sampsize=10000
    seed=456;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Show central tendency and spread of seat counts.
---------------------------------------------------------------------------- */
proc means data=seats_sample_10k 
    n mean median std min max maxdec=0;
    var seats;
    title "Descriptive Statistics for Seats – Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <3> Frequency Distribution
   Purpose: Count how many cars have each seat configuration.
---------------------------------------------------------------------------- */
proc freq data=seats_sample_10k;
    tables seats / nocum;
    title "Frequency of Seat Counts – Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <4> Sorted and Colorful Bar Chart
   Purpose: Visualize how many cars have each number of seats.
---------------------------------------------------------------------------- */

/* Step A: Create frequency summary */
proc sql;
    create table seats_summary_sample as
    select seats, count(*) as count
    from seats_sample_10k
    group by seats
    order by count desc;
quit;

/* Step B: Plot with descending order and unique colors */
proc sgplot data=seats_summary_sample;
    title "Seat Count Distribution (Sorted by Frequency) – Sample of 10,000";
    vbar seats / response=count datalabel 
        group=seats groupdisplay=cluster 
        categoryorder=respdesc;
    xaxis label="Number of Seats";
    yaxis label="Number of Cars";
run;

/* ----------------------------------------------------------------------------
   <5> Scatter Plot: Power vs. Seats
   Purpose: Visualize the relationship between engine power and seat count.
---------------------------------------------------------------------------- */
proc sgplot data=seats_sample_10k;
    title "Scatter Plot of Power (BHP) vs Number of Seats – Sample of 10,000";
    scatter x=seats y=power_bhp / markerattrs=(color=blue symbol=CircleFilled size=6);
    xaxis label="Number of Seats";
    yaxis label="Brake Horsepower (BHP)" max=500;
run;







/* ============================================================================
   13. MILEAGE VARIABLE ANALYSIS (SAMPLE OF 10,000)
   Variable: mileage_kmpl
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=mileage_sample_10k
    method=srs
    sampsize=10000
    seed=789;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Understand central tendency, spread, and percentiles.
---------------------------------------------------------------------------- */
proc means data=mileage_sample_10k 
    mean median std min max p25 p75 qrange maxdec=2;
    var mileage_kmpl;
    title "Descriptive Statistics for Mileage (km/l) – Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <3> Histogram of Mileage (Zoomed In)
   Purpose: Visualize the fuel efficiency distribution.
---------------------------------------------------------------------------- */
proc sgplot data=mileage_sample_10k;
    where mileage_kmpl > 0 and mileage_kmpl < 50; /* filter outliers */
    title "Mileage Distribution (km/l) - Zoomed In – Sample of 10,000";
    histogram mileage_kmpl / nbins=25 fillattrs=(color=cx8AC9C0);
    density mileage_kmpl / type=normal lineattrs=(color=red thickness=2);
    xaxis label="Mileage (km/l)";
    yaxis label="Frequency";
run;

/* ----------------------------------------------------------------------------
   <4> Boxplot of Mileage (Filtered)
   Purpose: Identify outliers in fuel efficiency values.
---------------------------------------------------------------------------- */
proc sgplot data=mileage_sample_10k;
    where mileage_kmpl > 0 and mileage_kmpl < 50;
    title "Boxplot of Mileage (km/l) - Filtered View – Sample of 10,000";
    vbox mileage_kmpl /
        fillattrs=(color=lightblue)
        lineattrs=(color=blue thickness=2)
        whiskerattrs=(color=gray)
        outlierattrs=(color=red symbol=CircleFilled);
    yaxis label="Mileage (km/l)";
run;

/* ----------------------------------------------------------------------------
   <5> Scatter Plot - Mileage vs Power
   Purpose: Explore trade-off between fuel efficiency and engine power.
---------------------------------------------------------------------------- */
proc sgplot data=mileage_sample_10k;
    where mileage_kmpl > 0 and mileage_kmpl < 50 and power_bhp < 500;
    title "Scatter Plot of Mileage vs Power – Sample of 10,000";
    scatter x=power_bhp y=mileage_kmpl / markerattrs=(color=green symbol=CircleFilled size=6);
    xaxis label="Power (BHP)";
    yaxis label="Mileage (km/l)";
run;









/* ============================================================================
   14. BODY TYPE VARIABLE ANALYSIS (ONE-HOT ENCODED) – SAMPLE OF 10,000
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Sample 10,000 Rows
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=body_sample_10k
    method=srs
    sampsize=10000
    seed=890;
run;

/* ----------------------------------------------------------------------------
   <2> Descriptive Statistics
   Purpose: Show proportions, variability, and range for each body type.
---------------------------------------------------------------------------- */
proc means data=body_sample_10k 
    mean std var min max p25 p75 maxdec=2;
    var body_suv body_sedan body_hatchback body_muv body_coupe body_convertible body_other;
    title "Descriptive Statistics for Body Type (One-Hot Encoded) – Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <3> Total Count of Cars by Body Type
   Purpose: Aggregate number of cars per body category.
---------------------------------------------------------------------------- */
proc means data=body_sample_10k noprint;
    var body_suv body_sedan body_hatchback body_muv body_coupe body_convertible body_other;
    output out=body_summary_sample(drop=_TYPE_ _FREQ_) sum=;
run;

/* ----------------------------------------------------------------------------
   <4> Transpose and Label for Plotting
   Purpose: Reshape data and assign clean display labels.
---------------------------------------------------------------------------- */
proc transpose data=body_summary_sample out=body_plot_sample;
    var body_suv body_sedan body_hatchback body_muv body_coupe body_convertible body_other;
run;

data body_plot_labeled_sample;
    set body_plot_sample;
    length body_label $15;
    if _NAME_ = "body_suv"         then body_label = "SUV";
    else if _NAME_ = "body_sedan"       then body_label = "Sedan";
    else if _NAME_ = "body_hatchback"   then body_label = "Hatchback";
    else if _NAME_ = "body_muv"         then body_label = "MUV";
    else if _NAME_ = "body_coupe"       then body_label = "Coupe";
    else if _NAME_ = "body_convertible" then body_label = "Convertible";
    else if _NAME_ = "body_other"       then body_label = "Other";
run;

/* ----------------------------------------------------------------------------
   <5> Sort Body Types by Count
   Purpose: Arrange for descending bar chart display.
---------------------------------------------------------------------------- */
proc sort data=body_plot_labeled_sample out=body_plot_sorted_sample;
    by descending COL1;
run;

/* ----------------------------------------------------------------------------
   <6> Bar Chart: Body Type Distribution (Sorted & Colorful)
   Purpose: Visually compare body type popularity with color-coded bars.
---------------------------------------------------------------------------- */
proc sgplot data=body_plot_sorted_sample;
    title "Body Type Distribution (Sorted by Count) – Sample of 10,000";
    vbar body_label / 
        response=COL1 
        datalabel 
        group=body_label 
        groupdisplay=cluster 
        categoryorder=respdesc;
    xaxis label="Body Type";
    yaxis label="Number of Cars";
run;








/* ============================================================================
   15. CITY VARIABLE ANALYSIS (ONE-HOT ENCODED) WITH SAMPLING
   Variables: city_delhi, city_mumbai, city_bangalore, city_chennai, city_hyderabad, city_other
   This section analyzes the distribution of car listings across cities, sampled to 10,000 records.
============================================================================ */

/* ----------------------------------------------------------------------------
   <0> Take a random sample of 10,000 records from the original dataset
---------------------------------------------------------------------------- */
proc surveyselect data=carsdata.FINAL_STEP18_REORDERED
    out=carsdata.SAMPLE_10K
    method=srs           /* Simple random sampling */
    sampsize=10000       /* Sample size */
    seed=12345;          /* Seed for reproducibility */
run;

/* ----------------------------------------------------------------------------
   <1> Descriptive Statistics on Sample
---------------------------------------------------------------------------- */
proc means data=carsdata.SAMPLE_10K
    mean std min max maxdec=2;
    var city_delhi city_mumbai city_bangalore city_chennai city_hyderabad city_other;
    title "Descriptive Statistics for City (One-Hot Encoded) - Sample of 10,000";
run;

/* ----------------------------------------------------------------------------
   <2> Total Listing Counts by City on Sample
---------------------------------------------------------------------------- */
proc means data=carsdata.SAMPLE_10K noprint;
    var city_delhi city_mumbai city_bangalore city_chennai city_hyderabad city_other;
    output out=city_summary(drop=_TYPE_ _FREQ_) sum=;
run;

/* ----------------------------------------------------------------------------
   <3> Transpose and Clean Labels
---------------------------------------------------------------------------- */
proc transpose data=city_summary out=city_plot;
    var city_delhi city_mumbai city_bangalore city_chennai city_hyderabad city_other;
run;

data city_plot_labeled;
    set city_plot;
    length city_label $15;
    if _NAME_ = "city_delhi"      then city_label = "Delhi";
    else if _NAME_ = "city_mumbai"     then city_label = "Mumbai";
    else if _NAME_ = "city_bangalore"  then city_label = "Bangalore";
    else if _NAME_ = "city_chennai"    then city_label = "Chennai";
    else if _NAME_ = "city_hyderabad"  then city_label = "Hyderabad";
    else if _NAME_ = "city_other"      then city_label = "Other";
run;

/* ----------------------------------------------------------------------------
   <4> Sort by Count for Visualization
---------------------------------------------------------------------------- */
proc sort data=city_plot_labeled out=city_sorted;
    by descending COL1;
run;

/* ----------------------------------------------------------------------------
   <5> Bar Chart: Car Listings by City (Sorted & Colorful)
---------------------------------------------------------------------------- */
proc sgplot data=city_sorted;
    title "Car Listings by City (Sorted by Count) - Sample of 10,000";
    vbar city_label / response=COL1 datalabel 
        group=city_label groupdisplay=cluster 
        categoryorder=respdesc;
    xaxis label="City";
    yaxis label="Number of Cars";
run;


















/* ============================================================================
  insight-driven analysis (After EDA)
  --answering specific business questions or company objectives based on car-resale data.
============================================================================ */

/* ----------------------------------------------------------------------------
   <1> Objectives (the question I want trying to answer)
   
   	<1"What is the most common body type in Mumbai?"

	<2"Which fuel type offers the best mileage on average?"

	<3"Are cars with more seats typically more powerful?"

	<4"Does ownership history affect price or mileage?"

	<5"What is the most fuel-efficient configuration (city + fuel type + body type)?"
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
   Q1: What is the most common body type in Mumbai?
---------------------------------------------------------------------------- */
proc sql;
    create table mumbai_bodies as
    select 
        body_suv, body_sedan, body_hatchback, body_muv, body_coupe, body_convertible, body_other
    from carsdata.FINAL_STEP18_REORDERED
    where city_mumbai = 1;
quit;

proc means data=mumbai_bodies sum;
    var body_:;
    title "Body Type Counts in Mumbai";
run;

/* ----------------------------------------------------------------------------
 In Mumbai, the most common body type is likely Hatchback,
 as it has the highest count among vehicles listed in this region.
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
  Q2: Which fuel type offers the best mileage on average?
---------------------------------------------------------------------------- */
proc means data=carsdata.FINAL_STEP18_REORDERED mean maxdec=2;
    class fuel_petrol fuel_diesel fuel_cng fuel_lpg fuel_electric;
    var mileage_kmpl;
    where mileage_kmpl > 0;
    title "Average Mileage by Fuel Type";
run;

/* ----------------------------------------------------------------------------
Among all fuel types, Electric has the highest average mileage at
 approximately XX km/l. This suggests it is the most efficient fuel category.
---------------------------------------------------------------------------- */


/* ----------------------------------------------------------------------------
  Q3: Are cars with more seats typically more powerful?
---------------------------------------------------------------------------- */
proc sgplot data=carsdata.FINAL_STEP18_REORDERED;
    where seats > 0 and power_bhp > 0 and power_bhp < 500;
    title "Scatter Plot of Seats vs Power";
    scatter x=seats y=power_bhp;
run;

proc corr data=carsdata.FINAL_STEP18_REORDERED;
    var seats power_bhp;
    title "Correlation between Seats and Power";
run;

/* ----------------------------------------------------------------------------
There is a moderate positive correlation between 
number of seats and engine power, suggesting that cars with more seats
 tend to have higher horsepower.
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
  Q4: Are cars with more seats typically more powerful?
---------------------------------------------------------------------------- */
proc means data=carsdata.FINAL_STEP18_REORDERED mean std maxdec=2;
    class owner_number;
    var mileage_kmpl power_bhp;
    where mileage_kmpl > 0 and power_bhp < 500;
    title "Mileage and Power by Owner Count";
run;

/* ----------------------------------------------------------------------------
Cars with fewer previous owners (e.g., 0 or 1) tend to have 
slightly higher mileage and better power,suggesting possible 
better maintenance or newer models
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
  Q5: What is the most fuel-efficient configuration (city + fuel type + body)?
---------------------------------------------------------------------------- */
proc sql;
    create table config_efficiency as
    select 
        case 
            when city_delhi = 1 then "Delhi"
            when city_mumbai = 1 then "Mumbai"
            when city_bangalore = 1 then "Bangalore"
            when city_chennai = 1 then "Chennai"
            when city_hyderabad = 1 then "Hyderabad"
            else "Other"
        end as City,
        case 
            when fuel_petrol = 1 then "Petrol"
            when fuel_diesel = 1 then "Diesel"
            when fuel_cng = 1 then "CNG"
            when fuel_lpg = 1 then "LPG"
            when fuel_electric = 1 then "Electric"
        end as Fuel_Type,
        case 
            when body_suv = 1 then "SUV"
            when body_sedan = 1 then "Sedan"
            when body_hatchback = 1 then "Hatchback"
            when body_muv = 1 then "MUV"
            when body_coupe = 1 then "Coupe"
            when body_convertible = 1 then "Convertible"
            else "Other"
        end as Body_Type,
        mileage_kmpl
    from carsdata.FINAL_STEP18_REORDERED
    where mileage_kmpl > 0;
quit;

proc sql;
    select City, Fuel_Type, Body_Type, mean(mileage_kmpl) as Avg_Mileage format=6.2
    from config_efficiency
    group by City, Fuel_Type, Body_Type
    order by Avg_Mileage desc;
quit;
/* ----------------------------------------------------------------------------
There is a weak positive correlation between 
number of seats and engine power, suggesting that cars with more seats
 tend to have higher horsepower.
---------------------------------------------------------------------------- */