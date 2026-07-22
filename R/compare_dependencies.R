#' Compare Two Versions of an R Package
#'
#' Downloads both versions of a package and compares dependencies and function definitions.
#'
#' @param info_new The newer version.
#' @param info_old The older version.
#'
#' @return A list summarizing added/removed/modified dependencies and functions.
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr transmute arrange
#' @importFrom rlang .data
#' @importFrom rlang :=
#' @importFrom risk.assessr create_traceability_matrix
#'
#' @keywords internal
compare_dependencies <- function(info_new, info_old) {
  if (is.null(info_new) || is.null(info_old)) {
    message("Comparison failed due to download or parsing issues.")
    return(NULL)
  }

  deps_fields <- c("Depends", "Imports", "Suggests")
  results <- list()
  deps_results <- list()

  for (field in deps_fields) {
    cat("\n--", field, "--\n")
    dep_new <- info_new$desc[[field]]
    dep_old <- info_old$desc[[field]]

    if (is.null(dep_new) && is.null(dep_old)) {
      cat("  No changes.\n")
      next
    }

    cmp <- compare_dep_fields(dep_new, dep_old)

    if (length(cmp$added)) {
      cat("  Added:    ", paste(cmp$added, collapse = ", "), "\n")
    }
    if (length(cmp$removed)) {
      cat("  Removed:  ", paste(cmp$removed, collapse = ", "), "\n")
    }
    if (length(cmp$modified)) {
      cat("  Modified:\n    ", paste(cmp$modified, collapse = "\n    "), "\n")
    }
    if (
      length(cmp$added) == 0 &&
        length(cmp$removed) == 0 &&
        length(cmp$modified) == 0
    ) {
      cat("  No changes.\n")
    }

    deps_results[[field]] <- cmp
  }

  results[["dependencies"]] <- deps_results

  return(results)
}


#' Compare Two DESCRIPTION Dependency Strings
#'
#' Identifies added, removed, and modified dependencies between two versions.
#'
#' @param dep_new A dependency string from the newer DESCRIPTION.
#' @param dep_old A dependency string from the older DESCRIPTION.
#'
#' @return A list with `added`, `removed`, and `modified` components.
#' @keywords internal
compare_dep_fields <- function(dep_new, dep_old) {
  df_new <- extract_versions(dep_new)
  df_old <- extract_versions(dep_old)

  rownames(df_new) <- df_new$pkg
  rownames(df_old) <- df_old$pkg

  pkgs_new <- df_new$pkg
  pkgs_old <- df_old$pkg

  added <- setdiff(pkgs_new, pkgs_old)
  removed <- setdiff(pkgs_old, pkgs_new)
  common <- intersect(pkgs_new, pkgs_old)

  modified <- c()
  for (pkg in common) {
    v_new <- df_new[pkg, "version"]
    v_old <- df_old[pkg, "version"]
    if (!identical(v_new, v_old)) {
      modified <- c(
        modified,
        sprintf(
          "%s: %s -> %s",
          pkg,
          ifelse(is.na(v_old), "none", v_old),
          ifelse(is.na(v_new), "none", v_new)
        )
      )
    }
  }
  list(added = added, removed = removed, modified = modified)
}
