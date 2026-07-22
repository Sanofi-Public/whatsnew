#' Print a summary of function differences
#'
#' This helper function prints the differences between functions in two versions
#' of a package. It shows which functions were added, removed, or modified,
#' including their arguments.
#'
#' @param func_cmp A list with elements `added`, `removed`, and `modified`.
#'   Each should contain function names and their argument formals.
#' @param old_version The version string for the old package version.
#' @param new_version The version string for the new package version.
#'
#' @return Invisibly returns `NULL`. Used for its side effect of printing to the console.
#' @keywords internal
#' @export
print_func_diff <- function(func_cmp, old_version, new_version) {
  cat("\n-- Functions --\n")

  if (length(func_cmp$added)) {
    cat("  Added:\n")
    for (fn in names(func_cmp$added)) {
      args <- format_formals(func_cmp$added[[fn]])
      cat(sprintf("    + %s(%s)\n", fn, paste(args, collapse = ", ")))
    }
  }

  if (length(func_cmp$removed)) {
    cat("  Removed:\n")
    for (fn in names(func_cmp$removed)) {
      args <- format_formals(func_cmp$removed[[fn]])
      cat(sprintf("    - %s(%s)\n", fn, paste(args, collapse = ", ")))
    }
  }

  if (length(func_cmp$modified)) {
    cat("  Modified:\n")
    for (fn in names(func_cmp$modified)) {
      old_args <- format_formals(func_cmp$modified[[fn]]$old)
      new_args <- format_formals(func_cmp$modified[[fn]]$new)
      cat(sprintf("    * %s\n", fn))
      cat(sprintf(
        "      - %s: (%s)\n",
        old_version,
        paste(old_args, collapse = ", ")
      ))
      cat(sprintf(
        "      + %s: (%s)\n",
        new_version,
        paste(new_args, collapse = ", ")
      ))
    }
  }

  invisible(NULL)
}


#' Format function argument formals as strings
#'
#' Helper that formats a list of function arguments and their default values.
#'
#' @param formals A named list of function arguments. Each element is either
#'   `NULL` (no default) or a string representing the default value.
#'
#' @return A character vector of formatted arguments.
#' @keywords internal
#' @export
format_formals <- function(formals) {
  unname(sapply(names(formals), function(arg) {
    default <- formals[[arg]]
    if (is.null(default)) {
      paste0(arg)
    } else {
      paste0(arg, " = ", default)
    }
  }))
}
