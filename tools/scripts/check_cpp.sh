#!/usr/bin/env bash
# Syntax-checks Ace's built-in C++ programs and Arduino sketches.
# Run from the repo root: bash tools/scripts/check_cpp.sh
# Unreal Engine files are skipped (they need the Unreal build tools).
set -euo pipefail

CPP_DIR="tools/scripts/cpp"
STUB_DIR="tools/scripts/stubs"
CXX="${CXX:-g++}"

if [[ ! -d "$CPP_DIR" ]]; then
  echo "error: $CPP_DIR not found. Run this from the repo root." >&2
  exit 1
fi

checked=0
skipped=0
failed=0

shopt -s nullglob

for file in "$CPP_DIR"/*.cpp; do
  if grep -q '^// @category Unreal Engine$' "$file"; then
    echo "SKIP  $file (Unreal Engine)"
    skipped=$((skipped + 1))
    continue
  fi
  echo "CHECK $file"
  if "$CXX" -std=c++17 -Wall -Wextra -Werror -fsyntax-only "$file"; then
    checked=$((checked + 1))
  else
    echo "FAIL  $file" >&2
    failed=$((failed + 1))
  fi
done

for file in "$CPP_DIR"/*.ino; do
  echo "CHECK $file"
  if "$CXX" -std=c++17 -Wall -Wextra -Werror -fsyntax-only -x c++ \
      -I "$STUB_DIR" -include Arduino.h "$file"; then
    checked=$((checked + 1))
  else
    echo "FAIL  $file" >&2
    failed=$((failed + 1))
  fi
done

echo
echo "Checked: $checked  Skipped: $skipped  Failed: $failed"

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
if [[ "$checked" -eq 0 ]]; then
  echo "error: no files were checked" >&2
  exit 1
fi
