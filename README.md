# Zwimm

Swift iOS app for finding swimming sessions across multiple pools.

## Features
- Search swimming sessions by location and radius
- Filter by activity type (Banenzwemmen, Recreatief, etc.)
- Real-time distance calculation using Haversine formula
- Mock data for testing

## Build & Test

```bash
# Build locally (requires Docker)
./agent_runner.py

# Or run tests directly
python3 ./agent_runner.py
```

## CI/CD

The project uses GitHub Actions with a macOS runner to build and test on every push/PR.
