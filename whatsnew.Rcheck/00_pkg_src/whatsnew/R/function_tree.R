#' Build a Nested Function Call Tree
#'
#' Builds a nested list representation of a package’s **function call tree** using
#' [pkgnet::FunctionReporter]. This is usually consumed by
#' [print_function_tree()] for pretty-printing, but you can also
#' work with the nested list directly.
#'
#' The output structure is a nested list of functions where each leaf is either:
#' * `NULL` (true leaf, no further calls), or
#' * a list containing `__cycle_to` to indicate a cycle in the graph.
#'
#' @param pkg_name Character scalar. Package name to analyze.
#' @param root Optional. Character name of a root function to start from.
#'   If `NULL`, roots are chosen automatically:
#'   * `"downstream"` -> sources (functions with no incoming calls).
#'   * `"upstream"` -> sinks (functions with no outgoing calls).
#' @param depth Integer. Maximum recursion depth. Default is `Inf`
#'   (full depth of the package graph).
#' @param direction Either `"downstream"` (caller -> callee) or `"upstream"`
#'   (callee -> caller).
#' @param pkg_version Optional. If supplied, enforce that this exact version of
#'   the package is installed. Throws an error otherwise.
#'
#' @param prune Optional. Prune exported function of package at the root of function tree
#'
#' @return A named list of the form:
#'   ```
#'   list(
#'     <pkg> = list(
#'       version = "<version>",
#'       <root_fn1> = list(...),
#'       <root_fn2> = list(...)
#'     )
#'   )
#'   ```
#'
#' @details
#' Internally, the function uses [pkgnet::FunctionReporter] to build an
#' igraph of function calls. Roots and neighbors are resolved from this
#' call graph. Cycles are guarded by inserting a `__cycle_to` marker.
#'
#' @examples
#' \dontrun{
#' # Build a function call tree for stringr::str_detect
#' ft <- function_tree("stringr", root = "str_detect", depth = 3,
#'                     direction = "downstream")
#'
#' print_function_tree(ft)
#' }
#'
#' @importFrom igraph V neighbors degree vcount
#' @importFrom pkgnet FunctionReporter
#' @importFrom utils packageVersion
#'
#' @export
function_tree <- function(
  pkg_name,
  root = NULL,
  depth = Inf,
  direction = c("downstream", "upstream"),
  pkg_version = NULL,
  prune = NULL
) {
  direction <- match.arg(direction)
  mode <- if (direction == "downstream") "out" else "in"

  if (!is.null(pkg_version)) {
    if (!requireNamespace(pkg_name, quietly = TRUE)) {
      stop(
        sprintf(
          "Package '%s' is not installed on current .libPaths().",
          pkg_name
        ),
        call. = FALSE
      )
    }
    found <- as.character(utils::packageVersion(pkg_name))
    want <- as.character(package_version(pkg_version))
    if (!identical(found, want)) {
      stop(
        sprintf(
          "Found %s %s, but you requested %s. Adjust lib_paths or install that version.",
          pkg_name,
          found,
          want
        ),
        call. = FALSE
      )
    }
  }

  # Build graph with pkgnet (caller -> callee)
  fr <- pkgnet::FunctionReporter$new()
  suppressWarnings(suppressMessages(fr$set_package(pkg_name = pkg_name)))
  g <- fr$pkg_graph$igraph

  # Helpers
  # Strip Namespace from Function Name
  # Helper function to remove namespace prefix from function names.
  # Args: x - Character scalar or vector. Function name(s) with optional namespace
  #   (e.g., "stringr::str_detect" or "str_detect").
  # Returns: Character scalar or vector. Function name(s) without namespace prefix.
  strip_ns <- function(x) sub("^[^:]+::+", "", x)

  # Extract Key Name from Function Name
  # Helper function to extract key name by stripping namespace prefix.
  # Args: x - Character scalar. Function name with optional namespace.
  # Returns: Character scalar. Function name without namespace prefix.
  key_name <- function(x) strip_ns(x)

  # Prepare  set (names without namespace)
  prune_set <- NULL
  if (!is.null(prune)) {
    if (is.character(prune)) {
      prune_set <- unique(strip_ns(prune))
    } else if (is.data.frame(prune) && "exported_function" %in% names(prune)) {
      prune_set <- unique(strip_ns(as.character(prune$exported_function)))
    } else {
      stop(
        "`prune` must be NULL, a character vector, or a data.frame with column 'exported_function'.",
        call. = FALSE
      )
    }
  }

  vn <- igraph::V(g)$name
  vn_stripped <- strip_ns(vn)

  # Pick Vertex Name from Graph
  # Helper function to match a function name (with or without namespace) to
  # the corresponding vertex name in the igraph call graph. Performs fuzzy
  # matching by stripping namespaces and prefers functions from the target
  # package when multiple matches exist.
  # Args: fun - Character scalar. Function name, optionally with namespace
  #   (e.g., "str_detect" or "stringr::str_detect").
  # Returns: Character scalar. The matched vertex name from the graph, or
  #   NA_character_ if no match is found.
  # Matching strategy:
  #   1. First attempts exact match (with or without package namespace prefix)
  #   2. If no exact match, strips namespaces and finds partial matches
  #   3. Prefers functions from the target package (pkg_name) when multiple
  #      matches exist
  #   4. Returns NA_character_ if no match is found
  pick_vertex_name <- function(fun) {
    exact <- vn[vn %in% c(fun, paste0(pkg_name, "::", fun))]
    if (length(exact)) {
      return(exact[1])
    }

    idx <- which(vn_stripped == strip_ns(fun))
    if (!length(idx)) {
      return(NA_character_)
    } # <- scalar NA, not character()
    in_pkg <- startsWith(vn[idx], paste0(pkg_name, "::"))
    if (any(in_pkg)) vn[idx[which(in_pkg)][1]] else vn[idx[1]]
  }

  # Depth limit
  max_depth <- if (is.infinite(depth)) igraph::vcount(g) else as.integer(depth)

  # Build Function Call Tree Node Recursively
  # Recursive helper function that builds a nested list representation of a
  # function's call tree, starting from a given node. Implements cycle detection
  # and depth limiting to prevent infinite recursion and control tree size.
  # Args:
  #   node_name - Character scalar. Name of the function node to build
  #     (vertex name from the igraph graph).
  #   depth_left - Integer scalar. Remaining recursion depth. When this
  #     reaches 0 or below, the function returns NULL (leaf node).
  #   seen - Character vector. Names of nodes already visited in the current
  #     path, used for cycle detection.
  # Returns: A named list representing the subtree rooted at node_name, or NULL if:
  #   - The node is invalid or doesn't exist in the graph
  #   - Depth limit is reached
  #   - The node has no neighbors (leaf node)
  #   If a cycle is detected, returns list(__cycle_to = <node_key>) to mark
  #   the cycle target.
  # The function performs the following steps:
  #   1. Validates the node exists in the graph
  #   2. Checks for cycles by verifying the node hasn't been seen in the current path
  #   3. Enforces depth limit
  #   4. Retrieves neighboring nodes (called/calling functions) from the graph
  #   5. Recursively builds subtrees for each neighbor
  #   6. Returns a nested list structure with function names as keys
  # Leaf nodes (functions with no further calls) are represented as NULL values
  # in the list. Cycles are marked with a special __cycle_to entry.
  build_node <- function(node_name, depth_left, seen) {
    node_key <- key_name(node_name)
    if (is.na(node_name) || !nzchar(node_name) || !(node_name %in% vn)) {
      return(NULL)
    }
    if (node_name %in% seen) {
      return(list(`__cycle_to` = node_key))
    }
    if (depth_left <= 0) {
      return(NULL)
    }

    vsel <- which(vn == node_name)
    if (!length(vsel)) {
      return(NULL)
    }

    nbrs <- igraph::neighbors(g, v = igraph::V(g)[vsel], mode = mode)
    if (length(nbrs) == 0) {
      return(NULL)
    }

    child_names <- sort(igraph::V(g)[nbrs]$name)
    out <- vector("list", length(child_names))
    names(out) <- vapply(child_names, key_name, character(1))
    for (i in seq_along(child_names)) {
      child_val <- build_node(
        child_names[i],
        depth_left - 1,
        c(seen, node_name)
      )
      if (is.null(child_val)) out[i] <- list(NULL) else out[[i]] <- child_val
    }
    out
  }

  # Determine first-level nodes:
  # - If `prune` is provided: EXACTLY those functions (that exist in the graph)
  # - Else: original behavior (graph roots by direction, or explicit `root`)
  first_level_vertex_names <- character()

  if (!is.null(prune_set)) {
    # If `root` is provided, narrow to just that one (if it's in prune_set)
    if (!is.null(root)) {
      if (strip_ns(root) %in% prune_set) {
        picked <- pick_vertex_name(root)
        if (!length(picked)) {
          stop("Specified `root` not found in the package call graph.")
        }
        first_level_vertex_names <- picked
      } else {
        stop(
          "`root` is not in the supplied exported function set (`prune`).",
          call. = FALSE
        )
      }
    } else {
      # All exported functions that are present in the graph
      mapped <- vapply(prune_set, pick_vertex_name, character(1))
      first_level_vertex_names <- unname(mapped[
        !is.na(mapped) & nzchar(mapped)
      ])

      if (!length(first_level_vertex_names)) {
        # nice diagnostic
        unknown <- setdiff(prune_set, vn_stripped)
        stop(
          sprintf(
            "None of the exported functions in `prune` were found in the package call graph. Missing: %s",
            paste(unknown, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }
  } else {
    # Original root logic (no pruning list given)
    if (!is.null(root)) {
      picked <- pick_vertex_name(root)
      if (is.na(picked) || !nzchar(picked)) {
        stop(
          sprintf(
            "Root function '%s' not found in the package call graph for '%s'.",
            root,
            pkg_name
          ),
          call. = FALSE
        )
      }
      first_level_vertex_names <- picked
    } else {
      if (direction == "downstream") {
        indeg <- igraph::degree(g, mode = "in")
        roots <- names(indeg[indeg == 0])
        if (!length(roots)) roots <- igraph::V(g)$name
      } else {
        outdeg <- igraph::degree(g, mode = "out")
        roots <- names(outdeg[outdeg == 0])
        if (!length(roots)) roots <- igraph::V(g)$name
      }
      first_level_vertex_names <- sort(roots)
    }
  }

  # Assemble nested structure (preserve NULLs)
  res <- list()
  res[[pkg_name]] <- list()
  res[[pkg_name]]$version <- as.character(utils::packageVersion(pkg_name))

  for (v in first_level_vertex_names) {
    r_key <- key_name(v)
    res[[pkg_name]][r_key] <- list(build_node(v, max_depth, seen = character()))
  }

  return(res)
}


# Print tree

#' Print a Function Call Tree
#'
#' Pretty-prints a hierarchical representation of a package's **function call tree**
#' as produced by `function_tree_nested()`. Leaves (no further calls) are shown
#' as plain names (their values are `NULL`). Cycles are annotated.
#'
#' @param tree A nested list from `function_tree_nested()`. Either the whole object
#'   (i.e., `list(<pkg> = list(version=..., <roots>...))`) or the inner package list
#'   (`list(version=..., <roots>...)`).
#' @param prefix Internal use - indentation prefix for branches (default: "").
#' @param last Internal use - whether the current node is the last at its level (default: `TRUE`).
#' @param show_version Logical; show package version at the root if available (default: `TRUE`).
#'
#' @return Invisibly returns `tree` after printing.
#'
#' @examples
#' \dontrun{
#' # Build a function tree (leaves are NULL)
#' ft <- function_tree_nested("stringr", root = "str_detect", depth = 3,
#'                            direction = "downstream", name_style = "pretty")
#'
#' # Print with ASCII (default)
#' print_function_tree(ft)
#'
#' }
#'
#' @export
print_function_tree <- function(
  tree,
  prefix = "",
  last = TRUE,
  show_version = TRUE
) {
  ch <- list(
    tee = "|-- ",
    elbow = "\\-- ",
    pipe = "|   ",
    blank = "    "
  )

  # Accept either the outer wrapper list(<pkg>=list(...)) or the inner list itself
  if (
    is.list(tree) &&
      length(tree) == 1L &&
      is.list(tree[[1]]) &&
      "version" %in% names(tree[[1]])
  ) {
    pkg_name <- names(tree)[1]
    inner <- tree[[1]]
  } else if (is.list(tree) && "version" %in% names(tree)) {
    pkg_name <- "package"
    inner <- tree
  } else {
    stop(
      "`tree` must be the object returned by function_tree_nested(), or its inner package list."
    )
  }

  # Header with version
  ver <- tryCatch(as.character(inner$version), error = function(e) {
    NA_character_
  })
  header <- if (show_version && !is.na(ver) && nzchar(ver)) {
    paste0(pkg_name, " (v", ver, ")")
  } else {
    pkg_name
  }

  # Print root header (as an elbow, to match your style)
  cat(ch$elbow, header, "\n", sep = "")

  # Children are everything except "version"
  roots <- inner[setdiff(names(inner), "version")]

  # Recursively Print Function Tree Children
  # Helper function that recursively prints the children nodes of a function call
  # tree with proper indentation and branch characters. Handles cycle detection
  # and formatting.
  # Args:
  #   nodes - Named list. The child nodes to print (function names as keys,
  #     subtrees or NULL as values).
  #   pref - Character scalar. Current indentation prefix for tree branches.
  # Returns: Invisibly returns NULL.
  # The function recursively traverses the tree structure:
  #   1. Prints each node name with appropriate branch character
  #   2. Detects and annotates cycles (marked with __cycle_to)
  #   3. Recursively prints non-NULL, non-cycle children
  #   4. Adjusts indentation prefix based on whether node is last in its level
  # Leaf nodes (NULL values) are printed as plain names without further recursion.
  # Cycles are detected by checking for __cycle_to marker in the node value.
  print_children <- function(nodes, pref) {
    if (length(nodes) == 0) {
      return(invisible())
    }
    nms <- names(nodes)
    for (i in seq_along(nms)) {
      nm <- nms[i]
      val <- nodes[[nm]]
      last <- (i == length(nms))
      cat(pref, if (last) ch$elbow else ch$tee, nm, sep = "")

      # Detect explicit cycle marker structure: list(`__cycle_to` = <name>)
      is_cycle <- is.list(val) &&
        !is.null(names(val)) &&
        "__cycle_to" %in% names(val)
      if (is_cycle) {
        cat(" (cycle to ", val$`__cycle_to`, ")", sep = "")
      }
      cat("\n")

      # Recurse into non-NULL, non-cycle children
      if (!is.null(val) && !is_cycle && is.list(val)) {
        next_pref <- paste0(pref, if (last) ch$blank else ch$pipe)
        print_children(val, next_pref)
      }
    }
    invisible()
  }

  print_children(roots, pref = ch$blank)
  invisible(tree)
}
