<!-- badges: start -->
![R-CMD-check](https://img.shields.io/badge/R%20CMD%20check-Passing-brightgreen.svg)
![Test Coverage](https://img.shields.io/badge/coverage-94%25-brightgreen.svg)
<!-- badges: end -->

# whatsnew

whatsnew is an R package that compares two versions of package and
summarizes the differences.

It can document changes, dependency updates, and function
removals/additions between releases and evaluate an impact analysis when
using a latest version of a package.

It is useful when preparing release notes or migration guides and
document breaking changes clearly (e.g., removed arguments, renamed
functions).

## Installation

From CRAN:

```r
install.packages("whatsnew")
```

From Github:


```r         
devtools::install_github("Sanofi-Public/whatsnew")
```

## Ouput Structure

A typical whatsnew report includes:

**Depends** Changes in the minimum required R version or system
dependencies.

**Imports / Suggests** Modifications in imported or suggested packages.

**Functions**

**Added**: New functions introduced. **Removed**: Functions no longer
available. **Modified**: Functions whose arguments or signatures have
changed.

```         
admiral <- compare("admiral", "1.1.1", "1.2.0")

 Comparison of admiral: 1.2.0 -> 1.1.1 

-- Depends --
  Modified:
     R: >= 4.1 -> >= 4.0 

-- Imports --
  Modified:
     admiraldev: >= 1.2.0 -> >= 1.1.0 

-- Suggests --
  Removed:   withr 

-- Functions --
  Removed:
    - get_joined_sub_data(dataset, dataset_add, by_vars, tmp_obs_nr_var, tmp_obs_nr_left, join_type, first_cond_upper, first_cond_lower, filter_join)
    - derive_vars_cat(dataset, definition, by_vars)
    - extend_condition(cond, var, is)
    - derive_vars_crit_flag(dataset, crit_nr = 1, condition, description, values_yn = FALSE, create_numeric_flag = FALSE)
    - roxygen_save_memory()
    - transform_range(source, source_range, target_range, flip_direction = FALSE, outside_range = NA)
  Modified:
    * set_admiral_options
      - 1.2.0: (subject_keys, signif_digits, save_memory)
      + 1.1.1: (subject_keys, signif_digits)
    * consolidate_metadata
      - 1.2.0: (datasets, key_vars, source_var, check_vars = warning, check_type = error)
      + 1.1.1: (datasets, key_vars, source_var, check_vars = warning, check_keys, check_type = error)
    * create_single_dose_dataset
      - 1.2.0: (dataset, dose_freq, start_date, start_datetime, end_date, end_datetime, lookup_table, lookup_column, nominal_time, c("keep_source_vars = expr_c(get_admiral_option(\"subject_keys\"), dose_freq, start_date, ", "keep_source_vars =     start_datetime, end_date, end_datetime)"))
      + 1.1.1: (dataset, dose_freq, start_date, start_datetime, end_date, end_datetime, lookup_table, lookup_column, nominal_time, c("keep_source_vars = expr_c(exprs(USUBJID), dose_freq, start_date, start_datetime, ", "keep_source_vars =     end_date, end_datetime)"))
    * derive_extreme_event
      - 1.2.0: (dataset, by_vars, events, tmp_event_nr_var, order, mode, source_datasets, check_type = warning, set_values_to, keep_source_vars = exprs(everything()))
      + 1.1.1: (dataset, by_vars, events, tmp_event_nr_var, order, mode, source_datasets, ignore_event_order, check_type = warning, set_values_to, keep_source_vars = exprs(everything()))
    * derive_vars_merged
      - 1.2.0: (dataset, dataset_add, by_vars, order, new_vars, filter_add, mode, exist_flag, true_value = Y, false_value = NA, missing_values, check_type = warning, duplicate_msg, relationship)
      + 1.1.1: (dataset, dataset_add, by_vars, order, new_vars, filter_add, mode, match_flag, exist_flag, true_value = Y, false_value = NA, missing_values, check_type = warning, duplicate_msg, relationship)
    * derive_var_merged_summary
      - 1.2.0: (dataset, dataset_add, by_vars, new_vars, filter_add, missing_values)
      + 1.1.1: (dataset, dataset_add, by_vars, new_vars, new_var, filter_add, missing_values, analysis_var, summary_fun)
    * derive_param_exposure
      - 1.2.0: (dataset, dataset_add, by_vars, input_code, filter_add, set_values_to)
      + 1.1.1: (dataset, dataset_add, by_vars, input_code, analysis_var, summary_fun, filter, filter_add, set_values_to)
    * derive_param_tte
      - 1.2.0: (dataset, dataset_adsl, source_datasets, by_vars, start_date, event_conditions, censor_conditions, create_datetime = FALSE, set_values_to, subject_keys = get_admiral_option("subject_keys"), check_type = warning)
      + 1.1.1: (dataset, dataset_adsl, source_datasets, by_vars, start_date, event_conditions, censor_conditions, create_datetime = FALSE, set_values_to, subject_keys = get_admiral_option("subject_keys"))
    * filter_date_sources
      - 1.2.0: (sources, source_datasets, by_vars, create_datetime = FALSE, subject_keys, mode, check_type = none)
      + 1.1.1: (sources, source_datasets, by_vars, create_datetime = FALSE, subject_keys, mode)
    * tte_source
      - 1.2.0: (dataset_name, filter, date, censor = 0, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, censor = 0, set_values_to)
    * event_source
      - 1.2.0: (dataset_name, filter, date, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, set_values_to)
    * censor_source
      - 1.2.0: (dataset_name, filter, date, censor = 1, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, censor = 1, set_values_to)
    * derive_summary_records
      - 1.2.0: (dataset, dataset_add, dataset_ref, by_vars, filter_add, set_values_to, missing_values)
      + 1.1.1: (dataset, dataset_add, dataset_ref, by_vars, filter, filter_add, analysis_var, summary_fun, set_values_to, missing_values)
    * derive_var_atoxgr_dir
      - 1.2.0: (dataset, new_var, tox_description_var, meta_criteria, criteria_direction, abnormal_indicator, get_unit_expr, signif_dig = get_admiral_option("signif_digits"))
      + 1.1.1: (dataset, new_var, tox_description_var, meta_criteria, criteria_direction, get_unit_expr, signif_dig = get_admiral_option("signif_digits"))
    * derive_var_joined_exist_flag
      - 1.2.0: (dataset, dataset_add, by_vars, order, new_var, tmp_obs_nr_var, join_vars, join_type, first_cond_lower, first_cond_upper, filter_add, filter_join, true_value = Y, false_value = NA, check_type = warning)
      + 1.1.1: (dataset, dataset_add, by_vars, order, new_var, tmp_obs_nr_var, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, filter, filter_add, filter_join, true_value = Y, false_value = NA, check_type = warning)
    * derive_vars_atc
      - 1.2.0: (dataset, dataset_facm, by_vars = exprs(!!!get_admiral_option("subject_keys"), CMREFID = FAREFID), id_vars, value_var)
      + 1.1.1: (dataset, dataset_facm, by_vars = exprs(USUBJID, CMREFID = FAREFID), id_vars, value_var)
    * signal_duplicate_records
      - 1.2.0: (dataset, by_vars, c("msg = paste(\"Dataset contains duplicate records\", \"with respect to\", ", "msg =     \"{.var {replace_values_by_names(by_vars)}}\")"), cnd_type = error, class)
      + 1.1.1: (dataset, by_vars, c("msg = paste(\"Dataset contains duplicate records\", \"with respect to\", ", "msg =     \"{.var {replace_values_by_names(by_vars)}}\")"), cnd_type = error)
    * event_joined
      - 1.2.0: (dataset_name, condition, order, join_vars, join_type, first_cond_lower, first_cond_upper, set_values_to, keep_source_vars, description)
      + 1.1.1: (dataset_name, condition, order, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, set_values_to, keep_source_vars, description)
    * filter_joined
      - 1.2.0: (dataset, dataset_add, by_vars, join_vars, join_type, first_cond_lower, first_cond_upper, order, tmp_obs_nr_var, filter_add, filter_join, check_type = warning)
      + 1.1.1: (dataset, dataset_add, by_vars, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, order, tmp_obs_nr_var, filter_add, filter_join, filter, check_type = warning)
    * get_summary_records
      - 1.2.0: (dataset, by_vars, filter, set_values_to)
      + 1.1.1: (dataset, by_vars, filter, analysis_var, summary_fun, set_values_to)
```

## Dependencies

```         
-- Depends --
  Modified:
     R: >= 4.1 -> >= 4.0 

-- Imports --
  Modified:
     admiraldev: >= 1.2.0 -> >= 1.1.0 

-- Suggests --
  Removed:   withr 
```

## Function

```         
-- Functions --
  Removed:
    - get_joined_sub_data(dataset, dataset_add, by_vars, tmp_obs_nr_var, tmp_obs_nr_left, join_type, first_cond_upper, first_cond_lower, filter_join)
    - derive_vars_cat(dataset, definition, by_vars)
    - extend_condition(cond, var, is)
    - derive_vars_crit_flag(dataset, crit_nr = 1, condition, description, values_yn = FALSE, create_numeric_flag = FALSE)
    - roxygen_save_memory()
    - transform_range(source, source_range, target_range, flip_direction = FALSE, outside_range = NA)
  Modified:
    * set_admiral_options
      - 1.2.0: (subject_keys, signif_digits, save_memory)
      + 1.1.1: (subject_keys, signif_digits)
    * consolidate_metadata
      - 1.2.0: (datasets, key_vars, source_var, check_vars = warning, check_type = error)
      + 1.1.1: (datasets, key_vars, source_var, check_vars = warning, check_keys, check_type = error)
    * create_single_dose_dataset
      - 1.2.0: (dataset, dose_freq, start_date, start_datetime, end_date, end_datetime, lookup_table, lookup_column, nominal_time, c("keep_source_vars = expr_c(get_admiral_option(\"subject_keys\"), dose_freq, start_date, ", "keep_source_vars =     start_datetime, end_date, end_datetime)"))
      + 1.1.1: (dataset, dose_freq, start_date, start_datetime, end_date, end_datetime, lookup_table, lookup_column, nominal_time, c("keep_source_vars = expr_c(exprs(USUBJID), dose_freq, start_date, start_datetime, ", "keep_source_vars =     end_date, end_datetime)"))
    * derive_extreme_event
      - 1.2.0: (dataset, by_vars, events, tmp_event_nr_var, order, mode, source_datasets, check_type = warning, set_values_to, keep_source_vars = exprs(everything()))
      + 1.1.1: (dataset, by_vars, events, tmp_event_nr_var, order, mode, source_datasets, ignore_event_order, check_type = warning, set_values_to, keep_source_vars = exprs(everything()))
    * derive_vars_merged
      - 1.2.0: (dataset, dataset_add, by_vars, order, new_vars, filter_add, mode, exist_flag, true_value = Y, false_value = NA, missing_values, check_type = warning, duplicate_msg, relationship)
      + 1.1.1: (dataset, dataset_add, by_vars, order, new_vars, filter_add, mode, match_flag, exist_flag, true_value = Y, false_value = NA, missing_values, check_type = warning, duplicate_msg, relationship)
    * derive_var_merged_summary
      - 1.2.0: (dataset, dataset_add, by_vars, new_vars, filter_add, missing_values)
      + 1.1.1: (dataset, dataset_add, by_vars, new_vars, new_var, filter_add, missing_values, analysis_var, summary_fun)
    * derive_param_exposure
      - 1.2.0: (dataset, dataset_add, by_vars, input_code, filter_add, set_values_to)
      + 1.1.1: (dataset, dataset_add, by_vars, input_code, analysis_var, summary_fun, filter, filter_add, set_values_to)
    * derive_param_tte
      - 1.2.0: (dataset, dataset_adsl, source_datasets, by_vars, start_date, event_conditions, censor_conditions, create_datetime = FALSE, set_values_to, subject_keys = get_admiral_option("subject_keys"), check_type = warning)
      + 1.1.1: (dataset, dataset_adsl, source_datasets, by_vars, start_date, event_conditions, censor_conditions, create_datetime = FALSE, set_values_to, subject_keys = get_admiral_option("subject_keys"))
    * filter_date_sources
      - 1.2.0: (sources, source_datasets, by_vars, create_datetime = FALSE, subject_keys, mode, check_type = none)
      + 1.1.1: (sources, source_datasets, by_vars, create_datetime = FALSE, subject_keys, mode)
    * tte_source
      - 1.2.0: (dataset_name, filter, date, censor = 0, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, censor = 0, set_values_to)
    * event_source
      - 1.2.0: (dataset_name, filter, date, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, set_values_to)
    * censor_source
      - 1.2.0: (dataset_name, filter, date, censor = 1, set_values_to, order)
      + 1.1.1: (dataset_name, filter, date, censor = 1, set_values_to)
    * derive_summary_records
      - 1.2.0: (dataset, dataset_add, dataset_ref, by_vars, filter_add, set_values_to, missing_values)
      + 1.1.1: (dataset, dataset_add, dataset_ref, by_vars, filter, filter_add, analysis_var, summary_fun, set_values_to, missing_values)
    * derive_var_atoxgr_dir
      - 1.2.0: (dataset, new_var, tox_description_var, meta_criteria, criteria_direction, abnormal_indicator, get_unit_expr, signif_dig = get_admiral_option("signif_digits"))
      + 1.1.1: (dataset, new_var, tox_description_var, meta_criteria, criteria_direction, get_unit_expr, signif_dig = get_admiral_option("signif_digits"))
    * derive_var_joined_exist_flag
      - 1.2.0: (dataset, dataset_add, by_vars, order, new_var, tmp_obs_nr_var, join_vars, join_type, first_cond_lower, first_cond_upper, filter_add, filter_join, true_value = Y, false_value = NA, check_type = warning)
      + 1.1.1: (dataset, dataset_add, by_vars, order, new_var, tmp_obs_nr_var, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, filter, filter_add, filter_join, true_value = Y, false_value = NA, check_type = warning)
    * derive_vars_atc
      - 1.2.0: (dataset, dataset_facm, by_vars = exprs(!!!get_admiral_option("subject_keys"), CMREFID = FAREFID), id_vars, value_var)
      + 1.1.1: (dataset, dataset_facm, by_vars = exprs(USUBJID, CMREFID = FAREFID), id_vars, value_var)
    * signal_duplicate_records
      - 1.2.0: (dataset, by_vars, c("msg = paste(\"Dataset contains duplicate records\", \"with respect to\", ", "msg =     \"{.var {replace_values_by_names(by_vars)}}\")"), cnd_type = error, class)
      + 1.1.1: (dataset, by_vars, c("msg = paste(\"Dataset contains duplicate records\", \"with respect to\", ", "msg =     \"{.var {replace_values_by_names(by_vars)}}\")"), cnd_type = error)
    * event_joined
      - 1.2.0: (dataset_name, condition, order, join_vars, join_type, first_cond_lower, first_cond_upper, set_values_to, keep_source_vars, description)
      + 1.1.1: (dataset_name, condition, order, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, set_values_to, keep_source_vars, description)
    * filter_joined
      - 1.2.0: (dataset, dataset_add, by_vars, join_vars, join_type, first_cond_lower, first_cond_upper, order, tmp_obs_nr_var, filter_add, filter_join, check_type = warning)
      + 1.1.1: (dataset, dataset_add, by_vars, join_vars, join_type, first_cond, first_cond_lower, first_cond_upper, order, tmp_obs_nr_var, filter_add, filter_join, filter, check_type = warning)
    * get_summary_records
      - 1.2.0: (dataset, by_vars, filter, set_values_to)
      + 1.1.1: (dataset, by_vars, filter, analysis_var, summary_fun, set_values_to)
```

You can check the result in this website
[Here](https://diffify.com/R/admiral/1.3.0/1.3.1)

## Traceability matrix comparison

[`whatsnew`](https://cran.r-project.org/package=whatsnew) package also
to build a **traceability matrix (TM)** and compare changes between
different package versions of.

### Create Traceability Matrices

We generate traceability matrices for two versions of `dplyr`:

```         
tm_list_1 <- whatsnew::generate_traceability_matrix("dplyr", "1.1.4") 
tm_list_2 <- whatsnew::generate_traceability_matrix("dplyr", "1.0.9") 
```

Each traceability matrix (`tm_list_$tm`) is a tibble showing exported
functions, their type, body, and documentation references.


### Example TM differences for function_type

| exported_function | function_type_tm_list_1_tm | function_type_tm_list_2_tm | different |
|:-----------------|:------------------|:------------------|:-----------------|
| add_count         | regular function           | S3 generic + method        | TRUE      |
| anti_join         | regular function           | S3 generic + method        | TRUE      |
| arrange           | regular function           | S3 generic + method        | TRUE      |
| arrange\_         | regular function           | S3 generic + method        | TRUE      |
| as_tibble         | regular function           | S3 generic + method        | TRUE      |
| auto_copy         | regular function           | S3 generic + method        | TRUE      |
| collapse          | regular function           | S3 generic + method        | TRUE      |
| collect           | regular function           | S3 generic + method        | TRUE      |
| common_by         | regular function           | S3 generic + method        | TRUE      |
| compute           | regular function           | S3 generic + method        | TRUE      |
