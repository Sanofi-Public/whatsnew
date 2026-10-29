"""R package detection for a study: list the packages its R scripts use."""

from __future__ import annotations

import re
from pathlib import Path

# library(pkg), library("pkg"), library('pkg'), require(pkg), etc.
_LIBRARY_RE = re.compile(
    r"""(?:library|require(?:Namespace)?)\s*\(\s*(?:package\s*=\s*)?["']?([A-Za-z][A-Za-z0-9._]*)["']?"""
)
# pkg:: or pkg::: namespace operator
_NAMESPACE_RE = re.compile(r"""([A-Za-z][A-Za-z0-9._]*):{2,3}""")

# Infrastructure packages used by the execution framework but never declared
# in user scripts: admeris runs the batch, logrx wraps each script via
# logrx::axecute().
INFRASTRUCTURE_PACKAGES = frozenset({"admeris", "logrx"})


def extract_packages_from_r_content(content: str) -> set[str]:
    """Return package names referenced in an R source string."""
    packages: set[str] = set()
    for match in _LIBRARY_RE.finditer(content):
        packages.add(match.group(1))
    for match in _NAMESPACE_RE.finditer(content):
        packages.add(match.group(1))
    return packages


def _batchlist_scripts(analysis_root: Path, batchlist_path: Path) -> list[Path]:
    """Return R script paths listed in the batchlist file that actually exist."""
    lines = batchlist_path.read_text(encoding="utf-8", errors="replace").splitlines()
    scripts: list[Path] = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        script_path = analysis_root / line
        if script_path.suffix.lower() == ".r" and script_path.is_file():
            scripts.append(script_path)
    return scripts


def collect_packages_from_batchlist(
    analysis_root: Path | str,
    batchlist_path: Path | str,
) -> set[str]:
    """Return all package names referenced in batchlist-listed R scripts."""
    packages: set[str] = set()
    for script in _batchlist_scripts(Path(analysis_root), Path(batchlist_path)):
        packages.update(
            extract_packages_from_r_content(
                script.read_text(encoding="utf-8", errors="replace")
            )
        )
    return packages


def collect_packages_from_folder(folder: Path | str) -> set[str]:
    """Return all package names referenced in R scripts found recursively in folder.

    Silently returns an empty set if the folder does not exist.
    """
    folder = Path(folder)
    if not folder.is_dir():
        return set()
    packages: set[str] = set()
    for script in sorted(folder.rglob("*.R")):
        if script.is_file():
            packages.update(
                extract_packages_from_r_content(
                    script.read_text(encoding="utf-8", errors="replace")
                )
            )
    return packages


def get_study_scripts(
    analysis_root: Path | str,
    batchlist_path: Path | str,
) -> list[Path]:
    """Return the study R scripts: batchlist scripts plus everything in MACRO."""
    analysis_root = Path(analysis_root)
    scripts = _batchlist_scripts(analysis_root, Path(batchlist_path))
    macro = analysis_root / "MACRO"
    if macro.is_dir():
        scripts += [p for p in sorted(macro.rglob("*.R")) if p.is_file()]
    return scripts


def get_study_packages(
    analysis_root: Path | str,
    batchlist_path: Path | str,
    include_infrastructure: bool = True,
) -> set[str]:
    """Return the packages used in the study.

    Detects packages via ``library()``/``require()`` calls and ``pkg::``
    namespace usage in the batchlist scripts and in ``<analysis_root>/MACRO``.
    When ``include_infrastructure`` is true, ``admeris`` and ``logrx`` are
    added because the execution framework calls them, not the user scripts.
    """
    analysis_root = Path(analysis_root)
    packages = collect_packages_from_batchlist(analysis_root, batchlist_path)
    packages |= collect_packages_from_folder(analysis_root / "MACRO")
    if include_infrastructure:
        packages |= INFRASTRUCTURE_PACKAGES
    return packages
