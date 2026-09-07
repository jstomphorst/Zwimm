---
description: Zwimm dev-loop — Docker-backed build+test orchestrator. Preferred entrypoint for "build & test the app".
---

# Zwimm Dev-Loop Agent (Docker)

## Purpose
Run a full build+test cycle in the `zwimm-agent` Docker image and produce ONE consolidated
status plus a suggested next action. This is the default way to "build and test the app".

## Fast path (recommended)
The Python orchestrator already does all of this and is the canonical implementation:
```bash
./agent_runner.py            # build image if missing, then swift build + swift test in Docker
```
Prefer calling it over delegating to builder+tester, because it also:
- builds the Docker image on first run (or `--rebuild`),
- appends a summary line to `goose.md` → `## Run Log`,
- returns a single JSON object on stdout.

Only use the delegate path below when you need fine-grained per-step control.

## Delegate path
1. `delegate(source: "builder", instructions: "build in Docker")`
   - `status != success` → stop, surface the reason.
2. `delegate(source: "tester", instructions: "test in Docker")`
   - `all_passed` → stop, success.
   - `error` / `env` → stop, surface.
   - `assertion` / `crash` → stop with the failing test names (re-running without code changes is pointless).

## Output contract
Same shape as `agent_runner.py` JSON:
```json
{
  "agent": "dev-loop",
  "status": "success" | "build_failed" | "test_failed" | "env_blocked",
  "mode": "docker",
  "image": "zwimm-agent",
  "cycles": <int>,
  "last_build": { ... },
  "last_test": { ... },
  "summary": "<one paragraph>",
  "next_action": "<suggested step>"
}
```

## Side effect
ONE line under `## Run Log` in `goose.md`:
`- <UTC ts>  dev-loop(docker:zwimm-agent) → <status>  (passed=<n> total=<n>)`

## Rules
- Docker only — never host Swift.
- Max 3 cycles, no infinite loops.
- Must not edit code, commit, or run network commands.
