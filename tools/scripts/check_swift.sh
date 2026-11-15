#!/usr/bin/env bash
# Checks Ace's built-in Swift scripts: each one must type-check on its own against the iOS 17 SDK.
# Needs a Mac with Xcode. Run from the repo root: bash tools/scripts/check_swift.sh
set -uo pipefail
DIR="tools/scripts/swift"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
checked=0
failed=0
shopt -s nullglob
for f in "$DIR"/*.swift; do
  if xcrun swiftc -typecheck -parse-as-library -sdk "$SDK" -target "$ARCH-apple-ios17.0-simulator" "$f" 2> "${TMPDIR:-/tmp}/swift-err.txt"; then
    checked=$((checked + 1))
  else
    echo "::error file=$f::$(head -c 800 "${TMPDIR:-/tmp}/swift-err.txt" | tr '\n' ' ')"
    failed=$((failed + 1))
  fi
done
echo "Swift scripts type-checked: $checked, failed: $failed"
[ "$failed" -eq 0 ]
