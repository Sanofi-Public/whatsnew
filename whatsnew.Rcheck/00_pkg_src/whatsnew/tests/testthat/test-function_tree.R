# load_fixture_graph

test_that("Test load stringr package igraph object", {
  g <- load_fixture_graph("stringr_call_graph.rds")
  expect_s3_class(g, "igraph")
})


test_that("Test load stringr package igraph object with snapshot value", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  # Convert the igraph object to a stable JSON representation
  stable_graph <- igraph::as_data_frame(g, what = "both")

  expect_snapshot_value(
    stable_graph, style = "json2"
  )

})

# function_tree

test_that("function_tree() errors on unknown root", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  expect_error(
    function_tree("stringr", root = "this_function_does_not_exist"),
    regexp = "not found in the package call graph"
  )
})

test_that("function_tree() errors on unknown root", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  expect_error(
    function_tree("stringr", root = "this_function_does_not_exist"),
    regexp = "not found in the package call graph"
  )
})

test_that("function_tree() basic shape and metadata", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")
  ft <- function_tree("stringr", root = "str_detect", direction = "downstream")

  expect_type(ft, "list")
  expect_true("stringr" %in% names(ft))
  expect_true(is.character(ft$stringr$version))
  expect_match(ft$stringr$version, "^[0-9]+\\.[0-9]+\\.[0-9]+")
  expect_true("str_detect" %in% names(ft$stringr))
})

test_that("depth limiting preserves leaf names as NULL (stored as list(NULL))", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft1 <- function_tree("stringr", root = "str_detect", depth = 1, direction = "downstream")
  root_children <- ft1$stringr$`str_detect`

  skip_if(is.null(root_children), "Root has no neighbors at depth 1 in this fixture")
  expect_type(root_children, "list")
})

test_that("upstream vs downstream produce different traversals", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  down <- function_tree("stringr", root = "str_to_upper", depth = 2, direction = "downstream")
  up   <- function_tree("stringr", root = "str_to_upper", depth = 2, direction = "upstream")

  down_children <- down$stringr$`str_to_upper`
  up_children   <- up$stringr$`str_to_upper`

  expect_false(identical(names(down_children), names(up_children)))
})

test_that("default roots are sources/sinks depending on direction", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  down <- function_tree("stringr", depth = 1, direction = "downstream")
  up   <- function_tree("stringr", depth = 1, direction = "upstream")

  expect_true(length(setdiff(names(down$stringr), "version")) >= 1)
  expect_true(length(setdiff(names(up$stringr),   "version")) >= 1)
})

test_that("namespace in root is accepted", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft <- function_tree("stringr", root = "stringr::str_trim", depth = 1, direction = "downstream")
  expect_true("str_trim" %in% names(ft$stringr))
})


# print_function_tree

test_that("stringr package", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph   = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "requireNamespace", function(...) TRUE)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft <- function_tree("stringr", pkg_version= "1.5.2")
  expect_snapshot(suppressWarnings(print_function_tree(ft)))
})

test_that("stringr package downstream", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph   = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "requireNamespace", function(...) TRUE)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft1 <- function_tree(
    "stringr",
    root = "str_detect",
    depth = 3,
    direction = "downstream",
    pkg_version = "1.5.2"
  )

  expect_snapshot(print_function_tree(ft1))
})

test_that("stringr package upstream", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph   = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "requireNamespace", function(...) TRUE)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft2 <- function_tree(
    "stringr",
    root = "str_detect",
    depth = 3,
    direction = "upstream",
    pkg_version = "1.5.2"
  )

  expect_snapshot(print_function_tree(ft2))
})



# function_tree

test_that("function_tree() errors on unknown root", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  expect_error(
    function_tree("stringr", root = "this_function_does_not_exist"),
    regexp = "not found in the package call graph"
  )
})

test_that("function_tree() basic shape and metadata", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")
  ft <- function_tree("stringr", root = "str_detect", direction = "downstream")

  expect_type(ft, "list")
  expect_true("stringr" %in% names(ft))
  expect_true(is.character(ft$stringr$version))
  expect_match(ft$stringr$version, "^[0-9]+\\.[0-9]+\\.[0-9]+")
  expect_true("str_detect" %in% names(ft$stringr))
})

test_that("depth limiting preserves leaf names as NULL (stored as list(NULL))", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft1 <- function_tree("stringr", root = "str_detect", depth = 1, direction = "downstream")
  root_children <- ft1$stringr$`str_detect`

  skip_if(is.null(root_children), "Root has no neighbors at depth 1 in this fixture")
  expect_type(root_children, "list")
})

test_that("upstream vs downstream produce different traversals", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  down <- function_tree("stringr", root = "str_to_upper", depth = 2, direction = "downstream")
  up   <- function_tree("stringr", root = "str_to_upper", depth = 2, direction = "upstream")

  down_children <- down$stringr$`str_to_upper`
  up_children   <- up$stringr$`str_to_upper`

  expect_false(identical(names(down_children), names(up_children)))
})

test_that("default roots are sources/sinks depending on direction", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  down <- function_tree("stringr", depth = 1, direction = "downstream")
  up   <- function_tree("stringr", depth = 1, direction = "upstream")

  expect_true(length(setdiff(names(down$stringr), "version")) >= 1)
  expect_true(length(setdiff(names(up$stringr),   "version")) >= 1)
})

test_that("namespace in root is accepted", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft <- function_tree("stringr", root = "stringr::str_trim", depth = 1, direction = "downstream")
  expect_true("str_trim" %in% names(ft$stringr))
})


# prune_set params non null

test_that("stringr package prune one function", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph   = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "requireNamespace", function(...) TRUE)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft2 <- function_tree(
    "stringr",
    prune = "str_detect",
    pkg_version = "1.5.2"
  )

  expect_true("version" %in% names(ft2$stringr))
  expect_true("str_detect" %in% names(ft2$stringr))
  expect_snapshot(print_function_tree(ft2))

})


test_that("stringr package prune multiples functions", {
  g <- load_fixture_graph("stringr_call_graph.rds")

  fake_fr <- list(
    set_package = function(pkg_name) invisible(TRUE),
    pkg_graph   = list(igraph = g)
  )

  mockery::stub(function_tree, "pkgnet::FunctionReporter$new", fake_fr)
  mockery::stub(function_tree, "requireNamespace", function(...) TRUE)
  mockery::stub(function_tree, "utils::packageVersion", function(...) "1.5.2")

  ft2 <- function_tree(
    "stringr",
    prune = c("str_detect", "str_view_all"),
    pkg_version = "1.5.2"
  )

  expect_true("version" %in% names(ft2$stringr))
  expect_true("str_detect" %in% names(ft2$stringr))
  expect_true("str_view_all" %in% names(ft2$stringr))
  expect_snapshot(print_function_tree(ft2))

})








