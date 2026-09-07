---
description: Zwimm tester — runs the test suite INSIDE the zwimm-agent Docker image, classifies failures, fixed JSON report
---

# Zwimm Tester Agent (Docker)

## Purpose
Run tests inside the `zwimm-agent` Docker image and return a machine-readable report. Never "fix" code — test only.

## Prerequisites
1. Read `goose.md` first.
2. Image `zwimm-agent` must exist (see `builder` agent if missing).
3. A `Package.swift` with a test target must be present at repo root.

## Test procedure
```bash
cd <repo-root>
docker run --rm -v "$PWD:/app" -w /app zwimm-agent swift test --build-path .build
```

## Failure classification (for each failing test)
- `compile_error` — test target failed to build.
- `assertion` — XCTAssertEqual / XCTAssert* failed.
- `crash` — process crashed / signal / timeout.
- `env` — needs network, credentials, or a missing binary.

Map every failing test name to exactly one of the classes above using the log lines.

## Output contract (ALWAYS the last line, valid JSON)
```json
{
  "agent": "tester",
  "mode": "docker",
  "image": "zwimm-agent",
  "status": "all_passed" | "failures" | "error",
  "total_tests": <int>,
  "passed": <int>,
  "failed": <int>,
  "exit_code": <int>,
  "failures": [
    { "name": "<TestClass/testMethod>",
      "class": "compile_error" | "assertion" | "crash" | "env",
      "detail": "<1-line reason>" }
  ],
  "snippet": "<last 25 lines on error>"
}
```

## Rules
- Do not edit sources or tests, do not commit, never use host Swift.
- If `swift test` cannot run (no image, no test target), set `status:"error"` with a reason.
- Log all-pass into `goose.md` Run Log: "Tests OK (<n> passed) @ <UTC ts>".
