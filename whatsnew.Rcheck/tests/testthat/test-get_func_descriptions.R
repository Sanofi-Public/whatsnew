test_that("get_func_descriptions reads descriptions", {

  lib <- withr::local_tempdir()
  pkgdir <- withr::local_tempdir()
  pkgname <- "rdonlypkg"

  dir.create(pkgdir, showWarnings = FALSE)
  dir.create(file.path(pkgdir, "man"))

  ## DESCRIPTION
  writeLines(
    c(
      paste0("Package: ", pkgname),
      "Type: Package",
      "Title: Rd-only test package",
      "Version: 0.0.1",
      "Author: Test",
      "Maintainer: Test <test@example.com>",
      "Description: Minimal package containing only Rd files.",
      "License: MIT"
    ),
    con = file.path(pkgdir, "DESCRIPTION")
  )

  ## NAMESPACE (can be empty, but must exist)
  writeLines("", con = file.path(pkgdir, "NAMESPACE"))

  ## Rd file WITH description
  writeLines(
    c(
      "\\name{foo}",
      "\\alias{foo}",
      "\\title{Foo function}",
      "\\description{",
      "Foo does something useful.",
      "}"
    ),
    con = file.path(pkgdir, "man", "foo.Rd")
  )

  ## Rd file WITHOUT description
  writeLines(
    c(
      "\\name{bar}",
      "\\alias{bar}",
      "\\title{Bar function}"
    ),
    con = file.path(pkgdir, "man", "bar.Rd")
  )

  ## Install into temp library and test
  withr::with_libpaths(
    new = lib,
    action = "prefix",
    code = {
      install.packages(pkgdir, lib = lib, repos = NULL, type = "source", quiet = TRUE)

      out <- get_func_descriptions(pkgname)

      expect_type(out, "list")

      # foo should be present with description text
      expect_true("foo" %in% names(out))
      expect_true(is.character(out[["foo"]]))
      expect_match(out[["foo"]], "Foo does something useful")

      # bar should NOT be included (no \\description tag)
      expect_false("bar" %in% names(out))
    }
  )
})

test_that("get_func_descriptions errors for non-existent package", {
  expect_error(get_func_descriptions("thisPackageDoesNotExist123"))
})
