"""Check whether an R environment upgrade impacts the functions a study uses.

Steps:
1. Detect the packages used by the study scripts (see detect_study_packages).
2. Read the ``risk_report.json`` of the db-risk-rpackage repository for the two
   environment versions and keep the used packages whose version changed.
3. For each of them, read ``<pkg>_<old>_to_<new>.json`` (function diff) and
   collect the removed / modified functions.
4. Search the study scripts for calls to those functions and print them.

Usage::

    python check_env_impact.py --analysis-root tests/data \\
        --batchlist tests/data/REPORT/PGM/batchlist-dmc.txt \\
        --env-old int-v0.0.14 --env-new int-v0.0.15

The repository is read through the GitHub API (token from ``GITHUB_TOKEN``) or
from a local clone with ``--local-repo``.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Protocol

sys.path.insert(0, str(Path(__file__).resolve().parent))
from detect_study_packages import get_study_packages, get_study_scripts  # noqa: E402

DEFAULT_REPO = "Sanofi-GitHub/db-risk-rpackage"
DEFAULT_REF = "wise-env"
DEFAULT_API = "https://api.github.com"
RISK_REPORT_NAME = "risk_report.json"


class RepoSource(Protocol):
    def list_paths(self) -> list[str]: ...
    def read_text(self, path: str) -> str: ...


class LocalSource:
    """A local clone of the db-risk-rpackage repository."""

    def __init__(self, root: Path | str) -> None:
        self.root = Path(root)

    def list_paths(self) -> list[str]:
        return [
            p.relative_to(self.root).as_posix()
            for p in self.root.rglob("*.json")
            if ".git" not in p.parts
        ]

    def read_text(self, path: str) -> str:
        return (self.root / path).read_text(encoding="utf-8")


class GitHubSource:
    """The repository read through the GitHub REST API."""

    def __init__(self, repo: str, ref: str, token: str | None, api_url: str) -> None:
        self.repo, self.ref, self.token, self.api_url = repo, ref, token, api_url

    def _get(self, url: str, accept: str) -> bytes:
        headers = {"Accept": accept, "X-GitHub-Api-Version": "2022-11-28"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers)) as r:
            return r.read()

    def list_paths(self) -> list[str]:
        ref = urllib.parse.quote(self.ref, safe="")
        url = f"{self.api_url}/repos/{self.repo}/git/trees/{ref}?recursive=1"
        tree = json.loads(self._get(url, "application/vnd.github+json"))
        if tree.get("truncated"):
            print("warning: repository tree truncated by GitHub", file=sys.stderr)
        return [
            e["path"]
            for e in tree["tree"]
            if e["type"] == "blob" and e["path"].endswith(".json")
        ]

    def read_text(self, path: str) -> str:
        quoted = urllib.parse.quote(path)
        ref = urllib.parse.quote(self.ref, safe="")
        url = f"{self.api_url}/repos/{self.repo}/contents/{quoted}?ref={ref}"
        return self._get(url, "application/vnd.github.raw+json").decode("utf-8")


def _as_list(value: Any) -> list[str]:
    """The risk reports store single items as a bare string; normalise to a list."""
    if value is None:
        return []
    return [value] if isinstance(value, str) else list(value)


def find_risk_report(
    source: RepoSource, paths: list[str], env_old: str, env_new: str
) -> dict[str, Any]:
    """Return the risk_report.json comparing env_old to env_new."""
    candidates = [p for p in paths if p.rsplit("/", 1)[-1] == RISK_REPORT_NAME]
    # Cheap first pass: both versions appear in the path.
    ordered = sorted(candidates, key=lambda p: not (env_old in p and env_new in p))
    for path in ordered:
        report = json.loads(source.read_text(path))
        if env_old in report.get("lock_old", "") and env_new in report.get(
            "lock_new", ""
        ):
            report["_path"] = path
            return report
    raise SystemExit(
        f"No {RISK_REPORT_NAME} found for {env_old} -> {env_new} "
        f"({len(candidates)} report(s) checked)."
    )


def changed_used_packages(
    report: dict[str, Any], used: set[str]
) -> dict[str, tuple[str, str]]:
    """Used packages whose version differs between the two environments."""
    changed: dict[str, tuple[str, str]] = {}
    for name, info in report.get("risk_assessments", {}).items():
        if name in used and info["version_old"] != info["version_new"]:
            changed[name] = (info["version_old"], info["version_new"])
    return changed


def impacted_functions(
    source: RepoSource,
    paths: list[str],
    package: str,
    version_old: str,
    version_new: str,
    report: dict[str, Any],
) -> dict[str, str]:
    """Return {function: 'removed' | 'modified' | 'modified (optional args only)'}."""
    wanted = f"{package}_{version_old}_to_{version_new}.json"
    diff_path = next((p for p in paths if p.rsplit("/", 1)[-1] == wanted), None)
    if diff_path is None:
        print(f"  no diff file {wanted} in the repository", file=sys.stderr)
        return {}
    diff = json.loads(source.read_text(diff_path))["functions_diff"]

    optional_only = set(
        _as_list(
            report["risk_assessments"][package]
            .get("function_risks", {})
            .get("modified_optional_only", {})
            .get("functions")
            if isinstance(report["risk_assessments"][package].get("function_risks"), dict)
            else None
        )
    )
    impacted = {name: "removed" for name in diff.get("removed", {})}
    for name in diff.get("modified", {}):
        impacted[name] = (
            "modified (optional args only)" if name in optional_only else "modified"
        )
    return impacted


def find_usages(
    scripts: list[Path], package: str, functions: set[str]
) -> list[tuple[Path, int, str, str]]:
    """Return (script, line number, function, line) for each call to a function.

    ``other::fn(`` is ignored; ``fn(`` and ``package::fn(`` are matches.
    """
    if not functions:
        return []
    names = "|".join(re.escape(f) for f in sorted(functions, key=len, reverse=True))
    call = re.compile(rf"(?<![A-Za-z0-9._])(?:([A-Za-z][A-Za-z0-9._]*):{{2,3}})?({names})\s*\(")
    hits = []
    for script in scripts:
        text = script.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(text.splitlines(), start=1):
            code = line.split("#", 1)[0]
            for m in call.finditer(code):
                if m.group(1) in (None, package):
                    hits.append((script, number, m.group(2), line.strip()))
    return hits


def run(args: argparse.Namespace) -> int:
    source: RepoSource = (
        LocalSource(args.local_repo)
        if args.local_repo
        else GitHubSource(
            args.repo, args.ref, os.environ.get("GITHUB_TOKEN"), args.api_url
        )
    )
    used = get_study_packages(args.analysis_root, args.batchlist)
    scripts = get_study_scripts(args.analysis_root, args.batchlist)
    paths = source.list_paths()

    report = find_risk_report(source, paths, args.env_old, args.env_new)
    print(f"Environment change: {args.env_old} -> {args.env_new}")
    print(f"Risk report: {report['_path']}")

    changed = changed_used_packages(report, used)
    print()
    print(f"Study packages with a version change ({len(changed)}):")
    for name, (old, new) in sorted(changed.items()):
        print(f"- {name}: {old} -> {new}")
    if not changed:
        return 0

    impacted_total = 0
    for name, (old, new) in sorted(changed.items()):
        functions = impacted_functions(source, paths, name, old, new, report)
        hits = find_usages(scripts, name, set(functions))
        if not hits:
            continue
        print()
        print(f"{name} {old} -> {new}: impacted functions used in the study")
        for script, number, fn, line in hits:
            where = Path(script).relative_to(args.analysis_root).as_posix()
            print(f"  {where}:{number}  {fn} [{functions[fn]}]  {line}")
        impacted_total += len(hits)

    if impacted_total == 0:
        print()
        print("No impacted function is used in the study scripts.")
    return 1 if (impacted_total and args.fail_on_impact) else 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--analysis-root", required=True)
    p.add_argument("--batchlist", required=True)
    p.add_argument("--env-old", required=True, help="e.g. int-v0.0.14")
    p.add_argument("--env-new", required=True, help="e.g. int-v0.0.15")
    p.add_argument("--repo", default=DEFAULT_REPO)
    p.add_argument("--ref", default=DEFAULT_REF)
    p.add_argument("--api-url", default=DEFAULT_API)
    p.add_argument("--local-repo", help="Read a local clone instead of the GitHub API")
    p.add_argument("--fail-on-impact", action="store_true")
    return run(p.parse_args())


if __name__ == "__main__":
    sys.exit(main())
