/* ============================================================================
   STEP 0: Import raw dataset to CARSDATA library with full string formatting
   ============================================================================ */
libname carsdata "/home/u64178394/DataManagement";

proc import datafile="/home/u64178394/DataManagement/car_resale_prices.csv"
    out=carsdata.raw_import_base
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=MAX;
run;

proc print data=carsdata.raw_import_base (obs=10);
    title "STEP 0: Raw Imported Dataset (Uncleaned)";
run;


/* ============================================================================
   STEP 1: Drop irrelevant column 'VAR1'
   ============================================================================ */
data carsdata.cleaned_step1_dropped_var1;
    set carsdata.raw_import_base;
    drop VAR1;
run;

proc print data=carsdata.cleaned_step1_dropped_var1 (obs=10);
    title "STEP 1: Dataset After Dropping VAR1 Column";
run;


/* ============================================================================
   STEP 2: Remove exact duplicate rows
   ============================================================================ */
proc sort data=carsdata.cleaned_step1_dropped_var1 
          noduprecs 
          out=carsdata.cleaned_step2_no_duplicates 
          dupout=carsdata.cleaned_step2_duplicates_only;
    by _all_;
run;

proc print data=carsdata.cleaned_step2_duplicates_only;
    title "STEP 2: Duplicate Rows Removed";
run;

proc print data=carsdata.cleaned_step2_no_duplicates (obs=20);
    title "STEP 2: Unique Records Only";
run;


/* ============================================================================
   STEP 3A: Clean and normalize 'registered_year' column and extract fallback from 'full_name'
   ============================================================================ */
proc import datafile="/home/u64178394/DataManagement/car_resale_prices.csv"
    out=carsdata.interim_reimport_for_year
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=MAX;
run;

proc print data=carsdata.interim_reimport_for_year (obs=20);
    var full_name registered_year;
    title "Re-imported Registered Year Column (Text)";
run;

data carsdata.cleaned_step3_year_normalized;
    set carsdata.interim_reimport_for_year;
    length year_text $4;

    if index(registered_year, '/') > 0 then do;
        date_val = input(registered_year, anydtdte.);
        registered_year_cleaned = year(date_val);
    end;
    else if prxmatch("/^[A-Za-z]{3,9} [0-9]{4}$/", registered_year) then do;
        date_val = input(registered_year, monyy7.);
        registered_year_cleaned = year(date_val);
    end;
    else if length(strip(registered_year)) = 4 and notdigit(registered_year) = 0 then do;
        registered_year_cleaned = input(registered_year, 4.);
    end;
    else if not missing(full_name) and notdigit(scan(full_name, 1, ' ')) = 0 then do;
        year_text = scan(full_name, 1, ' ');
        registered_year_cleaned = input(year_text, 4.);
    end;
    else registered_year_cleaned = .;

    drop date_val year_text registered_year;
    rename registered_year_cleaned = registered_year;
run;

proc print data=carsdata.cleaned_step3_year_normalized (obs=20);
    var full_name registered_year;
    title "Cleaned Registered Year from Text or Fallback";
run;


/* ============================================================================
   STEP 3B: Fill missing registered_years explicitly from full_name
   ============================================================================ */
data carsdata.cleaned_step3_year_filled;
    set carsdata.cleaned_step3_year_normalized;
    length year_token $4;
    retain year_final;

    if missing(registered_year) then do;
        year_token = scan(full_name, 1, ' ');
        if lengthn(year_token) = 4 and notdigit(year_token) = 0 then
            year_final = input(year_token, 4.);
        else
            year_final = .;
    end;
    else year_final = registered_year;

    drop registered_year year_token;
    rename year_final = registered_year;
run;

proc sql;
    select count(*) as missing_after_fill
    from carsdata.cleaned_step3_year_filled
    where missing(registered_year);
quit;

proc freq data=carsdata.cleaned_step3_year_filled;
    tables registered_year / nocum;
    title "✅ Frequency of Registered Year After Fill";
run;

proc print data=carsdata.cleaned_step3_year_filled (obs=30);
    var full_name registered_year;
    title "STEP 3B: Registered Year After Fill";
run;


/* ============================================================================
   STEP 3C: Merge year info with cleaned dataset using row_id alignment
   ============================================================================ */
proc sort data=carsdata.cleaned_step2_no_duplicates out=carsdata.sorted_step3_base;
    by full_name;
run;

proc sort data=carsdata.cleaned_step3_year_filled out=carsdata.sorted_step3_years;
    by full_name;
run;

data carsdata.sorted_step3_base_with_id;
    set carsdata.sorted_step3_base;
    row_id = _N_;
run;

data carsdata.sorted_step3_years_with_id;
    set carsdata.sorted_step3_years;
    row_id = _N_;
run;

proc sql;
    create table carsdata.processed_step3_combined as
    select 
        a.*, 
        b.registered_year as year_merged
    from 
        carsdata.sorted_step3_base_with_id as a
    left join 
        carsdata.sorted_step3_years_with_id as b
    on 
        a.row_id = b.row_id;
quit;

data carsdata.step3_final_aligned_data;
    set carsdata.processed_step3_combined;
    drop row_id registered_year;
run;

proc print data=carsdata.step3_final_aligned_data (obs=20);
    var full_name resale_price year_merged;
    title "✅ Final Aligned Dataset (Step 3)";
run;

proc sql;
    select count(*) as final_missing_years
    from carsdata.step3_final_aligned_data
    where missing(year_merged);
quit;

proc print data=carsdata.step3_final_aligned_data (obs=1000);
    title "✅ Preview of Final Step 3 Dataset (Ready for Step 4)";
run;

/* ============================================================================
   STEP 4: Recheck for Duplicate Rows After Cleaning Registered Year
   Purpose: Ensure final dataset does not contain duplicate listings post-merge
   Input : carsdata.step3_final_aligned_data
   Outputs:
     - carsdata.step4_duplicates_found         → All duplicated rows
     - carsdata.step4_clean_no_duplicates      → Cleaned dataset without duplicates
     - carsdata.step4_final_deduplicated       → Final version for next step
   ============================================================================ */

/* Step 4A: Identify and isolate duplicate rows after year merge */
proc sort data=carsdata.step3_final_aligned_data 
          dupout=carsdata.step4_duplicates_found   /* Saves duplicates here */
          noduprecs 
          out=carsdata.step4_clean_no_duplicates;  /* Saves unique rows here */
    by _all_;
run;

/* Step 4B: Count how many duplicate rows were found */
proc sql;
    select count(*) as num_duplicates
    from carsdata.step4_duplicates_found;
quit;

/* Step 4C: Create a new dataset without duplicates for use in next steps */
proc sort data=carsdata.step3_final_aligned_data 
          out=carsdata.step4_final_deduplicated 
          noduprecs;
    by _all_;
run;

/* Step 4D: Preview the final clean dataset */
proc print data=carsdata.step4_final_deduplicated (obs=20);
    title "✅ STEP 4: Final Dataset After Removing Duplicates";
run;

/* ============================================================================
   STEP 5: Parse full_name into brand and model, clean formatting
   Purpose: Remove year prefix from full_name and extract brand/model
   Input : carsdata.step4_final_deduplicated
   Outputs:
     - carsdata.step5_cleaned_fullname        → full_name without year and standardized casing
     - carsdata.step5_fullname_split          → brand and model split into separate columns
     - carsdata.step5_final_column_order      → final reordered dataset (brand/model first)
   ============================================================================ */

/* Step 5A: Remove 4-digit year prefix from full_name and convert to proper case */
data carsdata.step5_cleaned_fullname;
    set carsdata.step4_final_deduplicated;

    /* Remove year prefix (first 5 characters including space) */
    full_name = strip(substr(full_name, 6));

    /* Convert to proper case for better formatting */
    full_name = propcase(full_name);
run;

proc print data=carsdata.step5_cleaned_fullname (obs=10);
    var full_name;
    title "STEP 5A: Full Name Without Year Prefix and Proper Case";
run;


/* Step 5B: Split cleaned full_name into brand and model */
data carsdata.step5_fullname_split;
    set carsdata.step5_cleaned_fullname;

    /* First word is the brand */
    brand = scan(full_name, 1, ' ');

    /* Remaining part is the model */
    model = substr(full_name, length(brand) + 2); /* +2 skips the space after brand */
run;

proc print data=carsdata.step5_fullname_split (obs=10);
    var full_name brand model;
    title "STEP 5B: Brand and Model Extracted from Full Name";
run;


/* Step 5C: Reorder columns and optionally drop original full_name */
data carsdata.step5_final_column_order;
    retain brand model resale_price year_merged engine_capacity insurance transmission_type kms_driven owner_type fuel_type max_power seats mileage body_type city;
    set carsdata.step5_fullname_split;

    drop full_name; /* Drop full_name to reduce redundancy */
run;

proc print data=carsdata.step5_final_column_order (obs=10);
    title "✅ STEP 5C: Final Dataset with Brand & Model First, Full Name Dropped";
run;

/* ============================================================================
   STEP 6: Clean and Standardize 'resale_price' Column
   Purpose : Convert mixed-format price strings into numeric INR values
   Inputs  : carsdata.step5_final_column_order (contains brand, model, etc.)
   Outputs :
     - carsdata.step6_resale_price_cleaned         → price cleaned and converted to numeric
     - carsdata.step6_price_filled_with_median     → missing prices filled using median
   ============================================================================ */

/* Step 6A: Convert '₹ X Lakh' and '₹ XX,XXX' formats into numeric */
data carsdata.step6_resale_price_cleaned;
    set carsdata.step5_final_column_order;

    /* Remove '₹' symbol and leading/trailing spaces */
    temp_price = strip(resale_price);
    temp_price = tranwrd(temp_price, '₹', '');
    temp_price = strip(temp_price);

    /* Case 1: Handle prices like '8.6 Lakh' → convert to 860000 */
    if index(temp_price, 'Lakh') > 0 then do;
        temp_price = tranwrd(temp_price, 'Lakh', '');
        temp_price = strip(temp_price);
        resale_price_num = input(temp_price, ?? best12.) * 100000;
    end;

    /* Case 2: Handle numeric prices like '4,55,000' */
    else do;
        temp_price = compress(temp_price, ',');
        resale_price_num = input(temp_price, ?? best12.);
    end;

    /* Finalize: Replace old resale_price with numeric one */
    drop resale_price temp_price;
    rename resale_price_num = resale_price;
run;

/* Preview cleaned numeric prices */
proc print data=carsdata.step6_resale_price_cleaned (obs=10);
    var brand model resale_price;
    title "STEP 6A: Cleaned Resale Price (Numeric)";
run;


/* Step 6B: Handle missing values in resale_price using median imputation */

/* Calculate median resale_price (excluding missing values) */
proc sql;
    select median(resale_price) into :median_price
    from carsdata.step6_resale_price_cleaned
    where resale_price is not missing;
quit;

/* Fill missing resale_price with median */
data carsdata.step6_price_filled_with_median;
    set carsdata.step6_resale_price_cleaned;

    if missing(resale_price) then resale_price = &median_price;
run;

/* Preview dataset with missing values filled */
proc print data=carsdata.step6_price_filled_with_median (obs=10);
    var brand model resale_price;
    title "STEP 6B: Resale Price with Missing Values Filled (Median = &median_price)";
run;

/* Summary: Count remaining missing values (should be 0) */
proc sql;
    select count(*) as still_missing
    from carsdata.step6_price_filled_with_median
    where missing(resale_price);
quit;

/* ============================================================================
   STEP 7: Clean and Standardize 'engine_capacity' Column
   Purpose : Convert engine capacity from string (e.g., '1197 cc') to numeric in cc,
             and fill missing values with the mean
   Inputs  : carsdata.step6_price_filled_with_median
   Output  : carsdata.step7_engine_capacity_cleaned
   ============================================================================ */

/* Step 7A: Calculate mean of valid engine_capacity values */
proc sql;
    select mean(input(compress(engine_capacity, 'cc '), best12.)) into :mean_engine
    from carsdata.step6_price_filled_with_median
    where engine_capacity is not missing;
quit;

/* Step 7B: Clean text and fill missing values */
data carsdata.step7_engine_capacity_cleaned;
    set carsdata.step6_price_filled_with_median;

    /* Remove 'cc' and convert to numeric */
    engine_capacity_num = input(compress(engine_capacity, 'cc '), ?? best12.);

    /* Fill missing values with the calculated mean */
    if missing(engine_capacity_num) then engine_capacity_num = &mean_engine;

    /* Final structure */
    drop engine_capacity;
    rename engine_capacity_num = engine_capacity;
run;

/* Step 7C: Preview result */
proc print data=carsdata.step7_engine_capacity_cleaned (obs=10);
    var brand model resale_price engine_capacity;
    title "STEP 7: Cleaned Engine Capacity (cc)";
run;

/* Step 7D: Verify no missing values remain */
proc sql;
    select count(*) as missing_engine_capacity
    from carsdata.step7_engine_capacity_cleaned
    where missing(engine_capacity);
quit;

/* ============================================================================
   STEP 8: Clean and Encode 'insurance' Column
   Purpose : Normalize inconsistent values in the 'insurance' column and convert to 
             binary flags for modeling use
   Input   : carsdata.step7_engine_capacity_cleaned
   Output  : carsdata.step8_insurance_encoded
   ============================================================================ */

/* Step 8A: Standardize 'insurance' values to clean consistent categories */
data carsdata.step8_insurance_standardized;
    set carsdata.step7_engine_capacity_cleaned;

    /* Normalize text (remove extra spaces and make lowercase) */
    insurance_clean = lowcase(strip(insurance));

    /* Map common variations to main categories */
    if insurance_clean in ("comprehensive", "comp", "comprehen.", "full comp") then
        insurance_clean = "comprehensive";
    else if insurance_clean in ("third party", "third", "thirdparty", "third party insurance") then
        insurance_clean = "third party";
    else insurance_clean = "unknown";  /* Includes blank, NA, or any undefined */
run;

/* Step 8B: One-Hot Encode standardized categories */
data carsdata.step8_insurance_encoded;
    set carsdata.step8_insurance_standardized;

    /* Binary flags for each category */
    is_comprehensive = (insurance_clean = "comprehensive");
    is_third_party   = (insurance_clean = "third party");
    is_unknown       = (insurance_clean = "unknown");

    /* Drop original columns */
    drop insurance insurance_clean;
run;

/* Step 8C: Preview one-hot encoded insurance flags */
proc print data=carsdata.step8_insurance_encoded (obs=20);
    var brand model resale_price engine_capacity kms_driven is_comprehensive is_third_party is_unknown;
    title "STEP 8: Final Cleaned and Encoded Insurance Column";
run;

/* Step 8D: Check category distribution (optional) */
proc freq data=carsdata.step8_insurance_encoded;
    tables is_comprehensive is_third_party is_unknown / nocum;
    title "STEP 8: Distribution of Encoded Insurance Categories";
run;

/* ============================================================================
   STEP 9: Clean and One-Hot Encode 'transmission_type' Column
   Purpose : 
      - Standardize transmission values to either 'manual', 'automatic', or 'unknown'
      - Handle typos and irregular entries using regex
      - Separate truly missing values from ambiguous/unknown ones
      - Apply one-hot encoding for modeling
   Input  : carsdata.step8_insurance_encoded
   Output : carsdata.step9_transmission_cleaned_encoded
   ============================================================================ */

/*Step 9A: Normalize and Encode Transmission Categories*/
data carsdata.step9_trans_cleaned;
    set carsdata.step8_insurance_encoded;

    /* Backup raw column for traceability */
    transmission_raw = transmission_type;

    /* Standardize text */
    transmission_clean = lowcase(striEp(transmission_type));

    /* Handle common typos and abbreviations using regex */
    if prxmatch("/auto|automat|a\b/", transmission_clean) then transmission_clean = "automatic";
    else if prxmatch("/man|manual|m\b/", transmission_clean) then transmission_clean = "manual";

    /* If still unrecognized but not blank, mark as 'unknown' */
    else if not missing(transmission_clean) then transmission_clean = "unknown";

    /* If truly missing (blank or .), track it separately */
    else transmission_clean = "";

    /* One-hot encoding */
    is_manual = (transmission_clean = "manual") * 1;
    is_automatic = (transmission_clean = "automatic") * 1;
    is_unknown_transmission = (transmission_clean = "unknown") * 1;
    is_missing_transmission = (transmission_clean = "") * 1;

    /* Drop intermediate cleaned column */
    drop transmission_type transmission_clean;
run;

/* Step 9B: Preview one-hot encoded values */
proc print data=carsdata.step9_trans_cleaned (obs=20);
    var brand model resale_price engine_capacity kms_driven transmission_raw
        is_manual is_automatic;
    title "STEP 9: One-Hot Encoded Transmission Type";
run;

/* Step 9C: Frequency distribution of original transmission types */
proc freq data=carsdata.step9_trans_cleaned;
    tables transmission_raw / nocum;
    title "STEP 9: Frequency of Transmission Types (Raw)";
run;

/* ============================================================================
   STEP 10: Clean and Impute 'kms_driven' Column
   Purpose : Convert string mileage values to numeric and fill missing values 
             using the median
   Input   : carsdata.step9_trans_cleaned
   Output  : carsdata.step10_kms_driven_imputed
   ============================================================================ */

/* Step 10A: Clean text and convert to numeric */
data carsdata.step10_kms_cleaned;
    set carsdata.step9_trans_cleaned;

    /* Remove commas, 'Kms', 'kms', and spaces */
    kms_clean = compress(kms_driven, ', kmsKMS');
    kms_driven_num = input(kms_clean, ?? best12.);

    drop kms_driven kms_clean;
    rename kms_driven_num = kms_driven;
run;

/* Step 10B: Calculate median kms_driven (excluding missing values) */
proc sql;
    select median(kms_driven) into :median_kms
    from carsdata.step10_kms_cleaned
    where not missing(kms_driven);
quit;

/* Step 10C: Fill missing kms_driven with the median */
data carsdata.step10_kms_driven_imputed;
    set carsdata.step10_kms_cleaned;

    if missing(kms_driven) then kms_driven = &median_kms;
run;

/* Step 10D: Preview result */
proc print data=carsdata.step10_kms_driven_imputed (obs=20);
    var brand model resale_price kms_driven;
    title "STEP 10: Final Cleaned and Imputed KMS Driven";
run;

/* Step 10E: Final missing check (should be 0) */
proc sql;
    select count(*) as still_missing
    from carsdata.step10_kms_driven_imputed
    where missing(kms_driven);
quit;

/* ============================================================================
   STEP 11: Clean and Ordinal Encode 'owner_type' Column
   Purpose : Standardize ownership labels and encode as ordinal numeric values
             to represent the ownership order. Handles common variations and
             unknowns using pattern matching.
   Input   : carsdata.step10_kms_driven_imputed
   Output  : carsdata.step11_owner_type_encoded
   ============================================================================ */

data carsdata.step11_owner_type_encoded;
    set carsdata.step10_kms_driven_imputed;

    /* Standardize text for consistency */
    owner_clean = lowcase(strip(owner_type));

    /* Ordinal Encoding with regex to match typos or variants */
    if prxmatch("/(first|1st)/", owner_clean) then owner_flag = 1;
    else if prxmatch("/(second|2nd)/", owner_clean) then owner_flag = 2;
    else if prxmatch("/(third|3rd)/", owner_clean) then owner_flag = 3;
    else if prxmatch("/(fourth|4th|above)/", owner_clean) then owner_flag = 4;
    else owner_flag = 0; /* Unknown, missing, or unrecognized */

    /* Drop unused intermediate variables */
    drop owner_type owner_clean;
run;

/* Step 11B: Preview encoded owner type */
proc print data=carsdata.step11_owner_type_encoded (obs=20);
    var brand model owner_flag;
    title "STEP 11: Ordinal Encoded Owner Type (1=First, 2=Second, ...)";
run;

/* Step 11C: Frequency distribution to confirm encoding */
proc freq data=carsdata.step11_owner_type_encoded;
    tables owner_flag / nocum;
    title "STEP 11: Frequency Distribution of Owner Flags";
run;

/* ============================================================================
   STEP 12: Clean and One-Hot Encode 'fuel_type' Column
   Purpose : Normalize known fuel types and encode into binary format for modeling
   Input   : carsdata.step11_owner_type_encoded
   Output  : carsdata.step12_fuel_type_one_hot
   ============================================================================ */

data carsdata.step12_fuel_type_one_hot;
    set carsdata.step11_owner_type_encoded;

    /* Clean and standardize */
    fuel_clean = lowcase(strip(fuel_type));

    

    /* Map to known categories */
    if fuel_clean in ("petrol") then fuel_clean = "petrol";
    else if fuel_clean in ("diesel") then fuel_clean = "diesel";
    else if fuel_clean in ("cng") then fuel_clean = "cng";
    else if fuel_clean in ("lpg") then fuel_clean = "lpg";
    else if fuel_clean in ("electric") then fuel_clean = "electric";
    else fuel_clean = "unknown";

    /* One-hot encoding */
    is_petrol        = (fuel_clean = "petrol");
    is_diesel        = (fuel_clean = "diesel");
    is_cng           = (fuel_clean = "cng");
    is_lpg           = (fuel_clean = "lpg");
    is_electric      = (fuel_clean = "electric");

    drop fuel_type fuel_clean;
run;

/* Step 12B: Preview encoded fuel type */
proc print data=carsdata.step12_fuel_type_one_hot (obs=20);
    var brand model is_petrol is_diesel is_cng is_lpg is_electric;
    title "STEP 12: One-Hot Encoded Fuel Type";
run;

/* Step 12C: Frequency check (optional) */
proc freq data=carsdata.step12_fuel_type_one_hot;
    tables is_petrol is_diesel is_cng is_lpg is_electric / nocum;
    title "STEP 12: Frequency of Fuel Type Flags";
run;

/* ============================================================================
   STEP 13: Clean and Standardize 'max_power' Column
   Purpose : Convert horsepower values to numeric format (remove 'bhp') and
             fill missing values with mean
   Input   : carsdata.step12_fuel_type_one_hot
   Output  : carsdata.step13_max_power_cleaned
   ============================================================================ */

/* STEP 13A - Clean max_power in a temp dataset for calculating mean */
data carsdata.step13_max_power_cleaned;
    set carsdata.step12_fuel_type_one_hot;

    length raw $50 numeric_part $10 unit $5;
    retain "max_power (bhp)"n;

    /* Step 1: Clean and normalize text input */
    raw = lowcase(strip(compress(max_power, '()@,rpm')));

    /* Step 2: Extract the first numeric value (e.g., 85, 110.5) */
    numeric_part = prxchange('s/[^0-9.]*([0-9.]+).*/\1/', -1, raw);
    value_num = input(numeric_part, ?? best12.);

    /* Step 3: Identify unit from text */
    if index(raw, 'bhp') > 0 then unit = 'bhp';
    else if index(raw, 'ps') > 0 then unit = 'ps';
    else if index(raw, 'kw') > 0 then unit = 'kw';
    else unit = '';

    /* Step 4: Convert to unified bhp */
    if unit = 'bhp' then "max_power (bhp)"n = value_num;
    else if unit = 'ps' then "max_power (bhp)"n = value_num * 0.9863;
    else if unit = 'kw' then "max_power (bhp)"n = value_num * 1.341;
    else if unit = '' and not missing(value_num) then "max_power (bhp)"n = value_num;
    else "max_power (bhp)"n = .;

    drop raw numeric_part value_num unit max_power;
run;

/* Step 13B: Clean text and fill missing or invalid values */
proc sql;
    select mean("max_power (bhp)"n) into :mean_power
    from carsdata.step13_max_power_cleaned
    where not missing("max_power (bhp)"n);
quit;

data carsdata.step13_max_power_cleaned;
    set carsdata.step13_max_power_cleaned;

    if missing("max_power (bhp)"n) then "max_power (bhp)"n = &mean_power;
run;

/* Step 13C: Preview cleaned max_power column */
proc print data=carsdata.step13_max_power_cleaned (obs=20);
    var brand model "max_power (bhp)"n;
    title "STEP 13 (Improved): Max Power Converted and Unified to BHP";
run;

/* Step 13D: Verify no missing values */
proc sql;
    select count(*) as missing_max_power
    from carsdata.step13_max_power_cleaned
    where missing("max_power (bhp)"n);
quit;

/* ============================================================================
   STEP 14: Clean and Standardize 'seats' Column
   Purpose : Convert seat values to numeric and fill missing values with 5
   Input   : carsdata.step13_max_power_cleaned
   Output  : carsdata.step14_seats_cleaned
   ============================================================================ */

data carsdata.step14_seats_cleaned;
    set carsdata.step13_max_power_cleaned;

    /* Handle common null strings */
    if lowcase(strip(seats)) in ("na", "null", "n.a.") then seats_clean = "";
    else seats_clean = compress(seats, ' '); /* Remove spaces */

    /* Convert to numeric safely */
    seats_num = input(seats_clean, ?? best12.);

    /* Fill missing values with default 5 */
    if missing(seats_num) then seats_num = 5;

    /* Drop old and rename */
    drop seats seats_clean;
    rename seats_num = seats;
run;

/* STEP 14B: Preview cleaned seats column */
proc print data=carsdata.step14_seats_cleaned (obs=20);
    var brand model seats;
    title "STEP 14: Cleaned Seats Column (Filled with 5 if Missing)";
run;

/* STEP 14C: Verify all values are now present */
proc sql;
    select count(*) as missing_seats
    from carsdata.step14_seats_cleaned
    where missing(seats);
quit;

/* ============================================================================
   STEP 15: Clean and Standardize 'mileage' Column
   Purpose : Extract numeric mileage from strings and fill missing with mean
   Input   : carsdata.step14_seats_cleaned
   Output  : carsdata.step15_mileage_cleaned
   ============================================================================ */

/* Step 15A: Extract numeric mileage safely in a DATA step first */
data carsdata.step15_mileage_temp;
    set carsdata.step14_seats_cleaned;

    length mileage_clean $10;
    retain mileage_num;

    /* Handle missing strings */
    if lowcase(strip(mileage)) in ("na", "n.a.", "null", "--") then mileage_clean = "";

    /* Extract numeric value using REGEX – works for kmpl or km/kg or extra text */
    else mileage_clean = prxchange('s/[^0-9.]*([0-9.]+).*/\1/', -1, strip(mileage));

    /* Convert cleaned string to numeric */
    mileage_num = input(mileage_clean, ?? best12.);
run;

/* Step 15B: Now calculate mean safely using cleaned numeric column */
proc sql;
    select mean(mileage_num) into :mean_mileage
    from carsdata.step15_mileage_temp
    where not missing(mileage_num);
quit;

/* Step 15C: Final dataset with missing mileage filled */
data carsdata.step15_mileage_cleaned;
    set carsdata.step15_mileage_temp;

    if missing(mileage_num) then mileage_num = &mean_mileage;

    drop mileage mileage_clean;
    rename mileage_num = "mileage (kmpl)"n;
run;

/* Step 15D: Preview cleaned mileage */
proc print data=carsdata.step15_mileage_cleaned (obs=10);
    var brand model "mileage (kmpl)"n;
    title "STEP 15: Cleaned Mileage Column (Mean Imputed)";
run;

/* Step 15E: Confirm no missing values remain */
proc sql;
    select count(*) as missing_mileage
    from carsdata.step15_mileage_cleaned
    where missing("mileage (kmpl)"n);
quit;

/* ============================================================================
   STEP 16: Clean and Encode 'body_type' Column
   Purpose : Standardize body type entries and one-hot encode them for modeling
   Input   : carsdata.step15_mileage_cleaned
   Output  : carsdata.step16_body_type_encoded
   ============================================================================ */

/* Step 16A: Clean and Standardize body_type */
data carsdata.step16_body_type_cleaned;
    set carsdata.step15_mileage_cleaned;

    /* Normalize to lowercase and strip spaces */
    body_type_clean = lowcase(strip(body_type));

    /* Handle common inconsistencies */
    if prxmatch("/hatchback|hatch|hatch-back/", body_type_clean) then body_type_clean = "hatchback";
    else if prxmatch("/sedan/", body_type_clean) then body_type_clean = "sedan";
    else if prxmatch("/suv|s\.u\.v/", body_type_clean) then body_type_clean = "suv";
    else if prxmatch("/muv|mpv/", body_type_clean) then body_type_clean = "muv";
    else if prxmatch("/coupe/", body_type_clean) then body_type_clean = "coupe";
    else if prxmatch("/convertible/", body_type_clean) then body_type_clean = "convertible";
    else body_type_clean = "other";

run;

/* Step 16B: One-Hot Encoding for top categories */
data carsdata.step16_body_type_encoded;
    set carsdata.step16_body_type_cleaned;

    is_suv = (body_type_clean = "suv");
    is_sedan = (body_type_clean = "sedan");
    is_hatchback = (body_type_clean = "hatchback");
    is_muv = (body_type_clean = "muv");
    is_coupe = (body_type_clean = "coupe");
    is_convertible = (body_type_clean = "convertible");
    is_other_body = (body_type_clean = "other");

    drop body_type body_type_clean;
run;

/* Step 16C: Preview the cleaned and encoded body type */
proc print data=carsdata.step16_body_type_encoded (obs=20);
    var brand model is_suv is_sedan is_hatchback is_muv is_convertible is_other_body;
    title "STEP 16: One-Hot Encoded Body Type";
run;

/* ============================================================================
   STEP 17: Clean and Encode 'city' Column
   Purpose : Standardize city names, handle typos/missing values, and encode
   Input   : carsdata.step16_body_type_encoded
   Output  : carsdata.step17_city_cleaned_encoded
   ============================================================================ */

/* Step 17A: Clean and standardize city names */
data carsdata.step17_city_cleaned;
    set carsdata.step16_body_type_encoded;

    city_clean = lowcase(strip(city));

    /* Fix common typos */
    if city_clean in ("del hi", "dilli") then city_clean = "delhi";
    else if city_clean in ("mum bai", "bombay") then city_clean = "mumbai";
    else if city_clean in ("banglore", "bengaluru") then city_clean = "bangalore";
    else if missing(city_clean) then city_clean = "unknown";

run;

/* Step 17B: Frequency analysis to decide top N cities */
proc freq data=carsdata.step17_city_cleaned order=freq;
    tables city_clean / nocum;
    title "STEP 17: Frequency of Cleaned City Names";
run;

/* Step 17C: One-hot encode top cities */
data carsdata.step17_city_cleaned_encoded;
    set carsdata.step17_city_cleaned;

    /* Example: top cities based on previous frequency count */
    is_delhi = (city_clean = "delhi");
    is_mumbai = (city_clean = "mumbai");
    is_bangalore = (city_clean = "bangalore");
    is_chennai = (city_clean = "chennai");
    is_hyderabad = (city_clean = "hyderabad");

    is_other_city = not (is_delhi or is_mumbai or is_bangalore or is_chennai or is_hyderabad);

    drop city city_clean;
run;

/* Step 17D: Preview result */
proc print data=carsdata.step17_city_cleaned_encoded (obs=20);
    var brand model is_delhi is_mumbai is_bangalore is_other_city;
    title "STEP 17: One-Hot Encoded City Column";
run;

/* ============================================================================
   STEP 18: Final Column Reordering to Match Original Dataset Structure
   Purpose : Ensure final dataset matches original column order and naming
   Input   : carsdata.step17_city_cleaned_encoded
   Output  : carsdata.final_preprocessed_car_data
   ============================================================================ */

data carsdata.final_step18_reordered;
    set carsdata.step17_city_cleaned_encoded;

    rename
        year_merged = year
        resale_price = price
        engine_capacity = engine_cc
        "max_power (bhp)"n = power_bhp
        "mileage (kmpl)"n = mileage_kmpl
        owner_flag = owner_number
        kms_driven = mileage_km

        is_comprehensive = insurance_comp
        is_third_party = insurance_tp
        is_unknown = insurance_unk

        is_manual = trans_manual
        is_automatic = trans_auto
        is_missing_transmission = trans_missing

        is_petrol = fuel_petrol
        is_diesel = fuel_diesel
        is_cng = fuel_cng
        is_lpg = fuel_lpg
        is_electric = fuel_electric

        is_suv = body_suv
        is_sedan = body_sedan
        is_hatchback = body_hatchback
        is_muv = body_muv
        is_coupe = body_coupe
        is_convertible = body_convertible
        is_other_body = body_other

        is_delhi = city_delhi
        is_mumbai = city_mumbai
        is_bangalore = city_bangalore
        is_chennai = city_chennai
        is_hyderabad = city_hyderabad
        is_other_city = city_other;

    drop transmission_raw;
run;

/* Step 18B: Preview first 30 records */
proc print data=carsdata.final_step18_reordered (obs=100);
    title "✅ FINAL STEP 18:Cleaned Dataset";
run;

/* Export the pre-processed dataset */
proc export data=carsdata.final_step18_reordered
    outfile="/home/u64178394/DataManagement/final_car_data_cleaned.csv"
    dbms=csv
    replace;
run;
