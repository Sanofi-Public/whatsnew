test_that("compare orchestrates helper calls and returns structured diff", {

  calls <- list()

  fake_get_info <- function(pkg, ver) {
    calls$get_info <<- c(calls$get_info, list(list(pkg = pkg, ver = ver)))
    list(pkg = pkg, ver = ver, sentinel = paste0(pkg, "-", ver))
  }

  fake_compare_dependencies <- function(info_new, info_old) {
    calls$compare_dependencies <<- list(info_new = info_new, info_old = info_old)
    list(dep_diff = TRUE, new = info_new$ver, old = info_old$ver)
  }

  fake_compare_funcs <- function(info_new, info_old) {
    calls$compare_funcs <<- list(info_new = info_new, info_old = info_old)
    list(func_diff = TRUE, new = info_new$ver, old = info_old$ver)
  }

  fake_compare_tm <- function(pkg, ver_new, ver_old) {
    calls$compare_tm <<- list(pkg = pkg, ver_new = ver_new, ver_old = ver_old)
    list(tm_diff = TRUE, new = ver_new, old = ver_old)
  }

  testthat::local_mocked_bindings(
    get_info = fake_get_info,
    compare_dependencies = fake_compare_dependencies,
    compare_funcs = fake_compare_funcs,
    compare_tm = fake_compare_tm
  )

  out <- compare("mypkg", "2.0.0", "1.0.0")

  # Structure checks
  expect_type(out, "list")
  expect_equal(out$package, "mypkg")
  expect_equal(out$version_new, "2.0.0")
  expect_equal(out$version_old, "1.0.0")

  expect_named(
    out,
    c("package", "version_new", "version_old",
      "dependencies_diff", "functions_diff", "test_m")
  )

  expect_equal(out$dependencies_diff, list(dep_diff = TRUE, new = "2.0.0", old = "1.0.0"))
  expect_equal(out$functions_diff,     list(func_diff = TRUE, new = "2.0.0", old = "1.0.0"))
  expect_equal(out$test_m,             list(tm_diff = TRUE, new = "2.0.0", old = "1.0.0"))

  expect_length(calls$get_info, 2)
  expect_equal(calls$get_info[[1]], list(pkg = "mypkg", ver = "2.0.0"))
  expect_equal(calls$get_info[[2]], list(pkg = "mypkg", ver = "1.0.0"))

  expect_equal(calls$compare_tm, list(pkg = "mypkg", ver_new = "2.0.0", ver_old = "1.0.0"))

  expect_equal(calls$compare_dependencies$info_new$ver, "2.0.0")
  expect_equal(calls$compare_dependencies$info_old$ver, "1.0.0")
  expect_equal(calls$compare_funcs$info_new$ver, "2.0.0")
  expect_equal(calls$compare_funcs$info_old$ver, "1.0.0")
})

test_that("compare propagates errors from helpers", {
  testthat::local_mocked_bindings(
    get_info = function(...) stop("boom"),
    compare_dependencies = function(...) NULL,
    compare_funcs = function(...) NULL,
    compare_tm = function(...) NULL
  )

  expect_error(
    compare("mypkg", "2.0.0", "1.0.0"),
    "boom"
  )
})



