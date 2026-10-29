test_that("get_func_descriptions reads descriptions", {

  pkgdir <- withr::local_tempdir()
  pkgname <- "rdonlypkg"

  dir.create(file.path(pkgdir, "man"), recursive = TRUE)

  ## DESCRIPTION (required by tools::Rd_db(dir=) for package metadata;
  ## no installation is performed)
  writeLines(
    c(
      paste0("Package: ", pkgname),
      "Type: Package",
      "Title: Rd-only test package",
      "Version: 0.0.1",
      "Author: Test",
      "Maintainer: Test <test@example.com>",
      "Description: Minimal package containing only Rd files.",
      "License: MIT",
      "Encoding: UTF-8"
    ),
    con = file.path(pkgdir, "DESCRIPTION")
  )

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

  ## Build the Rd db directly from the source directory (no installation
  ## needed) and stub tools::Rd_db so get_func_descriptions() uses it.
  rd_db <- tools::Rd_db(dir = pkgdir)
  mockery::stub(get_func_descriptions, "tools::Rd_db", rd_db)

  out <- get_func_descriptions(pkgname)

  expect_type(out, "list")

  # foo should be present with description text
  expect_true("foo" %in% names(out))
  expect_true(is.character(out[["foo"]]))
  expect_match(out[["foo"]], "Foo does something useful")

  # bar should NOT be included (no \\description tag)
  expect_false("bar" %in% names(out))
})

test_that("get_func_descriptions errors for non-existent package", {
  expect_error(get_func_descriptions("thisPackageDoesNotExist123"))
})
