#!/usr/bin/env bash
# Compiles every Roblox Lua script with luau-compile (from github.com/luau-lang/luau releases).
# Run from the repo root: bash tools/scripts/check_lua.sh
set -uo pipefail
checked=0
failed=0
for f in tools/scripts/lua/*.lua; do
  if luau-compile --binary "$f" > /dev/null 2> /tmp/luau_err.txt; then
    checked=$((checked + 1))
  else
    echo "FAIL  $f: $(head -c 300 /tmp/luau_err.txt)" >&2
    failed=$((failed + 1))
  fi
done
echo "Lua scripts compiled: $checked, failed: $failed"
[ "$failed" -eq 0 ]
