#' Read and Parse DESCRIPTION File
#'
#' Extracts fields from the DESCRIPTION file of a package.
#'
#' @param dir Path to the root of the untarred package source.
#' @param fields Optional character vector specifying which fields to extract. If NULL, all fields are returned.
#'
#' @return A named list of fields from the DESCRIPTION file.
#' @keywords internal
get_pkg_desc <- function(dir, fields = NULL) {
  pkg_desc_path <- file.path(dir, "DESCRIPTION")
  if (!file.exists(pkg_desc_path)) {
    stop("DESCRIPTION not found at: ", pkg_desc_path, call. = FALSE)
  }
  dcf <- read.dcf(pkg_desc_path, fields = fields)
  as.list(dcf[1, , drop = TRUE])
}
