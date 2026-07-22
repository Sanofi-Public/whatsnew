#!/usr/bin/env Rscript
# Rewrite the tree for the public package name and repo metadata.
# Never reads or writes anything under .github/ (content or renames).
# After content edits: renames *.R / *.Rproj whose basename starts with
# risk.assessr -> risk.assessr (e.g. .Rproj, *-package.R).
# Run devtools::document() after renames so roxygen/man match the new package name.
# Run from the repository root:
#   Rscript .github/scripts/apply_opensource_transform.R
# In CI, GITHUB_WORKSPACE is set to the repo root.
#
# Optional env (e.g. GitHub Actions repository variables):
#   OSS_TRANSFORM_GITHUB_FROM — internal org/repo (default Sanofi-GitHub/bp-art-risk.assessr)
#   OSS_TRANSFORM_GITHUB_TO — public org/repo (default Sanofi-Public/risk.assessr)
#   OSS_TRANSFORM_INTERNAL_PM_HOST — internal RSPM host (default rstudio-pm.prod…sanofi.com)
#   OSS_TRANSFORM_OPTIONS_REPOS_URL — URL for options(repos="…") / PM replacement target (default https://cloud.r-project.org)

local({
  repo_root <- normalizePath(
    Sys.getenv("GITHUB_WORKSPACE", unset = getwd()),
    winslash = "/",
    mustWork = TRUE
  )

  gh_from <- Sys.getenv(
    "OSS_TRANSFORM_GITHUB_FROM",
    unset = "Sanofi-GitHub/bp-art-risk.assessr"
  )
  gh_to <- Sys.getenv(
    "OSS_TRANSFORM_GITHUB_TO",
    unset = "Sanofi-Public/risk.assessr"
  )
  pm_host <- Sys.getenv(
    "OSS_TRANSFORM_INTERNAL_PM_HOST",
    unset = "rstudio-pm.prod.p488440267176.aws-emea.sanofi.com"
  )
  options_repos_url <- Sys.getenv(
    "OSS_TRANSFORM_OPTIONS_REPOS_URL",
    unset = "https://cloud.r-project.org"
  )
  if (!nzchar(options_repos_url)) {
    options_repos_url <- "https://cloud.r-project.org"
  }

  regex_escape <- function(s) {
    gsub("([][{}()+*^$\\\\|?.])", "\\\\\\1", s, perl = TRUE)
  }

  skip_subpaths <- c(
    ".github/scripts/apply_opensource_transform.R"
  )

  skip_suffixes <- c(
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico",
    ".rds", ".rdx", ".rdb", ".tar", ".gz", ".zip", ".pdf",
    ".woff", ".woff2", ".eot", ".ttf"
  )

  badge_block <- paste0(
    "<!-- badges: start -->\n",
    "![R-CMD-check](https://img.shields.io/badge/R%20CMD%20check-Passing-brightgreen.svg)\n",
    "![Test Coverage](https://img.shields.io/badge/coverage-94%25-brightgreen.svg)\n",
    "![Pharmaverse](http://pharmaverse.org/shields/risk.assessr.svg)\n",
    "<!-- badges: end -->"
  )

  # Internal RSPM host → public mirrors (host from OSS_TRANSFORM_INTERNAL_PM_HOST)
  replace_internal_pm <- function(text) {
    if (!nzchar(pm_host)) {
      return(text)
    }
    cran <- options_repos_url
    base <- paste0("https://", pm_host)
    text <- gsub(
      paste0(base, "/prod-cran/__linux__/jammy/latest"),
      "https://packagemanager.posit.co/cran/__linux__/jammy/latest",
      text,
      fixed = TRUE
    )
    text <- gsub(
      paste0(base, "/prod-cran/__linux__/noble/latest"),
      "https://packagemanager.posit.co/cran/__linux__/noble/latest",
      text,
      fixed = TRUE
    )
    text <- gsub(paste0(base, "/prod-cran/latest"), cran, text, fixed = TRUE)
    text <- gsub(paste0(base, "/art-git/latest"), cran, text, fixed = TRUE)
    gsub(base, cran, text, fixed = TRUE)
  }

  # URL / repo-path swaps only (no prose or section rewrites). Used for README and all text files.
  replace_repo_links <- function(text) {
    text <- replace_internal_pm(text)
    if (nzchar(gh_from) && nzchar(gh_to)) {
      text <- gsub(gh_from, gh_to, text, fixed = TRUE)
      gh_url_from <- paste0("https://github.com/", gh_from)
      gh_url_to <- paste0("https://github.com/", gh_to)
      text <- gsub(gh_url_from, gh_url_to, text, fixed = TRUE)
    }
    text
  }

  # README Usage: when RSPM/INTERNAL/INTERNAL_RSPM all map to cloud.r-project.org, replace
  # the multi-line c() block with a single options(repos=...) line users can edit locally.
  readme_collapse_options_repos <- function(text) {
    u <- regex_escape(options_repos_url)
    pat <- paste0(
      "(?ms)^options\\(repos\\s*=\\s*c\\(\\s*\n",
      "\\s*RSPM\\s*=\\s*\"", u, "\",\\s*\n",
      "\\s*INTERNAL\\s*=\\s*\"", u, "\",\\s*\n",
      "\\s*INTERNAL_RSPM\\s*=\\s*\"", u, "\"\\s*\n",
      "\\)\\s*\\)"
    )
    repl <- paste0("options(repos=\"", options_repos_url, "\")")
    sub(pat, repl, text, perl = TRUE)
  }

  rel_posix <- function(path) {
    p <- normalizePath(path, winslash = "/", mustWork = TRUE)
    sub(paste0("^", repo_root, "/"), "", p, fixed = TRUE)
  }

  is_skipped_binary <- function(path) {
    nml <- tolower(basename(path))
    any(endsWith(nml, skip_suffixes))
  }

  # Text targets: R, Rmd, Rd, md, yml/yaml, DESCRIPTION, README*, NEWS.md, inst/**, docs/**.
  # Never touch .github/ (workflows, this script, issue templates, etc.).
  should_process <- function(path) {
    rel <- tryCatch(rel_posix(path), error = function(e) "")
    if (!nzchar(rel)) {
      return(FALSE)
    }
    if (startsWith(rel, ".github/")) {
      return(FALSE)
    }
    if (rel %in% skip_subpaths) {
      return(FALSE)
    }
    if (is_skipped_binary(path)) {
      return(FALSE)
    }
    base <- basename(path)
    ext <- tolower(tools::file_ext(path))
    if (startsWith(rel, "inst/")) {
      return(TRUE)
    }
    if (startsWith(rel, "docs/")) {
      return(TRUE)
    }
    if (base == "DESCRIPTION") {
      return(TRUE)
    }
    if (startsWith(base, "README")) {
      return(TRUE)
    }
    if (base == "NEWS.md") {
      return(TRUE)
    }
    if (ext %in% c("r", "rmd", "rd", "md", "yml", "yaml", "rproj")) {
      return(TRUE)
    }
    FALSE
  }

  transform_text <- function(path, text) {
    if (basename(path) == "README.md") {
      text <- sub(
        "(?s)<!-- badges: start -->.*?<!-- badges: end -->",
        badge_block,
        text,
        perl = TRUE
      )
    }

    text <- replace_repo_links(text)
    if (basename(path) == "README.md") {
      text <- readme_collapse_options_repos(text)
    }
    text <- gsub("risk.assessr", "risk.assessr", text, fixed = TRUE)

    if (basename(path) == "DESCRIPTION") {
      text <- sub(
        "(?m)^URL:.*$",
        "URL: https://sanofi-public.github.io/risk.assessr/",
        text,
        perl = TRUE
      )
      text <- sub(
        "(?m)^BugReports:.*$",
        paste0("BugReports: https://github.com/", gh_to, "/issues"),
        text,
        perl = TRUE
      )
    }

    text
  }

  read_utf8 <- function(path) {
    tryCatch(
      paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"),
      error = function(e) NULL,
      warning = function(w) NULL
    )
  }

  write_utf8 <- function(text, path) {
    if (!nzchar(text)) {
      writeLines(character(), path)
      return(invisible())
    }
    cat(enc2utf8(text), file = path, sep = "")
  }

  # Basename risk.assessr*.{R,Rproj} -> risk.assessr*.{R,Rproj} (not .github/)
  rename_internal_package_filenames <- function(files) {
    n_ok <- 0L
    for (from in files) {
      rel <- tryCatch(rel_posix(from), error = function(e) "")
      if (!nzchar(rel) || startsWith(rel, ".github/")) {
        next
      }
      ext <- tolower(tools::file_ext(from))
      if (!ext %in% c("r", "rproj")) {
        next
      }
      bn <- basename(from)
      new_bn <- sub(
        "^sanofi\\.risk\\.assessr",
        "risk.assessr",
        bn,
        perl = TRUE
      )
      if (identical(new_bn, bn)) {
        next
      }
      to <- file.path(dirname(from), new_bn)
      if (file.exists(to)) {
        message("skip rename (target exists): ", rel_posix(to))
        next
      }
      rel_to <- if (dirname(rel) == ".") {
        new_bn
      } else {
        paste(dirname(rel), new_bn, sep = "/")
      }
      if (file.rename(from, to)) {
        # Do not call rel_posix(from) here: the path was moved and no longer exists.
        message("renamed: ", rel, " -> ", rel_to)
        n_ok <- n_ok + 1L
      } else {
        warning("rename failed: ", rel, call. = FALSE)
      }
    }
    n_ok
  }

  # Walk the working tree only. Paths under .git/ are dropped so this script never
  # opens or rewrites the Git directory — commits, objects, and history are unchanged.
  all_files <- list.files(
    repo_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  )
  outside_git <- function(f) {
    parts <- strsplit(normalizePath(f, winslash = "/"), "/", fixed = TRUE)[[1]]
    !".git" %in% parts
  }
  all_files <- all_files[vapply(all_files, outside_git, logical(1))]

  changed <- 0L
  for (f in all_files) {
    if (!should_process(f)) {
      next
    }
    txt <- tryCatch(
      read_utf8(f),
      error = function(e) NULL
    )
    if (is.null(txt)) {
      next
    }
    new_txt <- transform_text(f, txt)
    if (!identical(new_txt, txt)) {
      write_utf8(new_txt, f)
      message("updated: ", rel_posix(f))
      changed <- changed + 1L
    }
  }
  renamed <- rename_internal_package_filenames(all_files)
  message("files modified: ", changed, "; renames: ", renamed)
  invisible(changed + renamed)
})