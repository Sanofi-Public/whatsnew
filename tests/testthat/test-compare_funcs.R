test_that("compare_funcs detects added, removed, and modified functions", {
  new <- list(functions = list(
    a = list(x = NULL),
    b = list(y = 1),
    c = list(z = "hi")
  ))

  old <- list(functions = list(
    a = list(x = NULL),
    b = list(y = 2),
    d = list(w = NULL)
  ))

  out <- compare_funcs(new, old)

  expect_type(out, "list")
  expect_named(out, c("added", "removed", "modified"))

  expect_named(out$added, "c")
  expect_true("c" %in% names(out$added))
  expect_false("a" %in% names(out$added))
  expect_false("b" %in% names(out$added))

  expect_named(out$removed, "d")
  expect_true("d" %in% names(out$removed))
  expect_false("a" %in% names(out$removed))
  expect_false("b" %in% names(out$removed))

  expect_true("b" %in% names(out$modified))
  expect_false("a" %in% names(out$modified))
  expect_equal(out$modified$b$old, list(y = 2))
  expect_equal(out$modified$b$new, list(y = 1))
})

test_that("compare_funcs ignores NA and empty names", {
  new_funcs <- list(list(x = 1), list(y = 2), good = list(z = 3))
  names(new_funcs)[1] <- NA_character_
  names(new_funcs)[2] <- ""

  old_funcs <- list(list(a = 1), also_good = list(b = 2))
  names(old_funcs)[1] <- ""

  out <- compare_funcs(
    list(functions = new_funcs),
    list(functions = old_funcs)
  )

  expect_true("good" %in% names(out$added))
  expect_true("also_good" %in% names(out$removed))

  expect_false(any(is.na(names(out$added))))
  expect_false(any(names(out$added) == ""))
  expect_false(any(is.na(names(out$removed))))
  expect_false(any(names(out$removed) == ""))
})

test_that("compare_funcs returns empty structures when identical", {
  funcs <- list(functions = list(
    a = list(x = NULL),
    b = list(y = 1)
  ))

  out <- compare_funcs(funcs, funcs)

  expect_length(out$added, 0)
  expect_length(out$removed, 0)
  expect_length(out$modified, 0)

  expect_true(identical(names(out$added), character(0)))
  expect_true(identical(names(out$removed), character(0)))
  expect_true(is.null(names(out$modified)))
})

test_that("compare_funcs treats different ordering as modified (identical is strict)", {
  new <- list(functions = list(f = list(a = 1, b = 2)))
  old <- list(functions = list(f = list(b = 2, a = 1)))

  out <- compare_funcs(new, old)

  expect_true("f" %in% names(out$modified))
  expect_equal(out$modified$f$old, list(b = 2, a = 1))
  expect_equal(out$modified$f$new, list(a = 1, b = 2))
})
