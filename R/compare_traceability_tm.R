#' Compare Traceability Matrices (TM) Between Two Package Versions
#'
#' This function compares the traceability matrices (TMs) generated for two
#' versions of an R package. It identifies differences in selected fields
#' (such as function type, body, and description) across versions.
#'
#' The function leverages `risk.assessr::generate_traceability_matrix()`
#' to extract TM data for each version, then compares them using
#' `compare_column()` and outputs a tidy data frame summarizing differences.
#'
#' @param package_name Character string, the name of the package to compare.
#' @param version_new Character string, the newer version of the package.
#' @param version_old Character string, the older version of the package.
#' @param fields Character vector of TM fields to compare.
#'   Defaults to `c("function_type", "function_body", "description")`.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{exported_function}{Function name being compared}
#'   \item{field}{The TM field that differs}
#'   \item{value_<package>_<new_version>}{Value from the newer version}
#'   \item{value_<package>_<old_version>}{Value from the older version}
#' }
#'
#' @examples
#' \dontrun{
#' # Compare traceability matrices for two versions of a package
#' diff_tm <- compare_tm("dplyr", "1.1.4", "1.0.8")
#' head(diff_tm)
#' }
#'
#' @export
compare_tm <- function(
  package_name,
  version_new,
  version_old,
  fields = c("function_type", "function_body", "description")
) {
  # Generate TMs for both versions
  tm_list_new <- risk.assessr::generate_traceability_matrix(
    package_name,
    version_new
  )
  tm_list_old <- risk.assessr::generate_traceability_matrix(
    package_name,
    version_old
  )

  # Dynamically create version-specific identifiers
  name_new <- paste0(package_name, "_", version_new)
  name_old <- paste0(package_name, "_", version_old)

  # Compare specified TM fields
  func_cmp <- purrr::map_dfr(fields, function(field) {
    compare_column(
      tm_list_new$tm,
      tm_list_old$tm,
      key = "exported_function",
      param_col = field,
      name1 = name_new,
      name2 = name_old,
      only_diff = TRUE
    ) %>%
      dplyr::transmute(
        exported_function,
        field = field,
        !!paste0("value_", name_new) := .data[[paste0(field, "_", name_new)]],
        !!paste0("value_", name_old) := .data[[paste0(field, "_", name_old)]]
      )
  }) %>%
    dplyr::arrange(exported_function, field)

  func_cmp
}


#' Compare one column across two data frames by key
#'
#' @description
#' Inner-joins two data frames on key column(s) and compares a single column
#' between them. Returns the keys, the two suffixed columns, and a logical
#' `different` flag with NA-aware rules.
#'
#' @param df1 A data frame.
#' @param df2 A data frame.
#' @param key Character vector of join key(s), passed to `dplyr::inner_join(by = key)`.
#' @param param_col String. Base name of the column to compare (without suffixes).
#' @param name1,name2 Suffixes for the compared columns from `df1` and `df2`.
#'   Defaults: `"tm_list_1_tm"` and `"tm_list_2_tm"`.
#' @param only_diff Logical. If `TRUE` (default), keep only rows where values differ.
#'   If `FALSE`, return all joined rows with a `different` flag.
#'
#' @return A tibble with the key column(s),
#'   `<param_col>_<name1>`, `<param_col>_<name2>`, and `different` (logical).
#'   If `only_diff = TRUE`, only rows with `different = TRUE` are kept.
#'
#' @importFrom dplyr inner_join select mutate filter all_of case_when
#' @importFrom dplyr tibble
#' @importFrom rlang .data
#' @export
compare_column <- function(
  df1,
  df2,
  key,
  param_col,
  name1 = "tm_list_1_tm",
  name2 = "tm_list_2_tm",
  only_diff = TRUE
) {
  # Helper function to aggregate multiple values per key
  aggregate_values <- function(df, key_col, val_col) {
    df %>%
      dplyr::distinct(dplyr::across(dplyr::all_of(c(key_col, val_col)))) %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(key_col))) %>%
      dplyr::summarise(
        !!val_col := {
          vals <- unique(.data[[val_col]])
          non_na <- sort(vals[!is.na(vals)])
          if (length(non_na) == 0) {
            NA_character_
          } else if (length(non_na) == 1) {
            non_na
          } else {
            paste(non_na, collapse = "; ")
          }
        },
        .groups = "drop"
      )
  }

  # Aggregate multiple values per function to prevent cartesian product issues
  df1 <- aggregate_values(df1, key, param_col)
  df2 <- aggregate_values(df2, key, param_col)

  col1 <- paste0(param_col, "_", name1)
  col2 <- paste0(param_col, "_", name2)

  # Early return for empty inputs
  if (nrow(df1) == 0 || nrow(df2) == 0) {
    empty_keys <- if (nrow(df1) > 0) {
      df1[0, key, drop = FALSE]
    } else {
      df2[0, key, drop = FALSE]
    }

    return(dplyr::bind_cols(
      empty_keys,
      dplyr::tibble(
        !!col1 := character(),
        !!col2 := character(),
        different = logical()
      )
    ))
  }

  # Join and compare
  result <- df1 %>%
    dplyr::inner_join(
      df2,
      by = key,
      suffix = c(paste0("_", name1), paste0("_", name2))
    ) %>%
    dplyr::select(dplyr::all_of(c(key, col1, col2))) %>%
    dplyr::mutate(
      different = dplyr::case_when(
        is.na(.data[[col1]]) & is.na(.data[[col2]]) ~ FALSE,
        xor(is.na(.data[[col1]]), is.na(.data[[col2]])) ~ TRUE,
        TRUE ~ .data[[col1]] != .data[[col2]]
      )
    )

  if (only_diff) {
    result <- dplyr::filter(result, .data$different)
  }
  result
}
