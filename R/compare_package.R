#' Compare Two Versions of a Package
#'
#' This function retrieves information for two versions of an R package,
#' compares their dependencies, exported functions, and test metrics,
#' and returns the differences as a structured R list.
#'
#' @param package_name Character string with the package name (e.g. `"dplyr"`).
#' @param package_version_new Character string with the newer version number.
#' @param package_version_old Character string with the older version number.
#'
#' @return A list containing:
#' \describe{
#'   \item{package}{Package name}
#'   \item{version_new}{Newer version number}
#'   \item{version_old}{Older version number}
#'   \item{dependencies_diff}{Comparison of dependencies}
#'   \item{functions_diff}{Comparison of functions}
#'   \item{test_m}{Comparison of test metrics}
#' }
#' @examples
#' \dontrun{
#' pkg_diff <- compare("dplyr", "1.1.4", "1.0.9")
#' str(pkg_diff)
#' }
#'
#' @export
compare <- function(package_name, package_version_new, package_version_old) {
  info_new <- get_info(package_name, package_version_new)
  info_old <- get_info(package_name, package_version_old)

  dep <- compare_dependencies(info_new, info_old)
  funct <- compare_funcs(info_new, info_old)
  diff_tm <- compare_tm(package_name, package_version_new, package_version_old)

  pkg_diff <- list(
    package = package_name,
    version_new = package_version_new,
    version_old = package_version_old,
    dependencies_diff = dep,
    functions_diff = funct,
    test_m = diff_tm
  )

  return(pkg_diff)
}
