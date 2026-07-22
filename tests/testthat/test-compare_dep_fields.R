# compare_dep_fields

test_that("compare_dep_fields detects added, removed, and modified dependencies correctly", {
  dep_old <- "dplyr (>= 1.0.0), tibble (>= 2.0.0), purrr"
  dep_new <- "dplyr (>= 1.1.0), tidyr (>= 1.2.0), purrr"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_type(result, "list")
  expect_named(result, c("added", "removed", "modified"))
  expect_equal(result$added, "tidyr")
  expect_equal(result$removed, "tibble")
  expect_true(any(grepl("^dplyr: ", result$modified)))
  expect_true(any(grepl("1.0.0", result$modified)))
  expect_true(any(grepl("1.1.0", result$modified)))
})

test_that("compare_dep_fields handles no changes correctly", {
  dep_old <- "dplyr (>= 1.0.0), purrr"
  dep_new <- "purrr, dplyr (>= 1.0.0)"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_equal(result$modified, NULL)
})

test_that("compare_dep_fields handles NA versions correctly", {
  dep_old <- "foo, bar (>= 1.0.0)"
  dep_new <- "foo (>= 2.0.0), bar"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_true(any(grepl("foo", result$modified)))
  expect_true(any(grepl("none ->", result$modified)))
  expect_true(any(grepl("bar", result$modified)))
  expect_true(any(grepl(">= 1.0.0 -> none", result$modified)))
})


test_that("compare_dep_fields handles both dep strings NULL", {
  result <- compare_dep_fields(NULL, NULL)

  expect_named(result, c("added", "removed", "modified"))
  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})

test_that("compare_dep_fields handles new NULL (all removed)", {
  dep_old <- "dplyr (>= 1.0.0), tibble"
  result <- compare_dep_fields(NULL, dep_old)

  expect_equal(sort(result$removed), sort(c("dplyr", "tibble")))
  expect_equal(result$added, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})

test_that("compare_dep_fields handles old NULL (all added)", {
  dep_new <- "dplyr (>= 1.0.0), tibble"
  result <- compare_dep_fields(dep_new, NULL)

  expect_equal(sort(result$added), sort(c("dplyr", "tibble")))
  expect_equal(result$removed, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})

test_that("compare_dep_fields ignores order and extra whitespace/newlines", {
  dep_old <- "dplyr (>= 1.0.0),\n  tibble, purrr"
  dep_new <- "purrr, tibble,  dplyr (>= 1.0.0)"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})

test_that("compare_dep_fields detects version change where only constraint changes", {
  dep_old <- "dplyr (>= 1.0.0)"
  dep_new <- "dplyr (>= 1.0.1)"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_true(any(grepl("^dplyr:", result$modified)))
  expect_true(any(grepl("1.0.0", result$modified)))
  expect_true(any(grepl("1.0.1", result$modified)))
})

test_that("compare_dep_fields treats exact same constraint as unchanged", {
  dep_old <- "dplyr (>= 1.0.0)"
  dep_new <- "dplyr (>= 1.0.0)"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})

test_that("compare_dep_fields can handle trailing commas / empty tokens", {
  dep_old <- "dplyr (>= 1.0.0), tibble,"
  dep_new <- "dplyr (>= 1.0.0), tibble"

  result <- compare_dep_fields(dep_new, dep_old)

  expect_equal(result$added, character())
  expect_equal(result$removed, character())
  expect_true(is.null(result$modified) || length(result$modified) == 0)
})


# test-compare_dependencies

test_that("compare_dependencies returns NULL when either input is NULL", {
  expect_null(compare_dependencies(NULL, list(desc = list())))
  expect_null(compare_dependencies(list(desc = list()), NULL))
})

test_that("compare_dependencies returns dependencies list with expected keys", {
  info_old <- list(desc = list(
    Depends  = "R (>= 3.5.0)",
    Imports  = "dplyr (>= 1.0.0), tibble",
    Suggests = "testthat"
  ))
  info_new <- list(desc = list(
    Depends  = "R (>= 3.5.0)",
    Imports  = "dplyr (>= 1.1.0), tidyr",
    Suggests = "testthat, covr"
  ))

  res <- compare_dependencies(info_new, info_old)

  expect_type(res, "list")
  expect_true("dependencies" %in% names(res))
  expect_named(res$dependencies, c("Depends", "Imports", "Suggests"))
})

test_that("compare_dependencies reports no changes when all fields missing in both", {
  info_old <- list(desc = list())
  info_new <- list(desc = list())

  res <- compare_dependencies(info_new, info_old)

  expect_true("dependencies" %in% names(res))
  # Since loop 'next's on all three fields, deps_results will be empty list
  expect_type(res$dependencies, "list")
  expect_equal(length(res$dependencies), 0)
})

test_that("compare_dependencies handles missing field in one version as added/removed", {
  info_old <- list(desc = list(Imports = "dplyr"))
  info_new <- list(desc = list())

  res <- compare_dependencies(info_new, info_old)

  expect_true("Imports" %in% names(res$dependencies))
  expect_equal(res$dependencies$Imports$added, character())
  expect_equal(res$dependencies$Imports$removed, "dplyr")
  expect_true(is.null(res$dependencies$Imports$modified) ||
                length(res$dependencies$Imports$modified) == 0)
})

test_that("compare_dependencies compares all three fields independently", {
  info_old <- list(desc = list(
    Depends  = "R (>= 3.6.0)",
    Imports  = "dplyr (>= 1.0.0)",
    Suggests = "testthat"
  ))
  info_new <- list(desc = list(
    Depends  = "R (>= 4.0.0)",
    Imports  = "dplyr (>= 1.0.0)",
    Suggests = "testthat, covr"
  ))

  res <- compare_dependencies(info_new, info_old)

  expect_true(any(grepl("^R:", res$dependencies$Depends$modified)))
  expect_equal(res$dependencies$Imports$added, character())
  expect_equal(res$dependencies$Imports$removed, character())
  expect_true(is.null(res$dependencies$Imports$modified) ||
                length(res$dependencies$Imports$modified) == 0)

  expect_equal(res$dependencies$Suggests$added, "covr")
  expect_equal(res$dependencies$Suggests$removed, character())
})

test_that("compare_dependencies returns only fields that exist in at least one version", {
  info_old <- list(desc = list(Imports = "dplyr"))
  info_new <- list(desc = list(Suggests = "testthat"))

  res <- compare_dependencies(info_new, info_old)

  expect_true("Imports" %in% names(res$dependencies))
  expect_true("Suggests" %in% names(res$dependencies))
  expect_false("Depends" %in% names(res$dependencies)) # both NULL -> skipped
})

