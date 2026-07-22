test_that("print_func_diff prints expected diff output", {
  func_cmp <- list(
    added = list(
      new_func = list(x = NULL, y = "1")
    ),
    removed = list(
      old_func = list(a = NULL)
    ),
    modified = list(
      mod_func = list(
        old = list(foo = NULL, bar = "TRUE"),
        new = list(foo = NULL, bar = "FALSE", baz = "\"new\"")
      )
    )
  )

  expect_snapshot({
    print_func_diff(func_cmp, old_version = "1.0.0", new_version = "2.0.0")
  })
})

test_that("format_formals formats arguments correctly", {
  fmls <- list(
    x = NULL,                  # no default
    y = "1",                   # numeric default
    z = "\"hello\"",           # character default with quotes
    w = "TRUE",                # logical default
    v = "list()"               # more complex default
  )

  result <- format_formals(fmls)

  expect_equal(result[1], "x")
  expect_equal(result[2], "y = 1")
  expect_equal(result[3], "z = \"hello\"")
  expect_equal(result[4], "w = TRUE")
  expect_equal(result[5], "v = list()")

  expect_type(result, "character")
  expect_length(result, 5)
})
