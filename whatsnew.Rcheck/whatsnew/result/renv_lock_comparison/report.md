# renv Lock File Comparison Report
Generated: 2026-03-23 15:11:14

## Run Parameters
- lock_old: env/renv_Rforsub_old.lock
- lock_new: env/renv_Rforsub.lock
- result_path: inst/result

## Summary
- Version changed: 4
- Added (new only): 0
- Removed (old only): 0

## Version Changes

     name version_old version_new
19    cli       3.6.2       3.6.3
36  dplyr       1.1.3       1.1.4
103 purrr       1.0.1       1.0.2
123 rlang       1.1.3       1.1.4

## Compare Status

- cli: OK
- dplyr: OK
- purrr: OK
- rlang: OK

## Package Reports

### cli (3.6.2 → 3.6.3)

- **Risk level:** low
- **Recommendation:** Usually safe; quick review recommended.


### dplyr (1.1.3 → 1.1.4)

- **Risk level:** medium
- **Recommendation:** Review diffs; run smoke tests before upgrade.

**Dependency risks:**

- Imports_modified [low-medium]: vctrs: >= 0.6.0 -> >= 0.6.4 — Cascading update; run compare on those packages.

**Function risks:**

- modified_optional_only [low]: import_vctrs, import_from — Backward compatible if defaults are sensible.

**Imports:**

- Modified: vctrs: >= 0.6.0 -> >= 0.6.4


**Functions (Added) with params:**

- stop_invalid_namespaced_expression(expr, i, call)

- rethrow_error_join_matches_overflow(cnd, call)

**Functions (Modified) - params changed:**

- import_vctrs:
  - 1.1.3: (name)
  + 1.1.4: (name, optional = FALSE)

- import_from:
  - 1.1.3: (name, package)
  + 1.1.4: (name, package, optional = FALSE)


### purrr (1.0.1 → 1.0.2)

- **Risk level:** high
- **Recommendation:** Manual review and regression tests before upgrade.

**Actions:**
- Depends changed: may require environment updates.

**Dependency risks:**

- Depends_modified [low-medium]: R: >= 3.4.0 -> >= 3.5.0 — Cascading update; run compare on those packages.

- Imports_modified [low-medium]: cli: >= 3.4.0 -> >= 3.6.1, rlang: >= 0.4.10 -> >= 1.1.1, vctrs: >= 0.5.0 -> >= 0.6.3 — Cascading update; run compare on those packages.

**Function risks:**

- added [low]: defer — New API only.

**Depends:**

- Modified: R: >= 3.4.0 -> >= 3.5.0


**Imports:**

- Modified: cli: >= 3.4.0 -> >= 3.6.1, rlang: >= 0.4.10 -> >= 1.1.1, vctrs: >= 0.5.0 -> >= 0.6.3


**Functions (Added) with params:**

- defer(expr, env = caller_env(), after = FALSE)


### rlang (1.1.3 → 1.1.4)

- **Risk level:** low
- **Recommendation:** Usually safe; quick review recommended.

**Function risks:**

- added [low]: dyn_lgl_push_back, dyn_int_push_back, dyn_dbl_push_back, dyn_cpl_push_back, dyn_raw_push_back, dyn_chr_push_back, dyn_list_push_back — New API only.

**Functions (Added) with params:**

- dyn_lgl_push_back(x, value)

- dyn_int_push_back(x, value)

- dyn_dbl_push_back(x, value)

- dyn_cpl_push_back(x, value)

- dyn_raw_push_back(x, value)

- dyn_chr_push_back(x, value)

- dyn_list_push_back(x, value)


## Output
- Report: result/renv_lock_comparison
- Risk report (JSON): renv_lock_comparison/risk_report.json
- QMD: renv_lock_comparison/package_reports
- JSON: renv_lock_comparison/json

