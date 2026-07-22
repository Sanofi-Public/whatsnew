# compare_column

test_that("compare_column returns key + param columns + flag; computes diffs incl. NA logic", {
  tm_list_1 <- list(
    tm = dplyr::tibble(
      exported_function = c("basket_select", "call_derivation", "compute_bmi", "compute_bsa"),
      class            = c(NA, NA, NA, NA),
      function_type    = c("regular function", "regular function", NA, "special function"),
      function_body    = "{code1}",
      where            = "admiral",
      code_script      = "R/some_file.R",
      documentation    = "some_doc.Rd"
    )
  )

  tm_list_2 <- list(
    tm = dplyr::tibble(
      exported_function = c("basket_select", "call_derivation", "compute_bmi", "compute_bsa"),
      class            = c(NA, NA, NA, NA),
      function_type    = c("regular function", "special function", NA, NA), # diffs on rows 2 and 4
      function_body    = "{code2}",
      where            = "admiral",
      code_script      = "R/other_file.R",
      documentation    = "other_doc.Rd"
    )
  )

  out_all <- compare_column(
    df1 = tm_list_1$tm,
    df2 = tm_list_2$tm,
    key = "exported_function",
    param_col = "function_type",
    name1 = "tm_list_1_tm",
    name2 = "tm_list_2_tm",
    only_diff = FALSE
  )

  # Structure
  expect_s3_class(out_all, "data.frame")
  expect_named(
    out_all,
    expected = c(
      "exported_function",
      "function_type_tm_list_1_tm",
      "function_type_tm_list_2_tm",
      "different"
    ),
    ignore.order = FALSE
  )
  expect_equal(nrow(out_all), 4)

  row1 <- out_all %>% filter(exported_function == "basket_select") %>% slice(1)
  expect_equal(row1$function_type_tm_list_1_tm, "regular function")
  expect_equal(row1$function_type_tm_list_2_tm, "regular function")
  expect_false(row1$different)

  row2 <- out_all %>% filter(exported_function == "call_derivation") %>% slice(1)
  expect_equal(row2$function_type_tm_list_1_tm, "regular function")
  expect_equal(row2$function_type_tm_list_2_tm, "special function")
  expect_true(row2$different)

  row3 <- out_all %>% filter(exported_function == "compute_bmi") %>% slice(1)
  expect_true(is.na(row3$function_type_tm_list_1_tm))
  expect_true(is.na(row3$function_type_tm_list_2_tm))
  expect_false(row3$different)

  row4 <- out_all %>% filter(exported_function == "compute_bsa") %>% slice(1)
  expect_equal(row4$function_type_tm_list_1_tm, "special function")
  expect_true(is.na(row4$function_type_tm_list_2_tm))
  expect_true(row4$different)
})

test_that("compare_column only_diff = TRUE filters to only differing rows", {
  tm_list_1 <- list(
    tm = dplyr::tibble(
      exported_function = c("basket_select", "call_derivation", "compute_bmi", "compute_bsa"),
      function_type    = c("regular function", "regular function", NA, "special function")
    )
  )

  tm_list_2 <- list(
    tm = dplyr::tibble(
      exported_function = c("basket_select", "call_derivation", "compute_bmi", "compute_bsa"),
      function_type    = c("regular function", "special function", NA, NA)
    )
  )

  out_diff <- compare_column(
    df1 = tm_list_1$tm,
    df2 = tm_list_2$tm,
    key = "exported_function",
    param_col = "function_type",
    name1 = "tm_list_1_tm",
    name2 = "tm_list_2_tm",
    only_diff = TRUE
  )

  expect_equal(nrow(out_diff), 2)
  expect_setequal(
    out_diff$exported_function,
    c("call_derivation", "compute_bsa")
  )
  expect_true(all(out_diff$different))
})

test_that("compare_column only_diff = TRUE returns empty when no diffs", {
  df1 <- dplyr::tibble(
    exported_function = c("a", "b"),
    function_type = c("x", NA)
  )
  df2 <- dplyr::tibble(
    exported_function = c("a", "b"),
    function_type = c("x", NA)
  )

  out_all <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "left_src",
    name2 = "right_src",
    only_diff = FALSE
  )
  expect_equal(nrow(out_all), 2)
  expect_false(any(out_all$different))

  out_diff <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "left_src",
    name2 = "right_src",
    only_diff = TRUE
  )
  expect_equal(nrow(out_diff), 0)
})

test_that("compare_column respects custom suffix names (both only_diff modes)", {
  df1 <- dplyr::tibble(
    exported_function = "a",
    function_type = "x"
  )
  df2 <- dplyr::tibble(
    exported_function = "a",
    function_type = "y"
  )

  out_all <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "left_src",
    name2 = "right_src",
    only_diff = FALSE
  )

  expect_named(
    out_all,
    c("exported_function",
      "function_type_left_src",
      "function_type_right_src",
      "different")
  )
  expect_true(out_all$different[[1]])

  out_diff <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "left_src",
    name2 = "right_src",
    only_diff = TRUE
  )
  expect_equal(nrow(out_diff), 1)
  expect_named(
    out_diff,
    c("exported_function",
      "function_type_left_src",
      "function_type_right_src",
      "different")
  )
  expect_true(out_diff$different[[1]])
})



# compare_tm

fake_gen_tm <- function(pkg, ver) {
  list(tm = dplyr::tibble(exported_function = character()))
}

fake_compare_column <- function(df1, df2, key, param_col, name1, name2, only_diff) {
  col1 <- paste0(param_col, "_", name1)
  col2 <- paste0(param_col, "_", name2)

  dplyr::tibble(
    exported_function = "f",
    !!col1 := paste0("new_", param_col),
    !!col2 := paste0("old_", param_col),
    different = TRUE
  )
}

test_that("compare_tm returns 1 row when fields has length 1", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column)

  out <- compare_tm("mypkg", "2.0.0", "1.0.0", fields = "description")

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1)
  expect_equal(out$exported_function, "f")
  expect_equal(out$field, "description")
  expect_equal(out$value_mypkg_2.0.0, "new_description")
  expect_equal(out$value_mypkg_1.0.0, "old_description")
})

test_that("compare_tm respects fields subset and preserves field labels", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column)

  out <- compare_tm("mypkg", "2.0.0", "1.0.0",
                    fields = c("description", "function_type"))

  expect_equal(nrow(out), 2)
  expect_equal(sort(out$field), sort(c("description", "function_type")))
  expect_true(any(out$value_mypkg_2.0.0 == "new_description"))
  expect_true(any(out$value_mypkg_2.0.0 == "new_function_type"))
})

test_that("compare_tm supports duplicate fields (returns duplicate rows)", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column)

  out <- compare_tm("mypkg", "2.0.0", "1.0.0",
                    fields = c("description", "description"))

  expect_equal(nrow(out), 2)
  expect_true(all(out$field == "description"))
})

test_that("compare_tm creates version-specific value_* columns from package/version args", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column)

  out <- compare_tm("abc", "0.1.0", "0.0.9", fields = "function_body")

  expect_named(out, c(
    "exported_function", "field",
    "value_abc_0.1.0", "value_abc_0.0.9"
  ))
  expect_equal(out$value_abc_0.1.0, "new_function_body")
  expect_equal(out$value_abc_0.0.9, "old_function_body")
})

test_that("compare_tm propagates errors from TM generation", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix",
                function(...) stop("gen failed"))

  expect_error(compare_tm("mypkg", "2.0.0", "1.0.0"), "gen failed")
})

test_that("compare_tm propagates errors from compare_column", {
  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", function(...) stop("cmp failed"))

  expect_error(compare_tm("mypkg", "2.0.0", "1.0.0"), "cmp failed")
})

test_that("compare_tm drops fields with no diffs when compare_column returns 0 rows", {
  fake_compare_column_some_empty <- function(df1, df2, key, param_col, name1, name2, only_diff) {
    col1 <- paste0(param_col, "_", name1)
    col2 <- paste0(param_col, "_", name2)

    if (param_col == "function_body") {
      # simulate: no differences for that field
      return(dplyr::tibble(
        exported_function = character(),
        !!col1 := character(),
        !!col2 := character(),
        different = logical()
      ))
    }

    dplyr::tibble(
      exported_function = "f",
      !!col1 := paste0("new_", param_col),
      !!col2 := paste0("old_", param_col),
      different = TRUE
    )
  }

  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column_some_empty)

  out <- compare_tm("mypkg", "2.0.0", "1.0.0",
                    fields = c("function_type", "function_body", "description"))

  expect_equal(sort(unique(out$field)), sort(c("function_type", "description")))
  expect_false(any(out$field == "function_body"))
  expect_equal(nrow(out), 2)
})

test_that("compare_tm returns tidy diff tibble with dynamic value_* columns", {

  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm)
  mockery::stub(compare_tm, "compare_column", fake_compare_column)

  out <- compare_tm("mypkg", "2.0.0", "1.0.0",
                    fields = c("function_type", "function_body", "description"))

  expect_s3_class(out, "tbl_df")
  expect_named(out, c(
    "exported_function", "field",
    "value_mypkg_2.0.0", "value_mypkg_1.0.0"
  ))

  expect_equal(nrow(out), 3)
  expect_true(all(out$exported_function == "f"))
  expect_equal(out$field, sort(c("function_type", "function_body", "description")))

  # spot check a value
  expect_true(any(out$field == "function_body"))
  expect_true(any(out$value_mypkg_2.0.0 == "new_function_body"))
  expect_true(any(out$value_mypkg_1.0.0 == "old_function_body"))
})


test_that("compare_column returns an empty tibble when df1 has 0 rows (covers early return)", {
  df1_empty <- data.frame(
    exported_function = character(),
    package = character(),
    function_type = character(),
    stringsAsFactors = FALSE
  )
  df2 <- data.frame(
    exported_function = "f",
    package = "pkg",
    function_type = "type",
    stringsAsFactors = FALSE
  )

  res <- compare_column(
    df1 = df1_empty,
    df2 = df2,
    key = c("exported_function", "package"),
    param_col = "function_type",
    name1 = "new",
    name2 = "old"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0L)
  expect_named(res, c("exported_function", "package",
                      "function_type_new", "function_type_old", "different"))
})

test_that("compare_column returns an empty tibble when df2 has 0 rows (covers early return)", {
  df1 <- data.frame(
    exported_function = "f",
    package = "pkg",
    function_type = "type",
    stringsAsFactors = FALSE
  )
  df2_empty <- data.frame(
    exported_function = character(),
    package = character(),
    function_type = character(),
    stringsAsFactors = FALSE
  )

  res <- compare_column(
    df1 = df1,
    df2 = df2_empty,
    key = c("exported_function", "package"),
    param_col = "function_type",
    name1 = "new",
    name2 = "old"
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0L)
  expect_named(res, c("exported_function", "package",
                      "function_type_new", "function_type_old", "different"))
})

# Tests for aggregation fix (preventing cartesian product)

test_that("compare_column aggregates multiple values per function correctly", {
  # Function with multiple function_type values in both versions
  df1 <- dplyr::tibble(
    exported_function = c("add_count", "add_count", "other_func"),
    function_type = c("regular function", "S3 generic + method", "regular function")
  )

  df2 <- dplyr::tibble(
    exported_function = c("add_count", "add_count", "other_func"),
    function_type = c("S3 generic + method", "regular function", "regular function")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  # Should have exactly 2 rows (one per function)
  expect_equal(nrow(result), 2)

  # add_count should have aggregated values
  add_count_row <- result %>% dplyr::filter(exported_function == "add_count")
  expect_equal(nrow(add_count_row), 1)
  # Values should be aggregated and sorted
  expect_true(grepl("regular function", add_count_row$function_type_v1))
  expect_true(grepl("S3 generic", add_count_row$function_type_v1))
  expect_true(grepl("regular function", add_count_row$function_type_v2))
  expect_true(grepl("S3 generic", add_count_row$function_type_v2))
  # Should be marked as same (both have same set of values)
  expect_false(add_count_row$different)

  # other_func should be same
  other_row <- result %>% dplyr::filter(exported_function == "other_func")
  expect_equal(nrow(other_row), 1)
  expect_false(other_row$different)
})

test_that("compare_column prevents cartesian product with multiple values", {
  # Simulate the bug: function with different values in each version
  # Before fix: would create 2x2 = 4 rows with reversed values
  # After fix: should create 1 row with aggregated values
  df1 <- dplyr::tibble(
    exported_function = c("add_count", "add_count"),
    function_type = c("regular function", "S3 generic + method")
  )

  df2 <- dplyr::tibble(
    exported_function = c("add_count", "add_count"),
    function_type = c("S3 generic + method", "regular function")
  )

  # Use only_diff = FALSE to see the row even when values are the same
  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1_1.1.4",
    name2 = "v2_1.1.3",
    only_diff = FALSE
  )

  # Should have exactly 1 row, not 4
  expect_equal(nrow(result), 1)
  expect_equal(result$exported_function, "add_count")

  # Values should be aggregated (sorted, unique)
  expect_true(grepl("regular function", result$function_type_v1_1.1.4))
  expect_true(grepl("S3 generic", result$function_type_v1_1.1.4))
  expect_true(grepl("regular function", result$function_type_v2_1.1.3))
  expect_true(grepl("S3 generic", result$function_type_v2_1.1.3))

  # Should be marked as same (both have same set of values)
  expect_false(result$different)

  # With only_diff = TRUE, should return 0 rows (since they're the same)
  result_diff <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1_1.1.4",
    name2 = "v2_1.1.3",
    only_diff = TRUE
  )
  expect_equal(nrow(result_diff), 0)
})

test_that("compare_column handles functions with different multiple values correctly", {
  # Function has different sets of values in each version
  df1 <- dplyr::tibble(
    exported_function = c("func_a", "func_a", "func_b"),
    function_type = c("type1", "type2", "type1")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func_a", "func_a", "func_b"),
    function_type = c("type1", "type3", "type1")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "new",
    name2 = "old",
    only_diff = TRUE
  )

  # Should have 1 row for func_a (different) and 0 for func_b (same)
  expect_equal(nrow(result), 1)
  expect_equal(result$exported_function, "func_a")
  expect_true(result$different)

  # func_a should show aggregated differences
  expect_true(grepl("type1", result$function_type_new))
  expect_true(grepl("type2", result$function_type_new))
  expect_true(grepl("type1", result$function_type_old))
  expect_true(grepl("type3", result$function_type_old))
})

test_that("compare_column aggregates values in sorted order", {
  df1 <- dplyr::tibble(
    exported_function = c("func", "func", "func"),
    function_type = c("zebra", "alpha", "beta")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func", "func"),
    function_type = c("alpha", "zebra")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  expect_equal(nrow(result), 1)
  # Values should be sorted alphabetically
  expect_equal(result$function_type_v1, "alpha; beta; zebra")
  expect_equal(result$function_type_v2, "alpha; zebra")
  expect_true(result$different)
})

test_that("compare_column handles NA values in aggregation", {
  df1 <- dplyr::tibble(
    exported_function = c("func", "func", "func"),
    function_type = c("type1", NA_character_, "type2")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func", "func"),
    function_type = c("type1", "type2")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  expect_equal(nrow(result), 1)
  # NA should be excluded from aggregation (only non-NA values are aggregated)
  expect_true(grepl("type1", result$function_type_v1))
  expect_true(grepl("type2", result$function_type_v1))
  expect_false(grepl("NA", result$function_type_v1))
  expect_equal(result$function_type_v2, "type1; type2")
  # Should be marked as same (both have same non-NA values)
  expect_false(result$different)

  # Test case where all values are NA
  df1_all_na <- dplyr::tibble(
    exported_function = c("func", "func"),
    function_type = c(NA_character_, NA_character_)
  )

  df2_all_na <- dplyr::tibble(
    exported_function = c("func"),
    function_type = c(NA_character_)
  )

  result_all_na <- compare_column(
    df1_all_na, df2_all_na,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  expect_equal(nrow(result_all_na), 1)
  expect_true(is.na(result_all_na$function_type_v1))
  expect_true(is.na(result_all_na$function_type_v2))
  expect_false(result_all_na$different)
})

test_that("compare_column handles single value per function (no aggregation needed)", {
  # Functions with single values should work as before
  df1 <- dplyr::tibble(
    exported_function = c("func1", "func2"),
    function_type = c("type1", "type2")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func1", "func2"),
    function_type = c("type1", "type3")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = TRUE
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$exported_function, "func2")
  expect_equal(result$function_type_v1, "type2")
  expect_equal(result$function_type_v2, "type3")
})

test_that("compare_column handles duplicate values correctly (deduplicates)", {
  # Same value appears multiple times for a function
  df1 <- dplyr::tibble(
    exported_function = c("func", "func", "func"),
    function_type = c("type1", "type1", "type2")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func", "func"),
    function_type = c("type1", "type2")
  )

  result <- compare_column(
    df1, df2,
    key = "exported_function",
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  expect_equal(nrow(result), 1)
  # Should deduplicate: "type1" appears twice but should only appear once in result
  expect_equal(result$function_type_v1, "type1; type2")
  expect_equal(result$function_type_v2, "type1; type2")
  expect_false(result$different)
})

test_that("compare_tm handles aggregated values correctly", {
  # Test that compare_tm works with the aggregation fix
  # Use different values so they show up as differences
  fake_gen_tm_multiple <- function(pkg, ver) {
    if (ver == "1.1.4") {
      list(tm = dplyr::tibble(
        exported_function = c("add_count", "add_count", "other"),
        function_type = c("regular function", "S3 generic + method", "regular function"),
        function_body = c("body1", "body2", "body3"),
        description = c("desc1", "desc2", "desc3")
      ))
    } else {
      list(tm = dplyr::tibble(
        exported_function = c("add_count", "add_count", "other"),
        function_type = c("S3 generic + method", "regular function", "regular function"),
        function_body = c("body2", "body3", "body3"),  # Different: v1 has body1+body2, v2 has body2+body3
        description = c("desc2", "desc4", "desc3")  # Different: v1 has desc1+desc2, v2 has desc2+desc4
      ))
    }
  }

  mockery::stub(compare_tm, "risk.assessr::generate_traceability_matrix", fake_gen_tm_multiple)

  result <- compare_tm("testpkg", "1.1.4", "1.0.9",
                        fields = c("function_type", "function_body", "description"))

  # Should have results for add_count (different) - function_type is same so filtered out
  # add_count should appear once per field that differs, not multiple times
  add_count_rows <- result %>% dplyr::filter(exported_function == "add_count")
  expect_equal(nrow(add_count_rows), 2)  # function_body and description differ, function_type is same

  # function_type should be filtered out (same after aggregation)
  func_type_row <- add_count_rows %>% dplyr::filter(field == "function_type")
  expect_equal(nrow(func_type_row), 0)

  # Check that function_body shows aggregated values and differs
  func_body_row <- add_count_rows %>% dplyr::filter(field == "function_body")
  expect_equal(nrow(func_body_row), 1)
  expect_true(grepl("body1", func_body_row$value_testpkg_1.1.4))
  expect_true(grepl("body2", func_body_row$value_testpkg_1.1.4))
  expect_true(grepl("body2", func_body_row$value_testpkg_1.0.9))
  expect_true(grepl("body3", func_body_row$value_testpkg_1.0.9))

  # Check description differs
  desc_row <- add_count_rows %>% dplyr::filter(field == "description")
  expect_equal(nrow(desc_row), 1)
  expect_true(grepl("desc1", desc_row$value_testpkg_1.1.4))
  expect_true(grepl("desc2", desc_row$value_testpkg_1.1.4))
})

test_that("compare_column works with multi-column keys", {
  # Test aggregation with composite keys
  df1 <- dplyr::tibble(
    exported_function = c("func", "func", "func"),
    class = c("A", "A", "B"),
    function_type = c("type1", "type2", "type1")
  )

  df2 <- dplyr::tibble(
    exported_function = c("func", "func"),
    class = c("A", "B"),
    function_type = c("type1", "type1")
  )

  result <- compare_column(
    df1, df2,
    key = c("exported_function", "class"),
    param_col = "function_type",
    name1 = "v1",
    name2 = "v2",
    only_diff = FALSE
  )

  # Should have 2 rows: (func, A) and (func, B)
  expect_equal(nrow(result), 2)

  func_a <- result %>% dplyr::filter(exported_function == "func", class == "A")
  expect_equal(nrow(func_a), 1)
  expect_equal(func_a$function_type_v1, "type1; type2")
  expect_equal(func_a$function_type_v2, "type1")
  expect_true(func_a$different)

  func_b <- result %>% dplyr::filter(exported_function == "func", class == "B")
  expect_equal(nrow(func_b), 1)
  expect_equal(func_b$function_type_v1, "type1")
  expect_equal(func_b$function_type_v2, "type1")
  expect_false(func_b$different)
})




