## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(whatsnew)

## ----run-comparison, eval = FALSE---------------------------------------------
# source(system.file("script/compare_renv_lock.R", package = "whatsnew"))
# compare_renv_lock_files()  # Uses default lock files and tempdir() for output
# 
# # Or with explicit paths:
# compare_renv_lock_files(
#   lock_old = system.file("env/renv_Rforsub_old.lock", package = "whatsnew"),
#   lock_new = system.file("env/renv_Rforsub.lock", package = "whatsnew"),
#   result_path = tempdir()
# )

## ----show-report, echo = FALSE, results = "asis"------------------------------
report_path <- system.file("result/renv_lock_comparison/report.md", package = "whatsnew")
if (nzchar(report_path) && file.exists(report_path)) {
  report_lines <- readLines(report_path)
  cat(paste(report_lines, collapse = "\n"))
} else {
  cat("*Pre-generated report not found. Run `compare_renv_lock_files()` to generate a report.*\n\n")
  cat("**Report structure:**\n\n")
  cat("1. **Run Parameters** – lock file paths and output directory\n")
  cat("2. **Summary** – count of version-changed, added, and removed packages\n")
  cat("3. **Version Changes** – table of packages with version diffs\n")
  cat("4. **Compare Status** – OK/FAILED per package\n")
  cat("5. **Package Reports** – for each package: risk level, recommendation, actions, dependency/function risks, dependencies, function signatures\n")
}

