"""Collect package-scoped changes between the previous tag and HEAD.

This is a convenience helper for monorepos with per-package folders.

Usage (from repo root):
  python tools/skills/changelog-from-tags/scripts/collect_changes.py --package ../screen_brightness_windows

It prints:
  - detected current version (from pubspec.yaml)
  - previous stable tag
  - commits list affecting the package dir
  - diff stat affecting the package dir
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path


STABLE_TAG_RE = re.compile(r"^\d+\.\d+\.\d+(?:\+\d+)?$")


def _run(args: list[str], cwd: Path) -> str:
    out = subprocess.check_output(args, cwd=str(cwd), stderr=subprocess.STDOUT)
    return out.decode("utf-8", errors="replace").strip()


def _read_pubspec_version(pubspec_path: Path) -> str:
    text = pubspec_path.read_text(encoding="utf-8")
    for line in text.splitlines():
        if line.strip().startswith("version:"):
            return line.split(":", 1)[1].strip()
    raise RuntimeError(f"No 'version:' found in {pubspec_path}")


@dataclass(frozen=True)
class Collected:
    current_version: str
    previous_tag: str
    commits: str
    diff_stat: str


def collect(package_dir: Path) -> Collected:
    package_dir = package_dir.resolve()
    pubspec = package_dir / "pubspec.yaml"
    if not pubspec.exists():
        raise RuntimeError(f"pubspec.yaml not found under: {package_dir}")

    current_version = _read_pubspec_version(pubspec)

    tags_raw = _run(["git", "-C", str(package_dir), "tag", "--list", "--sort=-v:refname"], cwd=package_dir)
    tags = [t.strip() for t in tags_raw.splitlines() if t.strip()]
    stable_tags = [t for t in tags if STABLE_TAG_RE.match(t)]
    if not stable_tags:
        raise RuntimeError("No stable tags found (expected like 1.2.3 or 1.2.3+4)")
    previous_tag = stable_tags[0]

    commits = _run(
        ["git", "-C", str(package_dir), "log", f"{previous_tag}..HEAD", "--oneline", "--decorate", "--", "."],
        cwd=package_dir,
    )
    diff_stat = _run(
        ["git", "-C", str(package_dir), "diff", "--stat", f"{previous_tag}..HEAD", "--", "."],
        cwd=package_dir,
    )

    return Collected(
        current_version=current_version,
        previous_tag=previous_tag,
        commits=commits,
        diff_stat=diff_stat,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True, help="Path to the package directory")
    ns = parser.parse_args()

    package_dir = Path(ns.package)
    collected = collect(package_dir)

    print(f"package: {package_dir}")
    print(f"currentVersion: {collected.current_version}")
    print(f"previousStableTag: {collected.previous_tag}")
    print("\n# commits (scoped)")
    print(collected.commits or "(none)")
    print("\n# diff --stat (scoped)")
    print(collected.diff_stat or "(none)")


if __name__ == "__main__":
    # Windows-friendly entrypoint.
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    main()
