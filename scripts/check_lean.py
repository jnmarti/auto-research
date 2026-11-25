#!/usr/bin/env python3
"""Compile and audit every Lean proof file under research/."""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / "research"
AUDIT = ROOT / "scripts" / "AuditProofs.lean"
REQUIRED = RESEARCH / "portable-checkpoints" / "lean" / "PortableCheckpoints.lean"


def fail(message: str) -> None:
    raise SystemExit(message)


def cache_dependencies(lake: str, lean: str, files: list[Path], env: dict[str, str]) -> None:
    packages = (ROOT / ".lake" / "packages").resolve()
    source_roots = sorted(
        (Path(part).resolve() for part in env["LEAN_SRC_PATH"].split(os.pathsep) if part),
        key=lambda path: len(path.parts),
        reverse=True,
    )
    deps = set()
    for path in files:
        output = subprocess.check_output(
            [lean, f"--root={path.parent}", "--src-deps", str(path)],
            cwd=ROOT,
            env=env,
            text=True,
        )
        for line in output.splitlines():
            source = Path(line).resolve()
            for root in source_roots:
                if root.is_relative_to(packages) and source.is_relative_to(root):
                    deps.add(".".join(source.relative_to(root).with_suffix("").parts))
                    break
    if deps:
        print(f"Fetching cache for {len(deps)} imports: {', '.join(sorted(deps))}", flush=True)
        subprocess.run([lake, "exe", "cache", "get", *sorted(deps)], cwd=ROOT, env=env, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch-cache", action="store_true", help="fetch cache for imports")
    args = parser.parse_args()
    toolchain = (ROOT / "lean-toolchain").read_text(encoding="utf-8").strip()
    match = re.fullmatch(r"leanprover/lean4:v([0-9]+\.[0-9]+\.[0-9]+)", toolchain)
    if not match:
        fail(f"Expected a pinned Lean release in lean-toolchain; found {toolchain!r}")
    lean = shutil.which("lean")
    lake = shutil.which("lake")
    if lean is None or lake is None:
        fail("Lean and Lake are required. Install Elan and use the repository's lean-toolchain.")
    if not os.environ.get("LEAN_SRC_PATH"):
        fail("Run this checker with 'lake env python3 scripts/check_lean.py'.")
    version = subprocess.check_output([lean, "--version"], cwd=ROOT, text=True).strip()
    if not version.startswith(f"Lean (version {match[1]},"):
        fail(f"Expected Lean {match[1]} from lean-toolchain; found {version}")
    print(version, flush=True)

    if RESEARCH.is_symlink() or not RESEARCH.is_dir():
        fail("Expected a regular research/ directory.")
    paths = sorted(RESEARCH.rglob("*.lean"))
    if REQUIRED not in paths:
        fail(f"Required proof is missing: {REQUIRED.relative_to(ROOT)}")
    env = dict(os.environ)
    libdir = Path(subprocess.check_output(
        [lean, "--print-libdir"], cwd=ROOT, env=env, text=True,
    ).strip())
    lean_path = env.get("LEAN_PATH", "")
    import_roots = [libdir, *(Path(p) for p in lean_path.split(os.pathsep) if p)]
    for path in paths:
        if not path.is_file() or path.is_symlink():
            fail(f"Expected a regular Lean source: {path.relative_to(ROOT)}")
        if not path.read_text(encoding="utf-8").strip():
            fail(f"Empty Lean source: {path.relative_to(ROOT)}")
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", path.stem):
            fail(f"Use an ASCII Lean module name for {path.relative_to(ROOT)}.")
        if any((root / f"{path.stem}.olean").is_file() for root in import_roots):
            fail(f"Research module shadows a dependency module: {path.relative_to(ROOT)}")

    if args.fetch_cache:
        cache_dependencies(lake, lean, paths, env)

    flags = ["--trust=0", "-DwarningAsError=true", "-E", "hasSorry"]
    for path in paths:
        print(f"Checking {path.relative_to(ROOT)}", flush=True)
        with tempfile.TemporaryDirectory(prefix="research-lean-") as tmp:
            # A separate directory per source prevents collisions between modules
            # of different papers that happen to have the same file name.
            module = path.stem
            olean = Path(tmp) / f"{module}.olean"
            subprocess.run(
                [lean, *flags, f"--root={path.parent}", "-o", str(olean), str(path)],
                cwd=ROOT,
                env=env,
                check=True,
            )
            subprocess.run(
                [lean, *flags, "--run", str(AUDIT), module],
                cwd=ROOT,
                env={**env, "LEAN_PATH": os.pathsep.join(p for p in (tmp, lean_path) if p)},
                check=True,
            )
    print(f"Checked {len(paths)} Lean proof file(s).", flush=True)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        fail(f"Lean proof check failed (exit {error.returncode}).")
