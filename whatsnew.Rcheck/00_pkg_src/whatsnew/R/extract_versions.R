#' Extract Package Names and Versions from DESCRIPTION Dependency Fields
#'
#' Parses a string of dependencies (e.g. from 'Imports' or 'Depends') into a data frame with package names and versions.
#'
#' @param dep_string A string from a DESCRIPTION dependency field (e.g., 'Imports').
#'
#' @return A data frame with columns `pkg` and `version`.
#' @export
extract_versions <- function(dep_string) {
  if (is.null(dep_string)) {
    return(data.frame(
      pkg = character(),
      version = character(),
      stringsAsFactors = FALSE
    ))
  }

  # Clean all line breaks and excess spacing
  dep_string <- gsub("\\\\n|\\\\r|[\r\n]", " ", dep_string)
  dep_string <- gsub("\\s+", " ", dep_string)

  parts <- unlist(strsplit(dep_string, ","))
  parts <- trimws(parts)

  # Extract clean package name and version inside ()
  result <- lapply(parts, function(entry) {
    # Extract package name (before parentheses)
    pkg <- trimws(gsub("\\s*\\(.*\\)", "", entry))

    # Extract version if present
    m <- regmatches(entry, regexec("\\(([^\\)]+)\\)", entry))[[1]]
    version <- if (length(m) >= 2) m[2] else NA

    c(pkg = pkg, version = version)
  })

  df <- do.call(rbind, result)
  colnames(df) <- c("pkg", "version")
  rownames(df) <- df[, "pkg"]
  as.data.frame(df, stringsAsFactors = FALSE)
}
