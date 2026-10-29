# tests/testthat/test-get_pkg_desc.R

test_that("get_pkg_desc reads DESCRIPTION correctly", {
  # Create temp directory and file
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")

  desc_content <- paste0(
    "Package: mypkg\n",
    "Version: 1.2.3\n",
    "Depends: R (>= 4.0.0)\n",
    "Imports: dplyr, stringr\n"
  )

  writeLines(desc_content, desc_path)

  # Use get_pkg_desc
  pkg_desc <- get_pkg_desc(temp_dir)

  expect_type(pkg_desc, "list")
  expect_true(all(c("Package", "Version", "Depends", "Imports") %in% names(pkg_desc)))
  expect_equal(pkg_desc$Package, "mypkg")
  expect_equal(pkg_desc$Version, "1.2.3")

  # Should parse full fields
  expect_equal(pkg_desc$Depends, "R (>= 4.0.0)")
  expect_equal(pkg_desc$Imports, "dplyr, stringr")

  # Test selecting specific fields
  pkg_desc_fields <- get_pkg_desc(temp_dir, fields = c("Package", "Version"))
  expect_equal(names(pkg_desc_fields), c("Package", "Version"))
  expect_equal(pkg_desc_fields$Package, "mypkg")
})

test_that("get_pkg_desc returns error for missing DESCRIPTION", {
  temp_dir <- withr::local_tempdir()

  expect_error(
    get_pkg_desc(temp_dir),
    regexp = "DESCRIPTION not found"
  )
})
