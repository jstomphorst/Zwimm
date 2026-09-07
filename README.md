# Zwimm 🏊

> Find weekly swimming schedules (lap swim, baby swim, …) at pools near you — client/server app backed by a nightly schedule scraper, consumed by a SwiftUI iOS client.

## Repository layout

```
Zwimm/
├── Package.swift                     # SPM manifest (library + test target)
├── Sources/Zwimm/                    # Swift library code
├── Tests/ZwimmTests/                 # XCTest cases
├── Dockerfile                        # zwimm-agent image: Ubuntu 24.04 + Swift 6.3.3 + gh + python
├── .dockerignore                     # keep .env, .git, docs OUT of the image
├── agent_runner.py                   # Docker build+test orchestrator (JSON out, goose.md Run Log)
├── run.sh                            # convenience: docker build + run
├── .agents/agents/                   # Goose agent definitions
│   ├── builder.md                    #   swift build  (in Docker)
│   ├── tester.md                     #   swift test   (in Docker) + failure classification
│   └── dev-loop.md                   #   orchestrator entrypoint
├── specs/application_spec.md         # Full application spec (backend + iOS client)
├── goose.md                          # Persistent findings + Run Log (read before re-doing checks)
└── .env / .env.example               # FREELLM_API_KEY, GITHUB_TOKEN (never commit .env)
```

## Quick start — build & test (reproducible, Docker-backed)

```bash
./agent_runner.py              # builds image if missing, then `swift build` + `swift test` in Docker
./agent_runner.py --rebuild    # force a fresh docker build
./agent_runner.py --json-only  # only JSON on stdout, no progress
./agent_runner.py --skip-build # re-run tests only
./agent_runner.py --cycles 3   # max build/test cycles (default)
./agent_runner.py --image zwimm-agent  # use a different image name
```

Output: ONE JSON object describing status, per-cycle builder/tester results, and a
`next_action`. Every run appends a single line to `## Run Log` in `goose.md`.

Exit code: `0` on full success, `1` otherwise.

### Why Docker?

- **Isolated & reproducible** — no host Swift needed, no "works on my laptop".
- **Pinned toolchain** — Swift 6.3.3 (verified 2026-09-07, HTTP 200 on
  `download.swift.org` and confirmed by the Testing Library at runtime).
- **`.env` never baked into the image** — `.dockerignore` excludes it;
  volumes are mounted at runtime instead.

## Agents

All three agents are **Docker-based** and never edit sources (read/build/test only).

| Agent | Command / invocation | Purpose |
|---|---|---|
| `builder`  | `docker run --rm -v "$PWD:/app" -w /app zwimm-agent swift build` | Build, report errors/warnings |
| `tester`   | `docker run --rm -v "$PWD:/app" -w /app zwimm-agent swift test`  | Run tests, classify failures |
| `dev-loop` | `./agent_runner.py`                                           | Orchestrate both, log to `goose.md` |

Failure classes reported by `tester`: `compile_error` · `assertion` · `crash` · `env`.

## Local dev without Docker (optional)

If you have Swift ≥ 6.0 on your host, the same commands work directly:

```bash
swift build
swift test
```

`install_swift.sh` (old, Swift 5.10) and `run.sh` remain for reference, but the
recommended path is always `./agent_runner.py`.

## Environment variables

See `.env.example`. Copy it to `.env` and fill in real values. **`.env` must never
be committed** — it's git-ignored AND docker-ignored.

| Variable | Purpose |
|---|---|
| `FREELLM_API_KEY` | API key for the LLM provider used by the agent loop |
| `GITHUB_TOKEN`    | Used by `gh` for pushing branches / opening PRs (see `.agents/ios_developer_agent.md`) |

## Roadmap

See `specs/application_spec.md`. Open items tracked in `goose.md` and the top-level TODO.

---

## Oude notities (retained for history)

> ### Docker Test Confirmation
> - **Tested**: Docker build and run workflow confirmed functional.
>   - Build: `docker build -t zwimm-agent .`
>   - Run:   `docker run -it zwimm-agent`

### export.md (merged)
```sh
export GOOSE_PROVIDER="ollama"
export OLLAMA_HOST="http://localhost:11434"
export GOOSE_MODEL="qwen3.8:latest"
```
