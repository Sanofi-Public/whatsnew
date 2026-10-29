# whatsnew NEWS

## whatsnew 1.0.0

### Initial Release

First public release of `whatsnew`, an R package for comparing different versions of R packages.

**Features:**

* **Package Version Comparison**: Compare two versions of any R package and identify differences in dependencies, functions, and documentation.

    * **Dependency Analysis**: Track changes in `Depends`, `Imports`, and `Suggests` fields between package versions, including version requirement modifications.

    * **Function Comparison**: Detect added, removed, and modified functions with detailed signature comparisons showing argument changes.

    * **Traceability Matrix**: Generate and compare traceability matrices between package versions to track function type changes (e.g., regular functions vs S3 generics).

* **Function Call Tree**: Build and visualize nested function call trees to understand dependencies between exported function and helper functions






