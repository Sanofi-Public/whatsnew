library(jsonlite)
library(whatsnew)
library(rmarkdown)

make_qmd_from_diff <- function(diff, result_path = tempdir()) {
  # pull basic fields
  pkg         <- diff$package[[1]]
  old_version <- diff$version_old[[1]]
  new_version <- diff$version_new[[1]]

  # ----- helpers -----
  section_header <- function(txt) paste0("-- ", txt, " --")

  # Dependency sections (Depends / Imports / Suggests)
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
    c(section_header(block_name), out, "")  # <-- add blank line at end of block
  }

  deps <- diff$dependencies_diff$dependencies
  dep_lines <- c(
    fmt_dep_block("Depends",  deps$Depends),
    fmt_dep_block("Imports",  deps$Imports),
    fmt_dep_block("Suggests", deps$Suggests)
  )
  dep_lines <- dep_lines[nzchar(dep_lines)]  # remove excess empty lines

  # Function summary (added/removed/modified)
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

  # Combine body content with clean spacing
  output <- paste(c(dep_lines, fn_lines), collapse = "\n")

  # QMD header + body
  qmd_header <- c(
    "---",
    paste0("title: \"", pkg, " ", old_version, " → ", new_version, "\""),
    "format: html",
    "---",
    ""
  )
  qmd_body <- c("```", output, "```")

  # write file
  outfile <- file.path(result_path, paste0(pkg, "_", old_version, "_to_", new_version, ".qmd"))
  writeLines(c(qmd_header, qmd_body), outfile)
  invisible(outfile)
}


# --- Example usage ---
# If you have the JSON in a file:
# diff <- jsonlite::fromJSON("admiral_diff.json", simplifyVector = FALSE)
# make_qmd_from_diff(diff, result_path = ".")

# Or if your JSON is already parsed into `diff`, just call:
# make_qmd_from_diff(diff)




file1_path <- system.file("env/R-v1.8.0-20250530.json", package = "whatsnew")
file2_path <- system.file("env/R-v1.9.0-20250618.json", package = "whatsnew")

file1 <- fromJSON(file1_path, flatten = TRUE)
file2 <- fromJSON(file2_path, flatten = TRUE)

compare_env <- function(df1, df2) {
  merged <- merge(df1[, c("name", "version")],
                  df2[, c("name", "version")],
                  by = "name", suffixes = c("_file1", "_file2"))

  # Find differences in version
  version_diff <- merged[merged$version_file1 != merged$version_file2, ]

  return(version_diff)
}

diffs <- compare_env(file1, file2)
print(diffs)

result_path <- tempdir()
dir.create(result_path, recursive = TRUE, showWarnings = FALSE)

for (i in seq_len(nrow(diffs))) {
  pkg <- diffs$name[i]
  old_version <- diffs$version_file1[i]
  new_version <- diffs$version_file2[i]

  message(pkg, "package:", old_version, "=>", new_version)

  diff <- compare(pkg, new_version, old_version)
  make_qmd_from_diff(diff, result_path = file.path(result_path))

}



