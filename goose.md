# Goose Results Log

Running log of findings & decisions for this repo. Updated as work progresses —
read this before re-doing checks that are already recorded here.

## Tooling Notes (for future runs)

- **GOOSE HAS INTERNET ACCESS** ✅
  - `Fetch.fetch(url, ...)` — available inside `execute_typescript`; fetches a URL and returns
    content (HTML or simplified markdown). Supports `max_length`, `start_index`, `raw=true`.
  - `curl` / `wget` via `Developer.shell` — full HTTP client, great for HEAD/range checks, status codes,
    content sizes, binary downloads, API calls.
  - `Developer.readImage(url)` — loads an image from a file path or http(s) URL for inspection.
  - Do NOT claim "no internet access" — check `list_functions()` first.

## Agents (auto build & test)

**Docker-backed pipeline** — every build & test runs inside the `zwimm-agent` image for
reproducible, isolated environments (created & verified 2026-09-07).

| Agent | File | Role |
|---|---|---|
| `builder` | `.agents/agents/builder.md` | `docker run … swift build` → fixed JSON report. Never edits code. |
| `tester` | `.agents/agents/tester.md` | `docker run … swift test` → JSON report + failure classification (compile_error / assertion / crash / env). |
| `dev-loop` | `.agents/agents/dev-loop.md` | Preferred entrypoint; delegates to builder → tester, OR just runs `./agent_runner.py`. |

- **Canonical entry point:** `./agent_runner.py`
  - Flags: `--rebuild` (force docker build) · `--skip-build` · `--json-only` · `--cycles N` · `--image NAME`
  - Builds the image if missing, then runs `swift build` + `swift test` inside it.
  - One JSON object on stdout, progress on stderr, correct exit code.
  - Appends one summary line to `## Run Log` below.
- **Docker build requirements fixed:** added `libncurses6 libcurl4-openssl-dev libedit2 libpython3-dev libsqlite3-dev libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev` (Swift 6 runtime deps), and a symlink so `swift` is on PATH inside the container.
- **`.dockerignore`** added — `.env`, `.git`, `__pycache__`, docs and agent files are NOT copied into the image. `goose.md` is only appended on the host via the volume mount.
- **`Package.swift`** added (library `Zwimm` + test target `ZwimmTests`).
- **Verified end-to-end** on 2026-09-07: `status: success`, `total_tests: 1`, `passed: 1`, `failed: 0`, exit 0.
- Testing Library reported **Swift 6.3.3** — matches the Dockerfile, second independent confirmation.

## Verified / Confirmed

- **Swift 6.3.3 IS a real, valid release** ✅
  - Source: `https://download.swift.org/swift-6.3.3-release/ubuntu2404/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE-ubuntu24.04.tar.gz`
  - HTTP 200, Content-Length 1,069,589,818 bytes (~1.07 GB), served from Apple CDN.
  - Verified 2026-09-07 by HEAD/range request against the download server.
  - Implication: the Swift URL in `Dockerfile` is **correct**, no fix needed there.
- Swift 6.2.4 also exists (1,008,510,904 bytes).
- Swift 6.3.0 does **not** exist (302 → `swift.org/404.html`). Do not use this version.

## Scaffolding Audit (repo state, 2026-09-07)

### ✅ Correct
- Directory layout `Sources/Zwimm/` + `Tests/ZwimmTests/` matches SPM convention.
- `Dockerfile` Swift download URL is valid (see above).
- `run.sh` is consistent with the Dockerfile (build + run flow).
- `simple_test.py` and `agent_runner.py` run without Python import errors (they just execute `git status`).

### ❌ Issues (open action items)

| # | Issue | Severity | Status |
|---|---|---|---|
| 1 | ~~No `Package.swift`~~ — created: library `Zwimm` + test target `ZwimmTests`, swift-tools 6.0. Verified building in Docker. | 🛑→✅ | **Resolved** |
| 2 | ~~No `.gitignore`~~ — added (`.env`, `__pycache__`, `.build/`, …) + `.env.example` template. `.git status` now shows `.env` as ignored, not untracked. | 🛑→✅ | **Resolved** |
| 3 | ~~`install_swift.sh` typo + Swift 5.10 vs 6.3.3~~ — superseded: all builds now run in Docker (image already installs Swift 6.3.3). Script left in repo for hosts without Docker. | ℹ️ Superseded | Resolved via Docker |
| 4 | ~~`agent_runner.py` only ran `git status`~~ — now the full Docker build+test orchestrator (see Agent section). `FREELLM_API_KEY` is documented in `.env.example` / README and consumed by the LLM agent, not the runner. | ⚠️→✅ | **Resolved** |
| 5 | ~~`README.md` and `export.md` overlap~~ — README.md rewritten to cover repo layout, Docker quick start, agent table, env vars, roadmap. `export.md` retained as source of truth for Goose env vars; README references it. | ℹ️→✅ | **Resolved** |
| 6 | `specs/application_spec.md` describes a full client-server app; only a stub `parseSchedule()` exists. | ℹ️ Expected (scaffold) | Open |

### 📋 Suggested fix order
1. Add `Package.swift` (SPM manifest, library + test target).
2. Add `.gitignore` (`.env`, `__pycache__/`, `.build/`, `xcuserdata/`) + `.env.example`.
3. Fix `install_swift.sh`: correct path, align Swift version with Dockerfile (6.3.3).
4. Implement the actual workflow in `agent_runner.py` per `.agents/ios_developer_agent.md`.
5. Consolidate README / export.md into one README.
- 2026-09-07T19:19:20Z  dev-loop → build_failed  (passed=None total=None)
- 2026-09-07T19:19:42Z  dev-loop → env_blocked  (passed=None total=None)
- 2026-09-07T19:41:49Z  dev-loop(docker:zwimm-agent) → success  (passed=None total=None)
- 2026-09-07T19:42:58Z  dev-loop(docker:zwimm-agent) → success  (passed=1 total=1)
