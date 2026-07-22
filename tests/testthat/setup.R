library(dplyr)

# import an example of igraph object for testing
load_fixture_graph <- function(name) {
  # Changing locales to ensures consistent behavior
  path <- system.file("igraph_tree", name, package = "whatsnew")
  if (path == "") stop("Missing fixture: ", name, call. = FALSE)
  readRDS(path)
}

try(Sys.setlocale("LC_COLLATE", "C"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE",   "C"), silent = TRUE)

