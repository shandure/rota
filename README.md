# Rota — shift calendar for iOS

See `CLAUDE.md` for the full spec and working rules.

## Layout

- `RotaCore/` — models, `RotaEngine`, `Store` (shared framework for app + widget)
- `Rota/` — the app
- `RotaWidget/` — widget extension (step 7)
- `RotaTests/EngineTests/` — engine unit tests, one file per concern
- `project.yml` — XcodeGen spec; generates `Rota.xcodeproj` (git-ignored)
- `Package.swift` — lets the engine build and test with plain `swift test` (no Xcode)

## Build on a Mac

```bash
brew install xcodegen
xcodegen generate
open Rota.xcodeproj
```

## Run the engine tests anywhere (Docker)

```bash
docker run --rm -v "$PWD:/src" -w /src swift:6.0-jammy swift test
```
