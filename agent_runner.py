#!/usr/bin/env python3
"""Zwimm Autonomous Agent Runner — Docker-backed.

Runs the entire build + test cycle INSIDE the zwimm-agent Docker image so
every run happens in a clean, reproducible environment (no host Swift needed).

Local responsibilities:
  1. Ensure the Docker image exists (build it if missing or --rebuild).
  2. Run `docker run` for `swift build` and `swift test`.
  3. Parse logs, classify failures, emit ONE JSON report on stdout.
  4. Append one summary line to goose.md `## Run Log`.

Usage:
    ./agent_runner.py                  # build image if needed, then build + test in it
    ./agent_runner.py --rebuild        # force docker build first
    ./agent_runner.py --skip-build     # only re-run tests inside the image
    ./agent_runner.py --json-only      # suppress progress (stderr)
    ./agent_runner.py --cycles N       # max attempts (default 3, only assertion/crash retried)
    ./agent_runner.py --image NAME     # image name (default: zwimm-agent)
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
DOCKER_IMAGE = "zwimm-agent"


def log(msg: str, quiet: bool) -> None:
    if not quiet:
        print(msg, file=sys.stderr)


def run(cmd: list[str], quiet: bool, timeout: int = 1800) -> tuple[int, str]:
    log(f"  $ {' '.join(cmd)}", quiet)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") + (e.stderr or "")
        return 124, out + "\n[timeout]"
    return result.returncode, (result.stdout or "") + (result.stderr or "")


def docker_available() -> bool:
    return shutil.which("docker") is not None


def image_exists(image: str) -> bool:
    code, _ = run(["docker", "image", "inspect", image], quiet=True)
    return code == 0


def docker_build(image: str, quiet: bool) -> tuple[int, str]:
    log(f"[build-image] docker build -t {image} .", quiet)
    return run(
        ["docker", "build", "-t", image, "."],
        quiet=quiet,
        timeout=3600,
    )


def docker_swift(args: list[str], image: str, quiet: bool) -> tuple[int, str]:
    """Run swift inside the image, mount repo at /app (already the WORKDIR)."""
    cmd = [
        "docker", "run", "--rm",
        "-v", f"{REPO_ROOT}:/app",
        "-w", "/app",
        image,
        "swift", *args,
    ]
    return run(cmd, quiet=quiet)


def parse_error_lines(output: str, limit: int = 5) -> list[str]:
    out = []
    for line in output.splitlines():
        if re.search(r"\b(error|fatal error|XCTAssert)\b", line):
            out.append(line.strip())
        if len(out) >= limit:
            break
    return out


def parse_warning_lines(output: str, limit: int = 5) -> list[str]:
    out = []
    for line in output.splitlines():
        if re.search(r"\bwarn(ing|s)?\b", line, re.I):
            out.append(line.strip())
        if len(out) >= limit:
            break
    return out


def parse_test_summary(output: str) -> dict:
    result: dict = {}
    # Swift 5/6 format: "Executed N test(s), with M failures (K unexpected)"
    # Take the LAST occurrence (that's the "All tests" summary).
    execs = re.findall(r"Executed (\d+) tests?, with (\d+) failures? \((\d+) unexpected\)", output)
    if execs:
        total, failures, unexpected = (int(x) for x in execs[-1])
        result["total"] = total
        result["failed_count"] = failures
        result["unexpected"] = unexpected
        result["all_passed"] = failures == 0
    # failed test names — both Swift 5 and 6 log styles
    names = re.findall(r"Test Case '-\[[\w.]+ (\S+)\]' failed", output)
    if not names:
        names = re.findall(r"Test Case '([^']+)' failed:?", output)
    if not names:
        names = re.findall(r"^\s*\d+\)\s+(\S+/\S+)\s*$", output, re.M)
    result["failure_names"] = names[:10]
    result["failed_count"] = len(names)
    return result


def classify(output: str, names: list[str]) -> list[dict]:
    lower = output.lower()
    failures = []
    for name in names:
        if "compiling" in lower and "error" in lower:
            cls, detail = "compile_error", "test target failed to build"
        elif "xctassert" in lower or "assert" in lower:
            cls = "assertion"
            m = re.search(rf"{re.escape(name)}[^\n]*\n?([^\n]*)", output)
            detail = (m.group(1).strip() if m and m.group(1) else "assertion failure")[:200]
        elif "crash" in lower or "signal" in lower or "abort" in lower:
            cls, detail = "crash", "process crashed during test"
        else:
            cls, detail = "env", "unknown / likely environment"
        failures.append({"name": name, "class": cls, "detail": detail})
    return failures


def run_build_swift(image: str, quiet: bool) -> dict:
    base = {
        "agent": "builder",
        "mode": "docker",
        "image": image,
        "exit_code": None,
        "log": "<docker-stdout>",
    }
    code, out = docker_swift(["build", "--build-path", ".build"], image=image, quiet=quiet)
    base["exit_code"] = code
    base["errors"] = parse_error_lines(out)
    base["warnings"] = parse_warning_lines(out)
    base["status"] = "success" if code == 0 else "failure"
    if code != 0:
        base["snippet"] = "\n".join(out.splitlines()[-25:])
    # stash raw output on the object for the runner to reuse without re-running
    base["_raw"] = out
    return base


def run_test_swift(image: str, quiet: bool) -> dict:
    base = {
        "agent": "tester",
        "mode": "docker",
        "image": image,
        "exit_code": None,
        "log": "<docker-stdout>",
        "failures": [],
    }
    code, out = docker_swift(["test", "--build-path", ".build"], image=image, quiet=quiet)
    summary = parse_test_summary(out)
    base["exit_code"] = code
    base["total_tests"] = summary.get("total")
    base["failed"] = summary.get("failed_count", 0)
    base["passed"] = max(0, (summary.get("total") or 0) - (summary.get("failed_count") or 0)) if summary.get("total") is not None else None
    names = summary.get("failure_names", [])
    base["failures"] = classify(out, names)
    if code == 0 and not names:
        base["status"] = "all_passed"
    elif names:
        base["status"] = "failures"
    else:
        base["status"] = "error"
        base["snippet"] = "\n".join(out.splitlines()[-25:])
    base["_raw"] = out
    return base


def append_gooselog(line: str) -> None:
    goose_md = REPO_ROOT / "goose.md"
    existing = goose_md.read_text() if goose_md.exists() else ""
    if "## Run Log" not in existing:
        existing = (existing.rstrip() + "\n\n## Run Log\n" if existing else "## Run Log\n")
    with goose_md.open("a") as fh:
        fh.write(line + "\n")


def strip_internal(d: dict) -> dict:
    return {k: v for k, v in d.items() if not k.startswith("_")}


def main() -> int:
    parser = argparse.ArgumentParser(description="Zwimm Docker build & test orchestrator")
    parser.add_argument("--rebuild", action="store_true", help="force docker build even if image exists")
    parser.add_argument("--skip-build", action="store_true", help="skip swift build, only run tests")
    parser.add_argument("--json-only", action="store_true", help="suppress stderr progress")
    parser.add_argument("--cycles", type=int, default=3, help="max build/test cycles (default 3)")
    parser.add_argument("--image", default=DOCKER_IMAGE, help="docker image name")
    args = parser.parse_args()

    quiet = args.json_only
    cycles_report: list[dict] = []
    final_status = "env_blocked"
    final_test: dict | None = None
    final_build: dict | None = None
    image_built = False

    # --- 0. Ensure Docker image -------------------------------------------
    if not docker_available():
        report = {
            "agent": "dev-loop",
            "status": "env_blocked",
            "reason": "docker not installed on host",
            "next_action": "install docker, then re-run",
        }
        print(json.dumps(report, indent=2))
        return 1

    if not image_exists(args.image) or args.rebuild:
        log(f"[image] {args.image} missing or --rebuild -> building", quiet)
        code, out = docker_build(args.image, quiet=quiet)
        if code != 0:
            report = {
                "agent": "dev-loop",
                "status": "env_blocked",
                "reason": "docker build failed",
                "image": args.image,
                "docker_build_tail": out.splitlines()[-25:],
                "next_action": "fix Dockerfile (see .dockerignore + goose.md), then re-run",
            }
            print(json.dumps(report, indent=2))
            return 1
        image_built = True
    else:
        log(f"[image] {args.image} already present — reusing", quiet)

    # --- 1..N. Build/test cycles ------------------------------------------
    for i in range(1, max(1, args.cycles) + 1):
        if not args.skip_build:
            build = run_build_swift(args.image, quiet)
            final_build = build
            cycles_report.append({"cycle": i, "build": strip_internal(build)})
            log(f"[cycle {i}] swift build → {build['status']}", quiet)
            if build["status"] != "success":
                final_status = "build_failed"
                break

        test = run_test_swift(args.image, quiet)
        final_test = test
        cycles_report.append({"cycle": i, "test": strip_internal(test)})
        log(f"[cycle {i}] swift test → {test['status']}", quiet)

        if test["status"] == "all_passed":
            final_status = "success"
            break
        if test["status"] == "error" or any(f["class"] == "env" for f in test.get("failures", [])):
            final_status = "env_blocked" if test["status"] == "error" else "test_failed"
            break
        # assertion/crash: retrying without code changes is pointless
        final_status = "test_failed"
        break

    report = {
        "agent": "dev-loop",
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": final_status,
        "mode": "docker",
        "image": args.image,
        "image_built": image_built,
        "cycles": len({c["cycle"] for c in cycles_report}),
        "cycles_detail": cycles_report,
        "last_build": strip_internal(final_build) if final_build else None,
        "last_test": strip_internal(final_test) if final_test else None,
        "repo": str(REPO_ROOT),
        "next_action": {
            "success": "all good — proceed to next feature or commit",
            "build_failed": "inspect last_build.snippet, fix sources, re-run (add --rebuild if Dockerfile changed)",
            "test_failed": "inspect last_test.failures, fix assertions, re-run",
            "env_blocked": "resolve environment (docker/Swift/toolchain) then re-run",
        }.get(final_status, "see cycles_detail"),
    }

    # --- 1 line summary into goose.md -------------------------------------
    ts = report["timestamp"]
    passed = (final_test or {}).get("passed")
    total = (final_test or {}).get("total_tests")
    logline = f"- {ts}  dev-loop(docker:{args.image}) → {final_status}  (passed={passed} total={total})"
    try:
        append_gooselog(logline)
        log(f"logged: {logline}", quiet)
    except Exception as exc:  # noqa: BLE001
        log(f"warn: could not write goose.md: {exc}", quiet)

    print(json.dumps(report, indent=2))
    return 0 if final_status == "success" else 1


if __name__ == "__main__":
    sys.exit(main())
