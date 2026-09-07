---
description: Zwimm builder — builds the SPM package INSIDE the zwimm-agent Docker image, returns fixed JSON
---

# Zwimm Builder Agent (Docker)

## Purpose
Build the Zwimm Swift package inside the `zwimm-agent` Docker image. Never "fix" code — build only.

## Prerequisites
1. Read `goose.md` first — if the last Run Log line shows `dev-loop(docker:*) → success` and sources
   are unchanged, you may report the cached status unless the user asks for a rebuild.
2. `docker` must be on PATH (host requirement).
3. The image `zwimm-agent` must exist. If not, build it:
   `docker build -t zwimm-agent .`
   (The Dockerfile pins Swift 6.3.3, verified 2026-09-07.)

## Build procedure
```bash
cd <repo-root>
docker run --rm -v "$PWD:/app" -w /app zwimm-agent swift build --build-path .build
```

## Output contract (ALWAYS the last line, valid JSON)
```json
{
  "agent": "builder",
  "mode": "docker",
  "image": "zwimm-agent",
  "status": "success" | "failure" | "env_blocked",
  "exit_code": <int>,
  "errors": [ "<first 5 error lines>" ],
  "warnings": [ "<first 5 warning lines>" ],
  "snippet": "<last 25 lines on failure>"
}
```

## Rules
- Do not edit source files, do not commit, do not use host Swift (always Docker).
- On failure, include `snippet` so a human or a follow-up agent can act on it.
- Log success into `goose.md` Run Log: "Build OK @ <UTC ts>".
