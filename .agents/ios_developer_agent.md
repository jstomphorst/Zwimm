# Autonomous iOS Developer Agent

## Overview
This agent automates the full lifecycle of a feature or bugfix for the Zwimm iPhone application:
1. **Understand**: Parse user instruction / feature request.
2. **Develop**: Implement changes in the iOS project (Swift/SwiftUI).
3. **Test**: Run local tests (e.g., using xcodebuild).
4. **Fix**: If tests fail, analyze logs, apply fixes, and re-test iteratively.
5. **Git Commit**: Commit changes with a conventional commit message.
6. **Push & PR**: Push branch to remote and create or update a Pull Request via GitHub CLI (`gh`).

## Workflow Steps
- **Step 1**: Check out a new feature branch (`git checkout -b feature/<name>`).
- **Step 2**: Implement requirements.
- **Step 3**: Run tests (`xcodebuild test ...`).
- **Step 4**: Self-heal / Fix errors if tests fail.
- **Step 5**: Push branch and open/update PR.
