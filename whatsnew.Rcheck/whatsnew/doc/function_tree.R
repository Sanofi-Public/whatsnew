## -----------------------------------------------------------------------------
library(risk.assessr)
library(whatsnew)

ft <- whatsnew::function_tree("risk.assessr")
ft

## -----------------------------------------------------------------------------
ft1 <-  whatsnew::function_tree("risk.assessr", root = "assess_pkg_r_package", depth = 3, direction = "downstream")
str(ft1, max.level = 3)

## -----------------------------------------------------------------------------
ft2 <-  whatsnew::function_tree("risk.assessr", root = "assess_pkg_r_package", depth = 3, direction = "upstream")
str(ft2, max.level = 3)

## -----------------------------------------------------------------------------
 whatsnew::print_function_tree(ft)

## -----------------------------------------------------------------------------
here_version <- "1.0.1"  # Version of `here` used to generate test archive
temp_file <- tryCatch(system.file("test-data", "here_101.tar.gz", package = "whatsnew"))

temp_dir <- tempfile()
dir.create(temp_dir)

untar(temp_file, exdir = temp_dir)
pkg_source_path <- list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)[1]

exports_df <- risk.assessr::get_exports(pkg_source_path)

## -----------------------------------------------------------------------------
exports_df$exported_function

## -----------------------------------------------------------------------------
# pkgnet analyses the installed package; its namespace must be attached.
library(here)

## -----------------------------------------------------------------------------
res <- function_tree("here")
print_function_tree(res)

## -----------------------------------------------------------------------------
res <- function_tree("here", prune = exports_df$exported_function)
print_function_tree(res)

