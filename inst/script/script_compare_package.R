#' Compare specific package versions and save as JSON
#'
#' Examples: dplyr 1.0.9 -> 1.1.4, admiral 1.1.1 -> 1.2.0

library(jsonlite)
library(whatsnew)
source(system.file("script/funs.R", package = "whatsnew"), local = FALSE)

# Prefer inst/result when developing; otherwise use tempdir() (user-writable)
if (dir.exists("inst/result")) {
  result_path <- normalizePath("inst/result", mustWork = FALSE)
} else {
  result_path <- tempdir()
}
json_dir <- file.path(result_path, "package_json")
dir.create(json_dir, showWarnings = FALSE, recursive = TRUE)


# -----------------------------------------------------------------------------
# Compare dplyr
# -----------------------------------------------------------------------------
pkg_diff <- whatsnew::compare_package_versions("dplyr", "1.1.4", "1.0.9")
path <- file.path(json_dir, "dplyr.json")
jsonlite::write_json(pkg_diff, path, pretty = TRUE)


# -----------------------------------------------------------------------------
# Compare admiral
# -----------------------------------------------------------------------------
pkg_diff <- whatsnew::compare_package_versions("admiral", "1.2.0", "1.1.1")
path <- file.path(json_dir, "admiral.json")
jsonlite::write_json(pkg_diff, path, pretty = TRUE)

message("Output saved to: ", json_dir)
