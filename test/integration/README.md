# Integration tests

This directory holds the integration test suite for `dart_jellyfin`.
The tests exercise a real Jellyfin server running locally in Docker,
seeded with a small royalty-free media library.

The lightweight drift watchdog at
[`../spec_drift_watchdog_test.dart`](../spec_drift_watchdog_test.dart)
runs on every `dart test` and does not require Docker — it only
checks the upstream OpenAPI spec for changes. The Docker-backed
integration suite below is opt-in via the `integration` tag.

## Quick start

1. Install Docker (Desktop, OrbStack, Colima, anything that gives
   you a working `docker compose`).
2. Copy `.env.test.example` to `.env.test`. The defaults work as-is
   for Jellyfin; no external account is needed.
3. Bring up the stack:

   ```sh
   docker compose up -d
   ```

4. (First time only) Run the bootstrap to drive the first-run wizard,
   create the admin user, add the seed library and trigger a scan:

   ```sh
   dart run test/integration/bootstrap.dart
   ```

5. Run the integration tests:

   ```sh
   dart test --tags integration
   ```

6. Tear down when done:

   ```sh
   docker compose down       # keeps volumes (~30s next start)
   docker compose down -v    # wipes volumes (~5min next start)
   ```

## What's tested

The integration suite focuses on the consumer-facing surface of the
library — roughly 30-40 endpoints across:

- Authentication and session lifecycle (`user`)
- Library browsing (`library`, `items`, `tvShows`, `movies`)
- Search (`search`)
- Image URLs and bytes fetch (`images`)
- Playback reporting (`playback`)
- Sessions (`sessions`)

Destructive admin endpoints (deleteLibrary, uninstallPlugin, …) and
hardware-dependent endpoints (Live TV tuner discovery) are tagged
`@Tags(['destructive'])` / `@Tags(['hardware'])` and skipped by
default. Run them explicitly with
`dart test --tags "integration && destructive"` after backing up the
test volumes.

## Why no CI?

These tests require Docker, several minutes per cold start, and a
local network port. They are designed to run on a contributor's
machine before opening a PR, not on every push. The spec drift
watchdog is the lightweight CI-friendly counterpart and runs on every
`dart test`.
