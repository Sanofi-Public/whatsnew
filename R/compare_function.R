#' Compare Exported Functions Between Two Versions
#'
#' @param new_funcs Named list: names are function names, values are lists of formals.
#' @param old_funcs Named list: same as above.
#'
#' @return A list with `added`, `removed`, and `modified` function names.
#' @export
compare_funcs <- function(new_funcs, old_funcs) {
  new_funcs <- new_funcs$functions
  old_funcs <- old_funcs$functions

  new_names <- names(new_funcs)
  old_names <- names(old_funcs)

  new_names <- new_names[!is.na(new_names) & nzchar(new_names)]
  old_names <- old_names[!is.na(old_names) & nzchar(old_names)]

  added_names <- setdiff(new_names, old_names)
  removed_names <- setdiff(old_names, new_names)
  common_names <- intersect(new_names, old_names)

  modified <- list()

  for (fn in common_names) {
    old_formals <- old_funcs[[fn]]
    new_formals <- new_funcs[[fn]]

    if (!identical(old_formals, new_formals)) {
      modified[[fn]] <- list(old = old_formals, new = new_formals)
    }
  }

  list(
    added = new_funcs[added_names],
    removed = old_funcs[removed_names],
    modified = modified
  )
}
