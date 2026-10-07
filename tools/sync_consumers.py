"""Generate a reviewable package snapshot; never copy credentials or build output."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys


ENGINE = Path(__file__).resolve().parents[1]
PACKAGE = ENGINE / "packages" / "analytics_actions_flutter"
MANIFEST = "generated_manifest.json"


def canonical_snapshot() -> tuple[dict[str, bytes], bytes]:
    paths = [PACKAGE / "pubspec.yaml", PACKAGE / "analysis_options.yaml"]
    paths.extend(sorted((PACKAGE / "lib").rglob("*.dart")))
    files: dict[str, bytes] = {}
    for path in paths:
        if path.is_symlink() or not path.is_file():
            raise ValueError("Canonical package must contain regular source files")
        files[path.relative_to(PACKAGE).as_posix()] = path.read_bytes()
    manifest = {
        "schemaVersion": "shipglows.analytics.vendor.v1",
        "source": "shipglows-analytics-engine/packages/analytics_actions_flutter",
        "generated": True,
        "files": {name: hashlib.sha256(value).hexdigest() for name, value in sorted(files.items())},
    }
    return files, (json.dumps(manifest, indent=2, ensure_ascii=True) + "\n").encode("utf-8")


def destination(host: Path) -> Path:
    host = host.resolve(strict=True)
    if not (host / "pubspec.yaml").is_file():
        raise ValueError("--host must name a Flutter app containing pubspec.yaml")
    target = host / "vendor" / "analytics_actions_flutter"
    for path in [host / "vendor", target]:
        if path.is_symlink() or path.resolve().is_relative_to(host) is False:
            raise ValueError("Vendor target must remain inside the selected app")
    if target.exists():
        for path in target.rglob("*"):
            if path.is_symlink() or not path.resolve().is_relative_to(target.resolve()):
                raise ValueError("Vendor snapshot cannot contain symlinks or external targets")
    return target


def sync(host: Path, files: dict[str, bytes], manifest: bytes, check: bool) -> None:
    target = destination(host)
    expected = {**files, MANIFEST: manifest}
    existing = {path.relative_to(target).as_posix(): path for path in target.rglob("*") if path.is_file()}
    if check:
        drift = set(expected).symmetric_difference(existing)
        drift.update(name for name in set(expected).intersection(existing) if existing[name].read_bytes() != expected[name])
        if drift:
            raise ValueError("Vendor snapshot drift: " + ", ".join(sorted(drift)))
        print("analytics_actions_flutter: canonical snapshot verified")
        return
    stale = set(existing).difference(expected)
    previous_path = target / MANIFEST
    previous = json.loads(previous_path.read_text(encoding="utf-8")) if previous_path.exists() else {}
    managed = previous.get("files", {})
    for name in set(existing).intersection(files):
        actual = existing[name].read_bytes()
        if actual != files[name] and hashlib.sha256(actual).hexdigest() != managed.get(name):
            raise ValueError("Unmanaged or edited vendor file: " + name)
    if stale:
        # Remove only previously generated, unchanged source files. Never remove
        # unknown files or locally edited work to make the destination match.
        for name in stale:
            if name not in managed or hashlib.sha256(existing[name].read_bytes()).hexdigest() != managed[name]:
                raise ValueError("Unmanaged or edited vendor file: " + name)
        for name in stale:
            existing[name].unlink()
    for name, value in expected.items():
        path = target / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value)
    print("analytics_actions_flutter: generated canonical snapshot")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", type=Path, required=True, action="append", help="Explicit Flutter app path; repeat for multiple hosts")
    parser.add_argument("--check", action="store_true", help="Read-only exact source and manifest drift check")
    args = parser.parse_args()
    try:
        files, manifest = canonical_snapshot()
        for host in args.host:
            sync(host, files, manifest, args.check)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
