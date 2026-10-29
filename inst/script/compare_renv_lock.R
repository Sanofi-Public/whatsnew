#' Compare Two renv Lock Files for Risk Assessment
#'
#' Reads two renv lock files, finds package version differences, and runs
#' compare_package_versions for each to generate risk assessment reports.
#'
#' @param lock_old Path to the old lock file. Defaults to package's renv_Rforsub_old.lock.
#' @param lock_new Path to the new lock file. Defaults to package's renv_Rforsub.lock.
#' @param result_path Base output directory. Defaults to \code{tempdir()} (user-writable).
#'
#' @return Invisibly returns the diffs list (version_changed, added, removed).
#'
#' @examples
#' \donttest{
#' library(whatsnew)
#' source(system.file("script/compare_renv_lock.R", package = "whatsnew"))
#' compare_renv_lock_files()
#' compare_renv_lock_files(
#'   lock_old = "inst/env/renv_Rforsub_old.lock",
#'   lock_new = "inst/env/renv_Rforsub.lock",
#'   result_path = "inst/result"
#' )
#' }

library(jsonlite)
library(whatsnew)

# Source funs.R (with fallback when package path not found)
funs_path <- system.file("script/funs.R", package = "whatsnew")
if (!nzchar(funs_path)) funs_path <- "inst/script/funs.R"
source(funs_path, local = FALSE)


# -----------------------------------------------------------------------------
# Main: compare lock files and run compare_package_versions
# -----------------------------------------------------------------------------
compare_renv_lock_files <- function(lock_old = NULL, lock_new = NULL, result_path = NULL) {
  if (is.null(lock_old)) {
    lock_old <- system.file("env/renv_Rforsub_old.lock", package = "whatsnew")
    if (!nzchar(lock_old)) lock_old <- "inst/env/renv_Rforsub_old.lock"
  }
  if (is.null(lock_new)) {
    lock_new <- system.file("env/renv_Rforsub.lock", package = "whatsnew")
    if (!nzchar(lock_new)) lock_new <- "inst/env/renv_Rforsub.lock"
  }
  if (is.null(result_path)) result_path <- tempdir()

  # Ensure funs (including assess_package_risk) are available
  if (!exists("assess_package_risk", mode = "function")) {
    funs_path <- system.file("script/funs.R", package = "whatsnew")
    if (!nzchar(funs_path)) funs_path <- "inst/script/funs.R"
    source(funs_path, local = FALSE)
  }

  # Organized output: renv_lock_comparison/
  out_root <- file.path(result_path, "renv_lock_comparison")
  qmd_path <- file.path(out_root, "package_reports")
  json_path <- file.path(out_root, "json")
  dir.create(qmd_path, recursive = TRUE, showWarnings = FALSE)
  dir.create(json_path, recursive = TRUE, showWarnings = FALSE)

  message("Reading lock files...")
  message("  Old: ", lock_old)
  message("  New: ", lock_new)

  df_old <- parse_renv_lock(lock_old)
  df_new <- parse_renv_lock(lock_new)
  diffs <- compare_renv_packages(df_old, df_new)

  n_changed <- nrow(diffs$version_changed)
  n_added <- nrow(diffs$added)
  n_removed <- nrow(diffs$removed)

  message("\n--- Summary ---")
  message("  Version changed: ", n_changed)
  message("  Added (new only): ", n_added)
  message("  Removed (old only): ", n_removed)

  if (n_changed > 0) {
    message("\nVersion differences:")
    print(diffs$version_changed)
  }
  if (n_added > 0) {
    message("\nAdded packages:")
    print(diffs$added)
  }
  if (n_removed > 0) {
    message("\nRemoved packages:")
    print(diffs$removed)
  }

  # Track risk assessment outcomes and collect diffs for report
  risk_results <- character()
  pkg_diffs <- list()

  if (n_changed > 0) {
    message("\n--- Running compare_package_versions (risk assessment) ---")
    for (i in seq_len(nrow(diffs$version_changed))) {
      pkg <- diffs$version_changed$name[i]
      old_version <- diffs$version_changed$version_old[i]
      new_version <- diffs$version_changed$version_new[i]

      message("  ", pkg, ": ", old_version, " -> ", new_version)

      tryCatch({
        diff <- whatsnew::compare_package_versions(pkg, new_version, old_version)
        make_qmd_from_diff(diff, result_path = qmd_path)
        jsonlite::write_json(diff, file.path(json_path, paste0(pkg, "_", old_version, "_to_", new_version, ".json")), pretty = TRUE)
        pkg_diffs[[pkg]] <- diff
        risk_results[pkg] <- "OK"
        message("    -> OK")
      }, error = function(e) {
        msg <- conditionMessage(e)
        message("    -> FAILED: ", msg)
        warning("compare_package_versions failed for ", pkg, ": ", msg)
        risk_results[pkg] <<- paste0("FAILED: ", msg)
      })
    }
  }

  # Risk assessment per package
  risk_assessments <- list()
  if (length(pkg_diffs) > 0) {
    for (pkg in names(pkg_diffs)) {
      risk_assessments[[pkg]] <- assess_package_risk(pkg_diffs[[pkg]])
    }
  }

  # Save risk report JSON
  risk_report <- list(
    generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    lock_old = lock_old,
    lock_new = lock_new,
    summary = list(
      version_changed = n_changed,
      added = n_added,
      removed = n_removed
    ),
    risk_assessments = risk_assessments,
    compare_status = as.list(risk_results)
  )
  risk_report_file <- file.path(out_root, "risk_report.json")
  jsonlite::write_json(risk_report, risk_report_file, pretty = TRUE)

  # Shorten paths for report (strip project root)
  lock_old_short <- tryCatch(shorten_path(lock_old), error = function(e) lock_old)
  lock_new_short <- tryCatch(shorten_path(lock_new), error = function(e) lock_new)
  out_root_short <- tryCatch(shorten_path(out_root), error = function(e) out_root)
  qmd_path_short <- tryCatch(shorten_path(qmd_path), error = function(e) qmd_path)
  json_path_short <- tryCatch(shorten_path(json_path), error = function(e) json_path)
  result_path_short <- tryCatch(shorten_path(result_path), error = function(e) result_path)

  # Build report
  report_lines <- c(
    "# renv Lock File Comparison Report",
    paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "",
    "## Run Parameters",
    paste0("- lock_old: ", lock_old_short),
    paste0("- lock_new: ", lock_new_short),
    paste0("- result_path: ", result_path_short),
    "",
    "## Summary",
    paste0("- Version changed: ", n_changed),
    paste0("- Added (new only): ", n_added),
    paste0("- Removed (old only): ", n_removed),
    ""
  )

  if (n_changed > 0) {
    report_lines <- c(report_lines,
      "## Version Changes",
      "",
      paste(utils::capture.output(print(diffs$version_changed)), collapse = "\n"),
      ""
    )
  }

  if (n_added > 0) {
    report_lines <- c(report_lines,
      "## Added Packages",
      "",
      paste(utils::capture.output(print(diffs$added)), collapse = "\n"),
      ""
    )
  }

  if (n_removed > 0) {
    report_lines <- c(report_lines,
      "## Removed Packages",
      "",
      paste(utils::capture.output(print(diffs$removed)), collapse = "\n"),
      ""
    )
  }

  if (length(risk_results) > 0) {
    report_lines <- c(report_lines,
      "## Compare Status",
      "",
      paste0("- ", names(risk_results), ": ", risk_results),
      ""
    )
  }

  # Package-by-package report (risk + details per package)
  if (length(pkg_diffs) > 0) {
    report_lines <- c(report_lines, "## Package Reports", "")
    for (pkg in names(pkg_diffs)) {
      d <- pkg_diffs[[pkg]]
      r <- risk_assessments[[pkg]]
      old_v <- d$version_old[[1]]
      new_v <- d$version_new[[1]]

      report_lines <- c(report_lines,
        paste0("### ", pkg, " (", old_v, " → ", new_v, ")"),
        "",
        paste0("- **Risk level:** ", r$risk_level),
        paste0("- **Recommendation:** ", r$recommendation),
        ""
      )
      if (length(r$actions) > 0) {
        report_lines <- c(report_lines, "**Actions:**", paste0("- ", r$actions), "")
      }
      if (length(r$dependency_risks) > 0) {
        report_lines <- c(report_lines, "**Dependency risks:**", "")
        for (n in names(r$dependency_risks)) {
          dr <- r$dependency_risks[[n]]
          report_lines <- c(report_lines,
            paste0("- ", n, " [", dr$risk, "]: ", paste(dr$items, collapse = ", "), " — ", dr$note),
            ""
          )
        }
      }
      if (length(r$function_risks) > 0) {
        report_lines <- c(report_lines, "**Function risks:**", "")
        for (n in names(r$function_risks)) {
          fr <- r$function_risks[[n]]
          report_lines <- c(report_lines,
            paste0("- ", n, " [", fr$risk, "]: ", paste(fr$functions, collapse = ", "), " — ", fr$note),
            ""
          )
        }
      }

      deps <- d$dependencies_diff$dependencies
      if (!is.null(deps)) {
        for (block in c("Depends", "Imports", "Suggests")) {
          b <- deps[[block]]
          if (!is.null(b) && (length(b$added) > 0 || length(b$removed) > 0 || length(b$modified) > 0)) {
            report_lines <- c(report_lines, paste0("**", block, ":**"), "")
            if (length(b$added) > 0) report_lines <- c(report_lines, paste0("- Added: ", paste(b$added, collapse = ", ")), "")
            if (length(b$removed) > 0) report_lines <- c(report_lines, paste0("- Removed: ", paste(b$removed, collapse = ", ")), "")
            if (length(b$modified) > 0) report_lines <- c(report_lines, paste0("- Modified: ", paste(b$modified, collapse = ", ")), "")
            report_lines <- c(report_lines, "")
          }
        }
      }
      fns <- d$functions_diff
      if (!is.null(fns)) {
        if (length(fns$added) > 0) {
          report_lines <- c(report_lines, "**Functions (Added) with params:**", "")
          for (fn in names(fns$added)) {
            fmls <- fns$added[[fn]]
            args <- tryCatch(if (is.list(fmls)) paste(whatsnew::format_formals(fmls), collapse = ", ") else "", error = function(e) "")
            report_lines <- c(report_lines, paste0("- ", fn, "(", args, ")"), "")
          }
        }
        if (length(fns$removed) > 0) {
          report_lines <- c(report_lines, "**Functions (Removed) with params:**", "")
          for (fn in names(fns$removed)) {
            fmls <- fns$removed[[fn]]
            args <- tryCatch(if (is.list(fmls)) paste(whatsnew::format_formals(fmls), collapse = ", ") else "", error = function(e) "")
            report_lines <- c(report_lines, paste0("- ", fn, "(", args, ")"), "")
          }
        }
        if (length(fns$modified) > 0) {
          report_lines <- c(report_lines, "**Functions (Modified) - params changed:**", "")
          for (fn in names(fns$modified)) {
            m <- fns$modified[[fn]]
            old_args <- tryCatch(if (is.list(m$old)) paste(whatsnew::format_formals(m$old), collapse = ", ") else "", error = function(e) "")
            new_args <- tryCatch(if (is.list(m$new)) paste(whatsnew::format_formals(m$new), collapse = ", ") else "", error = function(e) "")
            report_lines <- c(report_lines,
              paste0("- ", fn, ":"),
              paste0("  - ", old_v, ": (", paste(old_args, collapse = ", "), ")"),
              paste0("  + ", new_v, ": (", paste(new_args, collapse = ", "), ")"),
              ""
            )
          }
        }
      }
      report_lines <- c(report_lines, "")
    }
  }

  report_lines <- c(report_lines,
    "## Output",
    paste0("- Report: ", out_root_short),
    paste0("- Risk report (JSON): ", shorten_path(risk_report_file)),
    paste0("- QMD: ", qmd_path_short),
    paste0("- JSON: ", json_path_short),
    ""
  )

  report_file <- file.path(out_root, "report.md")
  writeLines(report_lines, report_file)
  message("\nOutput saved:")
  message("  Report:      ", report_file)
  message("  Risk report: ", risk_report_file)
  message("  QMDs:       ", qmd_path)
  message("  JSON:       ", json_path)

  invisible(diffs)
}


# Auto-run only when sourced interactively (e.g. R CMD batch), not during vignette build
if (interactive() && identical(parent.frame(), .GlobalEnv)) {
  compare_renv_lock_files()
}



