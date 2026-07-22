#' Download and Parse a Specific Package Version
#'
#' Downloads a specified version of a CRAN package and extracts DESCRIPTION info and function names.
#'
#' @param package_name The name of the package to download.
#' @param version The version of the package to download.
#' @param use_isolated_lib Logical. If TRUE, uses an isolated library path.
#'
#' @return A list with `desc` (DESCRIPTION fields) and `functions` (character vector).
#' @examples
#' \dontrun{
#' info_old <- get_info("dplyr", "1.0.9")
#' info_new <- get_info("dplyr", "1.1.4")
#' }
#'
#' @importFrom remotes download_version
#' @importFrom utils untar
#' @export
get_info <- function(package_name, version, use_isolated_lib = TRUE) {
  if (use_isolated_lib) {
    # Create isolated library path
    message(paste0(
      "Creating isolated library path for ",
      package_name,
      " ",
      version
    ))
    lib_path <- file.path(tempdir(), paste0(package_name, "_", version))
    dir.create(lib_path, showWarnings = FALSE)
    old_lib <- .libPaths()
    on.exit(.libPaths(old_lib))
    .libPaths(c(lib_path, old_lib))

    # 2. Save and restore global options
    old_options <- options()
    on.exit(options(old_options), add = TRUE)

    # 3. Save and restore ALL environment variables
    # This ensures complete isolation of env var changes
    all_old_env <- Sys.getenv()
    on.exit(
      {
        # Get current env vars
        current_env <- Sys.getenv()

        # Remove any NEW environment variables that were added during the call
        added_vars <- setdiff(names(current_env), names(all_old_env))
        if (length(added_vars) > 0) {
          try(Sys.unsetenv(added_vars), silent = TRUE)
        }

        # Restore all original environment variables
        do.call(Sys.setenv, as.list(all_old_env))
      },
      add = TRUE
    )

    # 4. Unload package if already loaded
    if (package_name %in% loadedNamespaces()) {
      message(paste0("Unloading cached ", package_name, " from namespace"))
      try(unloadNamespace(package_name), silent = TRUE)
    }
  }

  temp_file <- tryCatch(
    {
      remotes::download_version(package = package_name, version = version)
    },
    error = function(e) {
      message(paste("Failed to download version", version, ":", e$message))
      return(NULL)
    }
  )

  if (is.null(temp_file)) {
    return(NULL)
  }

  temp_dir <- tempfile()
  dir.create(temp_dir)
  untar(temp_file, exdir = temp_dir)
  pkg_source_path <- list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)[
    1
  ]

  pkg_desc <- get_pkg_desc(pkg_source_path)

  func_names <- tryCatch(
    {
      get_package_functions(pkg_source_path)
    },
    error = function(e) {
      message(paste("Failed to parse functions:", e$message))
      return(NULL)
    }
  )

  list(desc = pkg_desc, functions = func_names)
}
