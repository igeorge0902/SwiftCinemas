# SwiftCinemas REST Tests

This test folder supports two backend modes for REST contract tests:

- `mocked` (default): deterministic tests using fixtures and `MockURLProtocol`
- `real`: live smoke calls against the configured backend in `URLManager.baseURL`

## Backend Mode Switch

Set environment variable:

- `SWIFT_REST_BACKEND=mocked`
- `SWIFT_REST_BACKEND=real`

If unset, mode defaults to `mocked`.

Helper files:

- `TestBackendMode.swift` -> resolves backend mode from env
- `MockHTTPTransport.swift` -> request capture + mock URL protocol
- `MockResponseFixtures.swift` -> endpoint fixture mapping

## Current Coverage

`VenueForMoviesIntegrationTests.swift` includes:

- mocked contract test for `MbooksService.locations()`
- mocked contract test for `MbooksService.moviesSearch(query:)`
- real-backend smoke test for `MbooksService.locations()` (auto-skipped unless mode is `real`)

## Run

```bash
cd /Users/gyorgy.gaspar/work/cinemas/cinemas/SwiftCinemas
scripts/run-rest-test.sh mocked
```

```bash
cd /Users/gyorgy.gaspar/work/cinemas/cinemas/SwiftCinemas
scripts/run-rest-test.sh real SwiftCinemasTests/VenueForMoviesIntegrationTests/testLocations_LiveSmokeWhenRealBackendEnabled
```

## Notes

- Fixture mapping is currently in-code for fast edits.
- Future phases can move fixtures to JSON files and expand coverage to `LoginGatewayService`.
- If `[CP] Embed Pods Frameworks` fails with `Operation not permitted`, run:

```bash
cd /Users/gyorgy.gaspar/work/cinemas/cinemas/SwiftCinemas
rm -rf ~/Library/Developer/Xcode/DerivedData/SwiftCinemas-*
xattr -dr com.apple.quarantine Pods || true
chmod -R u+rwX Pods
pod install
```
