# Contributing

Thanks for helping improve HiCalendar! This repo is an Xcode + SwiftUI app with APNS/Supabase tooling. For detailed conventions, see AGENTS.md.

## Getting Started
- Clone and open: `open HiCalendar.xcodeproj`.
- iOS targets run on an iPhone 15 simulator (adjust as needed).
- For APNS/Supabase scripts: `python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`.

## Workflow
- Create a feature/bugfix branch: `git checkout -b feat/short-topic`.
- Keep changes small and focused; update docs when relevant (`PRD.md`, `Docs/`).
- Run checks before pushing: build + tests + scripts as applicable.

## Build & Test
- Build: `xcodebuild -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- Test: `xcodebuild ... test` or Xcode Product > Test.
- Python utilities (optional): `python simple_push_test.py` or `./manual_push.sh`.

## Coding Standards
- Follow Swift style in AGENTS.md (indentation, naming, file structure).
- One primary type per file; keep SwiftUI views and managers cohesive.

## Commits & PRs
- Conventional commits preferred: `feat:`, `fix:`, `chore:`, `docs:`, `test:`.
- PRs include: clear description, linked issues, screenshots/GIFs for UI changes, test plan, and doc updates.

## Security
- Never commit secrets (APNS keys, tokens). Use Keychain/env files ignored by Git.
- Follow APPLE_AUTH_SETUP.md, PUSH_SETUP_GUIDE.md, and setup_apns_env.md for credentials and push setup.

## Reference
- See AGENTS.md for project structure, commands, testing, and policies.
