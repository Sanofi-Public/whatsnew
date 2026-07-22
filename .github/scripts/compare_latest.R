#!/usr/bin/env Rscript
# Compare repository version with CRAN version using whatsnew
#
# This script:
# 1. Reads package info from DESCRIPTION (or extracts from tar.gz if provided)
# 2. Queries CRAN for latest version
# 3. Always treats repository version as newest (uses local source or extracted tar.gz)
# 4. Downloads CRAN version for comparison
# 5. Performs comparison and generates summary
#
# Usage:
#   Rscript compare_latest.R [test_package.tar.gz] [save_result]
#
# Arguments:
#   test_package.tar.gz: Optional path to tar.gz file to use as local package source.
#                        If not provided, uses current directory (repository root).
#   save_result: Optional logical (TRUE/FALSE). If TRUE, saves JSON to inst/versions/ folder.
#                Default: FALSE
#
# Output files:
# - version_env.txt: Environment variables for GitHub Actions
# - package_comparison.json: Full comparison results (always saved to current directory)
# - inst/versions/package_comparison.json: Full comparison results (if save_result=TRUE)

library(whatsnew)
library(desc)
library(jsonlite)

# ============================================================================
# STEP 0: Parse command line arguments
# ============================================================================
args <- commandArgs(trailingOnly = TRUE)
# Always use repository root as package path
package_path <- "."

# Parse arguments: [test_package.tar.gz] [save_result]
# If first arg looks like TRUE/FALSE, treat it as save_result (no test_package)
# Otherwise, first arg is test_package, second arg (if present) is save_result
test_package_tgz <- NULL
save_result <- FALSE

if (length(args) > 0) {
  if (grepl("^(TRUE|FALSE|true|false)$", args[1])) {
    # First arg is save_result (no test_package)
    save_result <- as.logical(toupper(args[1]))
  } else {
    # First arg is test_package
    test_package_tgz <- args[1]
    # Check if second arg is save_result
    if (length(args) > 1 && grepl("^(TRUE|FALSE|true|false)$", args[2])) {
      save_result <- as.logical(toupper(args[2]))
    }
  }
}

cat(sprintf("Package path: %s (repository root)\n", package_path))
if (!is.null(test_package_tgz)) {
  cat(sprintf("Test package tar.gz: %s\n", test_package_tgz))
}
cat(sprintf("Save result to inst/versions/: %s\n", save_result))

# ============================================================================
# STEP 1: Determine local package source (tar.gz or directory)
# ============================================================================
local_pkg_path <- package_path
temp_extract_dir <- NULL

if (!is.null(test_package_tgz)) {
  # Extract tar.gz to temporary directory
  if (!file.exists(test_package_tgz)) {
    stop(sprintf("Test package file not found: %s", test_package_tgz))
  }
  
  cat(sprintf("Extracting test package from: %s\n", test_package_tgz))
  temp_extract_dir <- tempfile()
  dir.create(temp_extract_dir)
  extracted_files <- tryCatch(
    untar(test_package_tgz, exdir = temp_extract_dir),
    error = function(e) {
      stop(sprintf("Failed to extract package from tar.gz: %s", e$message))
    }
  )
  if (length(extracted_files) == 0) {
    stop("Failed to extract package from tar.gz - no files were extracted")
  }
  
  # Find the extracted package directory (usually first subdirectory)
  extracted_dirs <- list.dirs(temp_extract_dir, full.names = TRUE, recursive = FALSE)
  if (length(extracted_dirs) == 0) {
    stop("Failed to extract package from tar.gz - no directories found")
  }
  local_pkg_path <- extracted_dirs[1]
  cat(sprintf("Extracted package path: %s\n", local_pkg_path))
}

# Validate package path exists
if (!dir.exists(local_pkg_path)) {
  stop(sprintf("Package path does not exist: %s", local_pkg_path))
}

# ============================================================================
# STEP 2: Read package information from DESCRIPTION
# ============================================================================
desc_file_path <- file.path(local_pkg_path, "DESCRIPTION")
if (!file.exists(desc_file_path)) {
  stop(sprintf("DESCRIPTION file not found at: %s", desc_file_path))
}

desc_file <- desc::desc(file = desc_file_path)
package_name <- desc_file$get("Package")
repo_version <- as.character(desc_file$get_version())  # Ensure character string
cat(sprintf("Package: %s | Repository version: %s\n", package_name, repo_version))

# ============================================================================
# STEP 2: Query CRAN for latest published version
# ============================================================================
cran_info <- tryCatch({
  pkgs <- available.packages(repos = "https://cloud.r-project.org")
  if (package_name %in% rownames(pkgs)) {
    list(available = TRUE, version = pkgs[package_name, "Version"])
  } else {
    list(available = FALSE)
  }
}, error = function(e) {
  list(available = FALSE, error = conditionMessage(e))
})

if (!cran_info$available) {
  status <- "not_on_cran"
  message <- sprintf("Package \"%s\" is not available on CRAN", package_name)
  cat(sprintf("Status: %s\n", status))
  # Write environment variables
  writeLines(
    c(
      "STATUS=not_on_cran",
      paste0("REPO_VERSION=", repo_version),
      "CRAN_VERSION="
    ),
    "version_env.txt"
  )
  cat(sprintf("\n%s\n", message))
  quit(status = 0)
}

cran_version <- as.character(cran_info$version)  # Ensure character string
cat(sprintf("CRAN version: %s\n", cran_version))

# ============================================================================
# STEP 3: Set version order
# Always treat local repository source as the newest version
# (regardless of numeric version comparison - repository code is always "newer")
# ============================================================================
version_new <- as.character(repo_version)  # Repository version (always treated as newer)
version_old <- as.character(cran_version)    # CRAN version (always treated as older)
status <- "ahead"
direction <- "Repository is newer than CRAN"
cat(sprintf(
  "Comparing: %s (%s - LOCAL/REPOSITORY) vs %s (%s - CRAN)\n",
  package_name, version_new, package_name, version_old
))
cat(sprintf("NOTE: Repository version (%s) is treated as NEWER than CRAN (%s), even if numeric version is lower\n",
            version_new, version_old))

# ============================================================================
# STEP 4: Get package information
# IMPORTANT: Repository version uses LOCAL SOURCE CODE (not CRAN download)
# This is because the repository version may not be published on CRAN yet
# ============================================================================

# Helper: Extract info from local source code (for repository version)
get_info_from_source <- function(source_path) {
  pkg_desc <- whatsnew:::get_pkg_desc(source_path)
  func_names <- tryCatch({
    whatsnew:::get_package_functions(source_path)
  }, error = function(e) {
    message(paste("Failed to parse functions:", e$message))
    return(NULL)
  })
  list(desc = pkg_desc, functions = func_names)
}

# Get info for newer version (always local repository or extracted tar.gz)
if (!is.null(test_package_tgz)) {
  cat("Using EXTRACTED TAR.GZ for newer version (not downloading from CRAN)\n")
} else {
  cat("Using LOCAL SOURCE for newer version (not downloading from CRAN)\n")
}
info_new <- get_info_from_source(local_pkg_path)

# Get info for older version (always from CRAN)
cat(sprintf("Downloading older version (%s) from CRAN\n", version_old))
info_old <- whatsnew::get_info(package_name, version_old)

if (is.null(info_new) || is.null(info_old)) {
  stop("Failed to retrieve package information")
}

# ============================================================================
# STEP 5: Perform comparison using whatsnew functions
# ============================================================================
pkg_diff <- tryCatch({
  # compare_dependencies is internal (not exported); compare_funcs is exported
  dep <- whatsnew:::compare_dependencies(info_new, info_old)
  funct <- whatsnew::compare_funcs(info_new, info_old)

  # Warn if versions are the same but differences are detected
  if (version_new == version_old) {
    new_func_count <- if (!is.null(info_new$functions)) length(info_new$functions) else 0
    old_func_count <- if (!is.null(info_old$functions)) length(info_old$functions) else 0
    added_count <- if (!is.null(funct$added)) length(funct$added) else 0
    removed_count <- if (!is.null(funct$removed)) length(funct$removed) else 0
    
    if (added_count > 0 || removed_count > 0) {
      cat(sprintf("\n⚠️ WARNING: Versions are identical (%s) but differences detected:\n", version_new))
      cat(sprintf("   Local source functions: %d\n", new_func_count))
      cat(sprintf("   CRAN source functions: %d\n", old_func_count))
      cat(sprintf("   Functions detected as added: %d\n", added_count))
      cat(sprintf("   Functions detected as removed: %d\n", removed_count))
      cat("   This may indicate:\n")
      cat("   - Different source builds/snapshots\n")
      cat("   - Differences in function extraction methods\n")
      cat("   - The test package tar.gz may be from a different source than CRAN\n\n")
    }
  }

  # Traceability matrix may fail if repo version not on CRAN (expected)
  diff_tm <- tryCatch({
    whatsnew::compare_tm(package_name, version_new, version_old)
  }, error = function(e) {
    cat("Warning: Traceability matrix comparison skipped (repo version not on CRAN)\n")
    return(NULL)
  })

  list(
    package = package_name,
    version_new = version_new,
    version_old = version_old,
    dependencies_diff = dep,
    functions_diff = funct,
    test_m = diff_tm
  )
}, error = function(e) {
  cat(sprintf("Error: %s\n", conditionMessage(e)))
  NULL
})

if (is.null(pkg_diff)) {
  status <- "comparison_failed"
  message <- sprintf(
    "⚠️ Comparison failed: repository (%s) vs CRAN (%s)",
    repo_version, cran_version
  )
  # Write environment variables
  writeLines(
    c(
      paste0("STATUS=", status),
      paste0("REPO_VERSION=", repo_version),
      paste0("CRAN_VERSION=", cran_version)
    ),
    "version_env.txt"
  )
  cat(sprintf("\n%s\n", message))
  quit(status = 0)
}

# ============================================================================
# STEP 6: Generate summary report
# ============================================================================
summary <- c(
  sprintf("## Package Comparison: %s", package_name),
  "",
  sprintf("- **Newer version**: %s", version_new),
  sprintf("- **Older version**: %s", version_old),
  sprintf("- **Status**: %s (%s)", status, direction),
  ""
)

# Dependencies summary
if (!is.null(pkg_diff$dependencies_diff$dependencies)) {
  # Count total dependency changes across all fields (Depends, Imports, Suggests)
  deps_list <- pkg_diff$dependencies_diff$dependencies
  n_deps <- 0
  for (field in names(deps_list)) {
    field_changes <- deps_list[[field]]
    if (!is.null(field_changes)) {
      n_deps <- n_deps + length(field_changes$added) + 
                        length(field_changes$removed) + 
                        length(field_changes$modified)
    }
  }
  # Ensure n_deps is a numeric value (not NULL or length zero)
  n_deps <- if (length(n_deps) == 0 || is.null(n_deps)) 0 else as.numeric(n_deps)
  
  summary <- c(
    summary,
    "### Dependencies Changes",
    "",
    if (n_deps > 0) sprintf("- %d change(s)", n_deps) else "- No changes",
    ""
  )
}

# Functions summary
if (!is.null(pkg_diff$functions_diff)) {
  funcs <- pkg_diff$functions_diff
  added <- if (!is.null(funcs$added)) length(funcs$added) else 0
  removed <- if (!is.null(funcs$removed)) length(funcs$removed) else 0
  modified <- if (!is.null(funcs$modified) && is.data.frame(funcs$modified)) {
    nrow(funcs$modified)
  } else {
    0
  }
  summary <- c(
    summary,
    "### Functions Changes",
    "",
    sprintf("- **Added**: %d", added),
    sprintf("- **Removed**: %d", removed),
    sprintf("- **Modified**: %d", modified),
    ""
  )
}

# Traceability matrix summary
if (!is.null(pkg_diff$test_m)) {
  n_tm <- if (is.data.frame(pkg_diff$test_m)) nrow(pkg_diff$test_m) else 0
  summary <- c(
    summary,
    "### Traceability Matrix Changes",
    "",
    if (n_tm > 0) sprintf("- %d difference(s)", n_tm) else "- No differences",
    ""
  )
}

summary_text <- paste(summary, collapse = "\n")
cat("\n", summary_text, "\n", sep = "")

# Helper function to convert numeric_version objects to character for JSON serialization
sanitize_for_json <- function(x) {
  if (inherits(x, "numeric_version")) {
    return(as.character(x))
  } else if (is.list(x)) {
    # Recursively sanitize list elements
    result <- lapply(x, sanitize_for_json)
    # Preserve names
    names(result) <- names(x)
    return(result)
  } else if (is.data.frame(x)) {
    # Convert data frame columns that might contain numeric_version
    for (col in names(x)) {
      if (inherits(x[[col]], "numeric_version")) {
        x[[col]] <- as.character(x[[col]])
      } else if (is.list(x[[col]])) {
        x[[col]] <- lapply(x[[col]], sanitize_for_json)
      }
    }
    return(x)
  } else {
    return(x)
  }
}

# Save results - sanitize numeric_version objects before JSON serialization
pkg_diff_sanitized <- sanitize_for_json(pkg_diff)

# Always save to current directory
write_json(pkg_diff_sanitized, "package_comparison.json", pretty = TRUE)
cat("\n✅ Comparison results saved to: package_comparison.json\n")

# Optionally save to inst/versions/ folder
if (save_result) {
  versions_dir <- "inst/versions"
  if (!dir.exists(versions_dir)) {
    dir.create(versions_dir, recursive = TRUE)
    cat(sprintf("Created directory: %s\n", versions_dir))
  }
  versions_file <- file.path(versions_dir, "package_comparison.json")
  write_json(pkg_diff_sanitized, versions_file, pretty = TRUE)
  cat(sprintf("✅ Comparison results also saved to: %s\n", versions_file))
}

# Write environment variables for GitHub Actions
writeLines(
  c(
    paste0("STATUS=", status),
    paste0("REPO_VERSION=", repo_version),
    paste0("CRAN_VERSION=", cran_version),
    paste0("VERSION_NEW=", version_new),
    paste0("VERSION_OLD=", version_old),
    paste0("DIRECTION=", direction)
  ),
  "version_env.txt"
)

# Clean up temporary extraction directory if used
if (!is.null(temp_extract_dir) && dir.exists(temp_extract_dir)) {
  unlink(temp_extract_dir, recursive = TRUE)
}

