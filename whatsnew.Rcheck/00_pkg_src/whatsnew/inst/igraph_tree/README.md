## How function_tree example was created

This file is generated using the `whatsnew::function_tree()` function:

```r
library(whatsnew)
library(pkgnet)

fr <- FunctionReporter$new()

# Silence pkgnet messages (optional but recommended)
suppressWarnings(
  suppressMessages(
    fr$set_package(pkg_name = "stringr")
  )
)

g <- fr$pkg_graph$igraph


saveRDS(g, "inst/igraph_tree/stringr_call_graph.rds")

# To print
whatsnew::print_function_tree(ft)

```
Versions:

- stringr 1.5.2
- rlang 1.1.7


It is used as a mock for the `test-function_tree` unit test function.



```
Versions:

- stringr 1.5.2
- rlang 1.1.7
0.3.1 -> 0.3.2

It is used as a mock for the `test-function_tree` unit test function.

pkg_diff <- whatsnew::compare_package_versions("admeris", "0.3.1", "0.3.2")
path <- file.path(json_dir, "dplyr.json")
jsonlite::write_json(pkg_diff, path, pretty = TRUE)
