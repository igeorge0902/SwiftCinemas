#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/run-rest-test.sh [mocked|real] [test-identifier]
MODE="${1:-mocked}"
TEST_IDENTIFIER="${2:-SwiftCinemasTests/VenueForMoviesIntegrationTests/testLocations_UsesGetPathAndReturnsFixtureInMockMode}"
DESTINATION="${IOS_SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.1}"

if [[ "$MODE" != "mocked" && "$MODE" != "real" ]]; then
  echo "Invalid mode: '$MODE' (expected: mocked|real)" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running $TEST_IDENTIFIER with SWIFT_REST_BACKEND=$MODE"
SWIFT_REST_BACKEND="$MODE" xcodebuild test \
  -workspace SwiftCinemas.xcworkspace \
  -scheme SwiftCinemas \
  -destination "$DESTINATION" \
  -only-testing:"$TEST_IDENTIFIER"

