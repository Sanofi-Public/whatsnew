# inst/ — Scripts, Outputs & Risk Assessment

Package comparison and risk assessment tools. All scripts require the **whatsnew** package.

---

## File Layout

```
inst/
├── README.md              # This file
├── script/
│   ├── compare_renv_lock.R
│   ├── script_compare_package.R
│   └── funs.R             # Shared helpers (do not run directly)
├── env/
│   ├── renv_Rforsub.lock
│   ├── renv_Rforsub_old.lock
│   └── ...
└── result/                 # Output directory
    ├── renv_lock_comparison/
    └── package_json/
```

---

## Scripts

### compare_renv_lock.R

Compares two renv lock files, identifies package version differences, and runs `compare_package_versions` for each. Generates report, risk assessment, QMD files, and JSON diffs.

**Arguments:**
- `lock_old` — Path to old lock file. Default: package's `env/renv_Rforsub_old.lock` (or `inst/env/` when developing).
- `lock_new` — Path to new lock file. Default: package's `env/renv_Rforsub.lock`.
- `result_path` — Base output directory. Default: `tempdir()` (user-writable; avoids write failures in read-only package install locations).

**Example:**

```r
library(whatsnew)
source(system.file("script/compare_renv_lock.R", package = "whatsnew"))
compare_renv_lock_files()  # Uses defaults: package lock files, output to tempdir()

# Explicit paths
compare_renv_lock_files(
  lock_old = "inst/env/renv_Rforsub_old.lock",
  lock_new = "inst/env/renv_Rforsub.lock",
  result_path = "inst/result"
)
```

### script_compare_package.R

Compares specific package versions and saves the full diff as JSON. Edit the script to change packages. Uses `inst/result` when it exists (development), otherwise `tempdir()` for output.

**Example:**

```r
library(whatsnew)
source(system.file("script/script_compare_package.R", package = "whatsnew"))
# Produces inst/result/package_json/ or tempdir()/package_json/ (dplyr.json, admiral.json)
```

---

## Functions (funs.R)

Shared helpers. Source with: `source(system.file("script/funs.R", package = "whatsnew"), local = FALSE)`.

### shorten_path(path)

Strips project root from a path for readable report output.

```r
shorten_path("C:/Users/me/whatsnew/inst/env/renv.lock")
# Returns: "inst/env/renv.lock"
```

### make_qmd_from_diff(diff, result_path = ".")

Writes a QMD report from `compare_package_versions` output.

```r
diff <- whatsnew::compare_package_versions("dplyr", "1.1.4", "1.1.3")
make_qmd_from_diff(diff, result_path = "inst/result/renv_lock_comparison/package_reports")
# Creates: dplyr_1.1.3_to_1.1.4.qmd
```

### parse_renv_lock(lock_path)

Reads renv lock JSON and returns a data.frame with `name` and `version`.

```r
df <- parse_renv_lock("inst/env/renv_Rforsub.lock")
head(df)
#   name   version
# 1  DBI    1.2.3
# 2 Deriv   4.1.6
```

### compare_renv_packages(df_old, df_new)

Compares two parsed lock files. Returns list with `version_changed`, `added`, `removed`.

```r
df_old <- parse_renv_lock("inst/env/renv_Rforsub_old.lock")
df_new <- parse_renv_lock("inst/env/renv_Rforsub.lock")
diffs <- compare_renv_packages(df_old, df_new)
diffs$version_changed  # data.frame of packages with version changes
diffs$added            # packages only in new
diffs$removed          # packages only in old
```

### assess_package_risk(diff)

Evaluates a package diff against risk rules. Returns risk level, recommendation, dependency/function risks, and actions.

```r
diff <- whatsnew::compare_package_versions("dplyr", "1.1.4", "1.1.3")
risk <- assess_package_risk(diff)
risk$risk_level       # "high" | "medium" | "low"
risk$recommendation   # Suggested action
risk$actions         # Specific actions to take
risk$dependency_risks # List of dep risks
risk$function_risks  # List of function risks
```

---

## Result Output Structure

```
inst/result/
├── renv_lock_comparison/           # compare_renv_lock.R
│   ├── report.md                  # Full report
│   ├── risk_report.json           # Structured risk assessment
│   ├── package_reports/           # QMD per package
│   │   └── pkg_old_to_new.qmd
│   └── json/                      # Full diff per package
│       └── pkg_old_to_new.json
└── package_json/                   # script_compare_package.R
    ├── admiral.json
    └── dplyr.json
```

---

## Example Outputs (Params Modified, Params Removed)

The reports show different risk patterns:

| Change type | Example | Location |
|-------------|---------|----------|
| **Params modified** | `import_vctrs(name)` → `import_vctrs(name, optional = FALSE)` | `report.md` → dplyr 1.1.3→1.1.4 |
| **Params modified** | `across()` gains `.unpack` param | `package_json/dplyr.json` (1.0.9→1.1.4) |
| **Functions removed** | `validate_formula`, `vec_coalesce`, `match_up`, etc. | `package_json/dplyr.json` (1.0.9→1.1.4) |
| **Functions added** | `defer()`, `stop_invalid_namespaced_expression()` | `report.md` → purrr, dplyr |

**Params modified example** (from dplyr 1.1.3 → 1.1.4):

```
- import_vctrs:
  - 1.1.3: (name)
  + 1.1.4: (name, optional = FALSE)

- import_from:
  - 1.1.3: (name, package)
  + 1.1.4: (name, package, optional = FALSE)
```

**Params removed / Functions removed:** Compare dplyr 1.0.9 → 1.1.4 (`package_json/dplyr.json`) for many removed internal functions and param changes in `across`, `if_any`, `if_all`, `c_across`.

---

## Risk Assessment Rules: Analyzing Package Modification Impact

Use these rules when reviewing `report.md` and `risk_report.json`.

### 1. Version Change Severity

| Change type | Risk level | Action |
|-------------|------------|--------|
| **Major** (x.0.0 → y.0.0, y > x) | High | Expect breaking changes. Review all diffs. Plan regression testing. |
| **Minor** (x.y.0 → x.z.0, z > y) | Medium | New features; possible deprecations. Check function diffs. |
| **Patch** (x.y.z → x.y.w, w > z) | Low | Bug fixes, minor tweaks. Quick review of modified functions. |

### 2. Dependency Changes

| Change | Risk | What to do |
|--------|------|------------|
| **New Imports** | Medium | Verify new transitive deps don't conflict or introduce vulnerabilities. |
| **Removed Imports** | High | Check whether your code relies on re-exports from the updated package. |
| **Modified Imports** (version bump) | Low–Medium | Cascading updates: run compare on those packages too. |
| **Depends changes** | High | R version or base package changes; may require environment updates. |

### 3. Function Changes

| Change | Risk | Impact |
|--------|------|--------|
| **Functions removed** | High | Breaking: your code may call them. Search codebase for usages. |
| **Functions added** | Low | New API; no immediate breakage. |
| **Params modified** | High | Possible breaking change. Check removed params, changed order, new required params. |
| **Params added (optional)** | Low | Backward compatible if defaults are sensible. |
| **Params removed** | High | Breaking: update all call sites. |

### 4. Recommended Review Order

1. Packages with removed functions → Highest risk.
2. Packages with modified function params → Inspect each call site.
3. Packages with dependency changes → Assess transitive impact.
4. Packages with only added functions → Lower priority.

### 5. Decision Matrix

| Scenario | Recommendation |
|----------|----------------|
| Only patch bumps, no function diffs | Usually safe to accept. |
| Minor bump + new functions only | Accept after smoke tests. |
| Any removed functions or modified params | Manual review + regression tests before upgrade. |
| Major version bump | Full risk assessment and dedicated test campaign. |
| New/removed dependencies | Update lock file and re-run environment validation. |

---

## risk_report.json Structure

```json
{
  "generated": "2026-03-23 14:17:35",
  "lock_old": "inst/env/renv_Rforsub_old.lock",
  "lock_new": "inst/env/renv_Rforsub.lock",
  "summary": {
    "version_changed": 4,
    "added": 0,
    "removed": 0
  },
  "risk_assessments": {
    "dplyr": {
      "package": "dplyr",
      "version_old": "1.1.3",
      "version_new": "1.1.4",
      "risk_level": "high",
      "recommendation": "Manual review and regression tests before upgrade.",
      "dependency_risks": { ... },
      "function_risks": { ... },
      "actions": [ ... ]
    }
  },
  "compare_status": {
    "cli": "OK",
    "dplyr": "OK",
    ...
  }
}
```
