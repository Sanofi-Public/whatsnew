pkgname <- "whatsnew"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('whatsnew')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("compare")
### * compare

flush(stderr()); flush(stdout())

### Name: compare
### Title: Compare Two Versions of a Package
### Aliases: compare

### ** Examples

## Not run: 
##D pkg_diff <- compare("dplyr", "1.1.4", "1.0.9")
##D str(pkg_diff)
## End(Not run)




cleanEx()
nameEx("compare_tm")
### * compare_tm

flush(stderr()); flush(stdout())

### Name: compare_tm
### Title: Compare Traceability Matrices (TM) Between Two Package Versions
### Aliases: compare_tm

### ** Examples

## Not run: 
##D # Compare traceability matrices for two versions of a package
##D diff_tm <- compare_tm("dplyr", "1.1.4", "1.0.8")
##D head(diff_tm)
## End(Not run)




cleanEx()
nameEx("function_tree")
### * function_tree

flush(stderr()); flush(stdout())

### Name: function_tree
### Title: Build a Nested Function Call Tree
### Aliases: function_tree

### ** Examples

## Not run: 
##D # Build a function call tree for stringr::str_detect
##D ft <- function_tree("stringr", root = "str_detect", depth = 3,
##D                     direction = "downstream")
##D 
##D print_function_tree(ft)
## End(Not run)




cleanEx()
nameEx("get_info")
### * get_info

flush(stderr()); flush(stdout())

### Name: get_info
### Title: Download and Parse a Specific Package Version
### Aliases: get_info

### ** Examples

## Not run: 
##D info_old <- get_info("dplyr", "1.0.9")
##D info_new <- get_info("dplyr", "1.1.4")
## End(Not run)




cleanEx()
nameEx("print_function_tree")
### * print_function_tree

flush(stderr()); flush(stdout())

### Name: print_function_tree
### Title: Print a Function Call Tree
### Aliases: print_function_tree

### ** Examples

## Not run: 
##D # Build a function tree (leaves are NULL)
##D ft <- function_tree_nested("stringr", root = "str_detect", depth = 3,
##D                            direction = "downstream", name_style = "pretty")
##D 
##D # Print with ASCII (default)
##D print_function_tree(ft)
##D 
## End(Not run)




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
