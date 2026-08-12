#!/usr/bin/env bash
# Regenerate the dart-dio client from the gateway-approved OpenAPI spec.
#
# Deterministic: rerunning this script on an unchanged spec must produce a
# zero git diff (verified in CI via `git diff --exit-code packages/notify_api`).
#
# Requires on PATH: node, java, dart, flutter, openapi-generator
# (dart pub global activate openapi_generator_cli).
#
# Pub mirrors: pub records the hosted base URL in pubspec.lock. Without the
# China mirrors below, `flutter pub get` rewrites every hosted URL to
# pub.dev, dirtying the root lockfile. The vars default to the mirrors so
# regen never causes lockfile churn; override the env to opt out.
#
# Generator pin: the wrapper resolves openapi-generator-cli 7.17.0; any other
# version aborts the run, because generator upgrades change the committed
# output and must be adopted deliberately (update EXPECTED_GENERATOR_VERSION
# and regenerate in the same commit).
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PKG_DIR/../.." && pwd)"
SPEC="$REPO_ROOT/packages/contracts/openapi/openapi.yaml"
WORK_DIR="$PKG_DIR/.dart_tool/openapi-generator"
NORMALIZED="$WORK_DIR/openapi.normalized.yaml"
EXPECTED_GENERATOR_VERSION="7.17.0"

export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

mkdir -p "$WORK_DIR"

# The openapi_generator_cli wrapper writes its own openapi_generator_config.json
# / jar cache into the cwd on *every* invocation, so never call it from a
# tracked directory — the work dir is gitignored.
ACTUAL_GENERATOR_VERSION="$(cd "$WORK_DIR" && openapi-generator version | tail -n 1 | tr -d '[:space:]')"
if [ "$ACTUAL_GENERATOR_VERSION" != "$EXPECTED_GENERATOR_VERSION" ]; then
  echo "regen: ERROR: expected openapi-generator $EXPECTED_GENERATOR_VERSION," >&2
  echo "regen: resolved $ACTUAL_GENERATOR_VERSION." >&2
  echo "regen: pin the wrapper to the expected jar, or bump" >&2
  echo "regen: EXPECTED_GENERATOR_VERSION and commit the regenerated output." >&2
  exit 1
fi

# 1. Normalize OpenAPI 3.1 `const` -> single-value `enum` (see tool/normalize-spec.mjs).
node "$PKG_DIR/tool/normalize-spec.mjs" "$SPEC" "$NORMALIZED"

# 2. Generate. Wipe lib/ and generator metadata first so stale models from
#    older specs cannot survive. Package-owned files (pubspec.yaml, test/,
#    tool/, ...) are protected by .openapi-generator-ignore.
rm -rf "$PKG_DIR/lib" "$PKG_DIR/.openapi-generator"
# Run from the gitignored work dir: the openapi_generator_cli wrapper writes
# its own openapi_generator_config.json / jar cache into the cwd.
(cd "$WORK_DIR" && openapi-generator generate \
  --generator-name dart-dio \
  --input-spec "$NORMALIZED" \
  --output "$PKG_DIR" \
  --additional-properties=pubName=notify_api,pubVersion=0.1.0,pubDescription="OpenAPI-generated gateway client for opencode-notify.",pubPublishTo=none)

# 3. Resolve workspace dependencies (lockfile-driven, deterministic; mirror
#    env above keeps pubspec.lock hosted URLs stable).
(cd "$REPO_ROOT" && flutter pub get)

# 4. Build the built_value/serializers .g.dart parts.
(cd "$PKG_DIR" && dart run build_runner build --delete-conflicting-outputs)

# 5. Normalize formatting of the generated sources so the committed output is
#    stable regardless of generator template whitespace.
dart format "$PKG_DIR/lib"

echo "regen: OK -> $PKG_DIR/lib"
