#' Extract Function Names from R Package Source
#'
#' Scans all R files in the specified package's R/ directory and returns a list of defined function names.
#'
#' @param pkg_source_path Character path to the untarred R package source directory.
#'
#' @return A character vector of function names.
#' @keywords internal
get_package_functions <- function(pkg_source_path) {
  r_dir <- file.path(pkg_source_path, "R")
  if (!dir.exists(r_dir)) {
    stop("No R/ directory found in the package source.")
  }

  r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
  func_info <- list()

  for (file in r_files) {
    parsed <- tryCatch(parse(file), error = function(e) NULL)
    if (is.null(parsed)) {
      next
    }

    for (expr in parsed) {
      if (is.call(expr) && expr[[1]] == as.name("<-")) {
        lhs <- expr[[2]]
        rhs <- expr[[3]]

        if (is.symbol(lhs) && is.call(rhs) && rhs[[1]] == as.name("function")) {
          func_name <- as.character(lhs)

          # Extract params directly from the function call node
          param_pairlist <- rhs[[2]] # [[2]] is the formals
          param_list <- as.list(param_pairlist)

          # Convert default values to readable R objects
          param_info <- lapply(param_list, function(x) {
            if (is.symbol(x)) {
              return(NULL)
            } # no default
            if (is.language(x)) {
              return(deparse(x))
            }
            return(x)
          })

          func_info[[func_name]] <- param_info
        }
      }
    }
  }

  return(func_info)
}
