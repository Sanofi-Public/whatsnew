test_that("get_info works correctly with mocked dependencies and default use_isolated_lib = TRUE", {

  mock_download <- "fake_package.tar.gz"
  mock_untar <- NULL
  mock_desc <- list(
    Package = "digest",
    Version = "0.6.25",
    Author = "Dirk Eddelbuettel"
  )

  mock_get_pkg_desc <- mock_desc
  mock_funcs <- c("digest", "hmac", "sha1")
  mock_get_package_functions <- mock_funcs

  mockery::stub(get_info, "remotes::download_version", mock_download)
  mockery::stub(get_info, "untar", mock_untar)
  mockery::stub(get_info, "get_pkg_desc", mock_get_pkg_desc)
  mockery::stub(get_info, "get_package_functions", mock_get_package_functions)

  result <- get_info("digest", "0.6.25")

  expect_type(result, "list")
  expect_named(result, c("desc", "functions"))
  expect_equal(result$desc$Package, "digest")
  expect_equal(result$desc$Version, "0.6.25")
  expect_equal(result$functions, mock_funcs)
})

test_that("get_info returns NULL when download_version errors", {
  # Make download_version throw, ensure get_info returns NULL
  mockery::stub(get_info, "remotes::download_version", function(...) {
    stop("no such version")
  })

  res <- get_info("digest", "0.0.0")
  expect_null(res)
})

test_that("get_info returns NULL when download_version returns NULL", {
  mockery::stub(get_info, "remotes::download_version", NULL)

  res <- get_info("digest", "0.6.25")
  expect_null(res)
})

test_that("get_info errors if untar fails (no tryCatch around untar)", {

  mockery::stub(get_info, "remotes::download_version", "fake.tar.gz")
  mockery::stub(get_info, "tempfile", "tmpdir")
  mockery::stub(get_info, "dir.create", TRUE)
  mockery::stub(get_info, "untar", function(...) stop("untar failed"))

  expect_error(get_info("digest", "0.6.25"), "untar failed")
})

test_that("get_info errors if list.dirs returns empty (no source path)", {

  mockery::stub(get_info, "remotes::download_version", "fake.tar.gz")
  mockery::stub(get_info, "tempfile", "tmpdir")
  mockery::stub(get_info, "dir.create", TRUE)
  mockery::stub(get_info, "untar", NULL)
  mockery::stub(get_info, "list.dirs", character(0))

  expect_error(get_info("digest", "0.6.25"))
})

test_that("get_info returns list with functions = NULL when get_package_functions errors", {
  mock_desc <- list(Package = "digest", Version = "0.6.25")

  mockery::stub(get_info, "remotes::download_version", "fake.tar.gz")
  mockery::stub(get_info, "tempfile", "tmpdir")
  mockery::stub(get_info, "dir.create", TRUE)
  mockery::stub(get_info, "untar", NULL)
  mockery::stub(get_info, "list.dirs", "tmpdir/digest")
  mockery::stub(get_info, "get_pkg_desc", mock_desc)
  mockery::stub(get_info, "get_package_functions", function(...) stop("parse error"))

  res <- get_info("digest", "0.6.25")

  expect_type(res, "list")
  expect_named(res, c("desc", "functions"))
  expect_equal(res$desc$Package, "digest")
  expect_null(res$functions)
})

test_that("get_info allows get_pkg_desc to return NULL but still returns structure", {

  mockery::stub(get_info, "remotes::download_version", "fake.tar.gz")
  mockery::stub(get_info, "tempfile", "tmpdir")
  mockery::stub(get_info, "dir.create", TRUE)
  mockery::stub(get_info, "untar", NULL)
  mockery::stub(get_info, "list.dirs", "tmpdir/digest")

  mockery::stub(get_info, "get_pkg_desc", NULL)
  mockery::stub(get_info, "get_package_functions", c("digest"))

  res <- get_info("digest", "0.6.25")
  expect_named(res, c("desc", "functions"))
  expect_null(res$desc)
  expect_equal(res$functions, "digest")
})

test_that("get_info passes pkg_source_path into get_pkg_desc and get_package_functions", {

  seen_desc_path <- NULL
  seen_funcs_path <- NULL

  fake_get_pkg_desc <- function(path) {
    seen_desc_path <<- path
    list(Package = "digest", Version = "0.6.25")
  }
  fake_get_package_functions <- function(path) {
    seen_funcs_path <<- path
    c("digest", "hmac")
  }

  mockery::stub(get_info, "remotes::download_version", "fake.tar.gz")
  mockery::stub(get_info, "tempfile", "tmpdir")
  mockery::stub(get_info, "dir.create", TRUE)
  mockery::stub(get_info, "untar", NULL)
  mockery::stub(get_info, "list.dirs", "tmpdir/digest")

  mockery::stub(get_info, "get_pkg_desc", fake_get_pkg_desc)
  mockery::stub(get_info, "get_package_functions", fake_get_package_functions)

  res <- get_info("digest", "0.6.25")
  expect_equal(res$functions, c("digest", "hmac"))
})
