# -----------------------------------------------------------------------------
# inst/script/funs.R - Shared functions for comparison scripts
# -----------------------------------------------------------------------------
# Used by: compare_renv_lock.R, script_compare_package.R
# Source: source(system.file("script/funs.R", package = "whatsnew"), local = FALSE)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Shorten path for report (parent folder + filename)
# -----------------------------------------------------------------------------
shorten_path <- function(path) {
  if (is.null(path) || !nzchar(path)) return(path)
  path <- gsub("[/\\\\]+", "/", path)
  parts <- strsplit(path, "/", fixed = TRUE)[[1]]
  if (length(parts) <= 1) return(basename(path))
  paste(parts[length(parts) - 1L], parts[length(parts)], sep = "/")
}


# -----------------------------------------------------------------------------
# QMD report from compare_package_versions diff
# -----------------------------------------------------------------------------
make_qmd_from_diff <- function(diff, result_path = ".") {
  pkg         <- diff$package[[1]]
  old_version <- diff$version_old[[1]]
  new_version <- diff$version_new[[1]]

  section_header <- function(txt) paste0("-- ", txt, " --")

  fmt_dep_block <- function(block_name, block) {
    out <- character()
    add <- block$added
    rem <- block$removed
    mod <- block$modified
    if (length(add) > 0) {
      out <- c(out, "  Added:")
      out <- c(out, paste0("     ", add, collapse = "\n"))
    }
    if (length(rem) > 0) {
      out <- c(out, "  Removed:")
      out <- c(out, paste0("     ", rem, collapse = "\n"))
    }
    if (length(mod) > 0) {
      out <- c(out, "  Modified:")
      out <- c(out, paste0("     ", mod, collapse = "\n"))
    }
    if (length(out) == 0) return(character())
    c(section_header(block_name), out, "")
  }

  deps <- diff$dependencies_diff$dependencies
  dep_lines <- c(
    fmt_dep_block("Depends",  deps$Depends),
    fmt_dep_block("Imports",  deps$Imports),
    fmt_dep_block("Suggests", deps$Suggests)
  )
  dep_lines <- dep_lines[nzchar(dep_lines)]

  fns <- diff$functions_diff
  fn_lines <- character()
  if (!is.null(fns$added) && length(fns$added) > 0) {
    fn_lines <- c(fn_lines, section_header("Functions (Added)"),
                  paste0("  ", names(fns$added)), "")
  }
  if (!is.null(fns$removed) && length(fns$removed) > 0) {
    fn_lines <- c(fn_lines, section_header("Functions (Removed)"),
                  paste0("  ", names(fns$removed)), "")
  }
  if (!is.null(fns$modified) && length(fns$modified) > 0) {
    fn_lines <- c(fn_lines, section_header("Functions (Modified)"),
                  paste0("  ", names(fns$modified)), "")
  }

  output <- paste(c(dep_lines, fn_lines), collapse = "\n")
  qmd_header <- c(
    "---",
    paste0("title: \"", pkg, " ", old_version, " → ", new_version, "\""),
    "format: html",
    "---",
    ""
  )
  qmd_body <- c("```", output, "```")
  outfile <- file.path(result_path, paste0(pkg, "_", old_version, "_to_", new_version, ".qmd"))
  writeLines(c(qmd_header, qmd_body), outfile)
  invisible(outfile)
}


# -----------------------------------------------------------------------------
# Parse renv lock file and extract package names + versions
# -----------------------------------------------------------------------------
parse_renv_lock <- function(lock_path) {
  if (!file.exists(lock_path)) {
    stop("Lock file not found: ", lock_path)
  }
  raw <- jsonlite::fromJSON(lock_path, simplifyVector = TRUE, simplifyDataFrame = FALSE)

  packages <- raw$Packages
  if (is.null(packages) || length(packages) == 0) {
    return(data.frame(name = character(), version = character(), stringsAsFactors = FALSE))
  }

  pkg_names <- names(packages)
  versions <- vapply(packages, function(x) {
    v <- x[["Version"]]
    if (is.null(v)) NA_character_ else as.character(v)
  }, character(1))

  data.frame(
    name = pkg_names,
    version = versions,
    stringsAsFactors = FALSE
  )
}


# -----------------------------------------------------------------------------
# Compare two package data.frames (renv lock format)
# -----------------------------------------------------------------------------
compare_renv_packages <- function(df_old, df_new) {
  merged <- merge(
    df_old[, c("name", "version")],
    df_new[, c("name", "version")],
    by = "name",
    all = TRUE,
    suffixes = c("_old", "_new")
  )

  version_changed <- merged[
    !is.na(merged$version_old) & !is.na(merged$version_new) &
    merged$version_old != merged$version_new,
  ]

  added <- merged[is.na(merged$version_old), c("name", "version_new")]
  names(added) <- c("name", "version")

  removed <- merged[is.na(merged$version_new), c("name", "version_old")]
  names(removed) <- c("name", "version")

  list(
    version_changed = version_changed,
    added = added,
    removed = removed
  )
}


# -----------------------------------------------------------------------------
# Load risk assessment rules from config (inst/script/risk_rules.json)
# -----------------------------------------------------------------------------
load_risk_rules <- function() {
  path <- system.file("script/risk_rules.json", package = "whatsnew")
  if (!nzchar(path)) path <- "inst/script/risk_rules.json"
  if (file.exists(path)) {
    jsonlite::fromJSON(path, simplifyVector = FALSE)
  } else {
    # Fallback defaults (same structure as risk_rules.json)
    list(
      dependency = list(
        added = list(risk = "medium", note = "Verify new transitive deps."),
        removed = list(risk = "high", note = "Check re-exports; may break."),
        modified = list(risk = "low-medium", note = "Cascading update; run compare on those packages."),
        depends_changed_action = "Depends changed: may require environment updates."
      ),
      function_changes = list(
        removed = list(risk = "high", note = "Search codebase for usages.", action = "Functions removed: search codebase and update call sites."),
        modified = list(risk = "high", note = "Check param changes at each call site.", action = "Params modified: inspect each call site."),
        added = list(risk = "low", note = "New API only.")
      ),
      param_changes = list(
        params_modified = list(risk = "high", note = "Possible breaking change. Check removed params, changed order, new required params."),
        params_added_optional = list(risk = "low", note = "Backward compatible if defaults are sensible."),
        params_removed = list(risk = "high", note = "Breaking: update all call sites.")
      ),
      recommendation = list(
        high = "Manual review and regression tests before upgrade.",
        medium = "Review diffs; run smoke tests before upgrade.",
        low = "Usually safe; quick review recommended."
      )
    )
  }
}


# -----------------------------------------------------------------------------
# Classify param changes for a single modified function (old_formals, new_formals)
# Returns: list(removed, modified, added_optional, added_required)
# -----------------------------------------------------------------------------
classify_param_changes <- function(old_f, new_f) {
  old_n <- names(old_f)
  new_n <- names(new_f)
  if (is.null(old_n)) old_n <- character(0)
  if (is.null(new_n)) new_n <- character(0)
  removed <- setdiff(old_n, new_n)
  added <- setdiff(new_n, old_n)
  common <- intersect(old_n, new_n)
  modified <- character(0)
  for (p in common) {
    if (!identical(old_f[[p]], new_f[[p]])) modified <- c(modified, p)
  }
  added_optional <- character(0)
  added_required <- character(0)
  for (p in added) {
    def <- new_f[[p]]
    has_default <- !is.null(def) && length(def) > 0
    if (has_default) added_optional <- c(added_optional, p) else added_required <- c(added_required, p)
  }
  list(removed = removed, modified = modified, added_optional = added_optional, added_required = added_required)
}

# -----------------------------------------------------------------------------
# Risk assessment: evaluate package diff against risk rules
# -----------------------------------------------------------------------------
assess_package_risk <- function(diff, rules = NULL) {
  if (is.null(rules)) rules <- load_risk_rules()
  dep <- rules$dependency
  fnr <- rules$function_changes
  pr <- rules$param_changes

  pkg <- diff$package[[1]]
  old_v <- diff$version_old[[1]]
  new_v <- diff$version_new[[1]]

  risk_levels <- character()
  actions <- character()

  # 1. Dependency risks
  deps <- diff$dependencies_diff$dependencies
  dep_risks <- list()
  if (!is.null(deps)) {
    for (block in c("Depends", "Imports", "Suggests")) {
      b <- deps[[block]]
      if (is.null(b)) next
      if (length(b$added) > 0) {
        dep_risks[[paste0(block, "_added")]] <- list(risk = dep$added$risk, items = b$added, note = dep$added$note)
        risk_levels <- c(risk_levels, dep$added$risk)
      }
      if (length(b$removed) > 0) {
        dep_risks[[paste0(block, "_removed")]] <- list(risk = dep$removed$risk, items = b$removed, note = dep$removed$note)
        risk_levels <- c(risk_levels, dep$removed$risk)
      }
      if (length(b$modified) > 0) {
        dep_risks[[paste0(block, "_modified")]] <- list(risk = dep$modified$risk, items = b$modified, note = dep$modified$note)
        risk_levels <- c(risk_levels, dep$modified$risk)
      }
      if (block == "Depends" && (length(b$added) > 0 || length(b$removed) > 0 || length(b$modified) > 0)) {
        risk_levels <- c(risk_levels, "high")
        actions <- c(actions, dep$depends_changed_action)
      }
    }
  }

  # 2. Function risks
  fns <- diff$functions_diff
  fn_risks <- list()
  if (!is.null(fns)) {
    if (length(fns$removed) > 0) {
      fn_risks$removed <- list(risk = fnr$removed$risk, functions = names(fns$removed), note = fnr$removed$note)
      risk_levels <- c(risk_levels, fnr$removed$risk)
      actions <- c(actions, fnr$removed$action)
    }
    if (length(fns$modified) > 0) {
      if (!is.null(pr)) {
        fn_high <- character(0)
        fn_low <- character(0)
        for (fn in names(fns$modified)) {
          m <- fns$modified[[fn]]
          old_f <- m$old
          new_f <- m$new
          if (is.null(old_f)) old_f <- list()
          if (is.null(new_f)) new_f <- list()
          pc <- classify_param_changes(old_f, new_f)
          has_breaking <- length(pc$removed) > 0 || length(pc$modified) > 0 || length(pc$added_required) > 0
          only_optional_added <- length(pc$removed) == 0 && length(pc$modified) == 0 &&
            length(pc$added_required) == 0 && length(pc$added_optional) > 0
          if (has_breaking) {
            fn_high <- c(fn_high, fn)
          } else if (only_optional_added) {
            fn_low <- c(fn_low, fn)
          } else {
            fn_high <- c(fn_high, fn)
          }
        }
        if (length(fn_high) > 0) {
          fn_risks$modified <- list(risk = fnr$modified$risk, functions = fn_high, note = fnr$modified$note)
          risk_levels <- c(risk_levels, fnr$modified$risk)
          actions <- c(actions, fnr$modified$action)
        }
        if (length(fn_low) > 0) {
          fn_risks$modified_optional_only <- list(risk = pr$params_added_optional$risk, functions = fn_low, note = pr$params_added_optional$note)
          risk_levels <- c(risk_levels, pr$params_added_optional$risk)
        }
      } else {
        fn_risks$modified <- list(risk = fnr$modified$risk, functions = names(fns$modified), note = fnr$modified$note)
        risk_levels <- c(risk_levels, fnr$modified$risk)
        actions <- c(actions, fnr$modified$action)
      }
    }
    if (length(fns$added) > 0 && length(fns$removed) == 0 && length(fns$modified) == 0) {
      fn_risks$added <- list(risk = fnr$added$risk, functions = names(fns$added), note = fnr$added$note)
    }
  }

  # Overall risk level
  overall <- "low"
  if (length(risk_levels) > 0) {
    if (any(risk_levels == "high")) overall <- "high"
    else if (any(risk_levels == "medium")) overall <- "medium"
    else if (any(risk_levels == "low-medium")) overall <- "medium"
  }

  rec <- rules$recommendation
  recommendation <- rec[[overall]]
  if (is.null(recommendation)) recommendation <- rec$low

  list(
    package = pkg,
    version_old = old_v,
    version_new = new_v,
    risk_level = overall,
    recommendation = recommendation,
    dependency_risks = dep_risks,
    function_risks = fn_risks,
    actions = unique(actions)
  )
}
