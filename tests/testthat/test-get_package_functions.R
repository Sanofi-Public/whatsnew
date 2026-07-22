test_that("errors if no R/ directory exists", {
  tmp <- withr::local_tempdir()
  expect_error(
    get_package_functions(tmp),
    "No R/ directory found"
  )
})

test_that("extracts function names and parameter defaults from R files", {
  pkg <- withr::local_tempdir()
  rdir <- file.path(pkg, "R")
  dir.create(rdir, recursive = TRUE)

  # File 1: normal functions + non-function assignment
  writeLines(
    c(
      "f1 <- function(a, b = 1, c = 'x') a + b",
      "not_a_func <- 123",
      "f2 <- function(x = c(1, 2), y = quote(z)) list(x, y)"
    ),
    con = file.path(rdir, "file1.R")
  )

  # File 2: function with no defaults + complex default expression
  writeLines(
    c(
      "f3 <- function(p, q, r = list(a = 1, b = 2)) r",
      "f4 <- function(u = { 1 + 2 }, v) u"
    ),
    con = file.path(rdir, "file2.R")
  )

  out <- get_package_functions(pkg)

  expect_type(out, "list")
  expect_true(all(c("f1", "f2", "f3", "f4") %in% names(out)))
  expect_false("not_a_func" %in% names(out))

  # f1 params: a has no default -> NULL
  expect_equal(out$f1$a, NULL)
  expect_equal(out$f1$b, 1)
  expect_equal(out$f1$c, "x")

  # f2 defaults are language; should be deparse() strings
  # (deparse can return length > 1 sometimes, so collapse for stable checks)
  expect_match(paste(out$f2$x, collapse = " "), "c\\(1, 2\\)")
  expect_match(paste(out$f2$y, collapse = " "), "quote\\(z\\)")

  # f3: list(...) is language -> deparse string
  expect_equal(out$f3$p, NULL)
  expect_equal(out$f3$q, NULL)
  expect_match(paste(out$f3$r, collapse = " "), "list\\(a = 1, b = 2\\)")

  # f4: block default is language -> deparse string; v has no default
  expect_match(paste(out$f4$u, collapse = " "), "\\{")
  expect_equal(out$f4$v, NULL)
})

test_that("skips files that fail to parse", {
  pkg <- withr::local_tempdir()
  rdir <- file.path(pkg, "R")
  dir.create(rdir, recursive = TRUE)

  # Good file
  writeLines("ok <- function(a = 1) a", con = file.path(rdir, "good.R"))

  # Bad file (parse error)
  writeLines("bad <- function( {", con = file.path(rdir, "bad.R"))

  out <- get_package_functions(pkg)

  expect_true("ok" %in% names(out))
  expect_false("bad" %in% names(out))
})
