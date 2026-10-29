# tests/testthat/test-extract_versions.R

test_that("extract_versions works with standard Imports string", {
  deps_string <- "admiraldev (>= 1.2.0), cli (>= 3.6.2), dplyr (>= 1.0.5), hms (>= 0.5.3), lifecycle (>= 0.1.0), lubridate (>= 1.7.4), magrittr (>= 1.5), purrr (>= 0.3.3), rlang (>= 0.4.4), stringr (>= 1.4.0)"

  df <- extract_versions(deps_string)

  expect_s3_class(df, "data.frame")
  expect_named(df, c("pkg", "version"))
  expect_equal(nrow(df), 10)

  expect_equal(df$pkg[1], "admiraldev")
  expect_equal(df$version[1], ">= 1.2.0")
  expect_equal(df$pkg[10], "stringr")
  expect_equal(df$version[10], ">= 1.4.0")

  expect_false(any(is.na(df$version)))
})

test_that("extract_versions works with NULL", {
  df <- extract_versions(NULL)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
  expect_named(df, c("pkg", "version"))
})

test_that("extract_versions works when some packages have no version", {
  deps_string <- "foo, bar (>= 1.0.0), baz"
  df <- extract_versions(deps_string)
  expect_equal(nrow(df), 3)
  expect_equal(df$pkg, c("foo", "bar", "baz"))
  expect_true(is.na(df$version[1]))
  expect_equal(df$version[2], ">= 1.0.0")
  expect_true(is.na(df$version[3]))
})
