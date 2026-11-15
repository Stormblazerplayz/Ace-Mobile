#!/usr/bin/env bash
# Checks Ace's built-in Python scripts: they must compile and pass pyflakes (no unused or undefined names).
# Run from the repo root: bash tools/scripts/check_python.sh   (pip install pyflakes first)
set -uo pipefail
DIR="tools/scripts/python"
checked=0
failed=0
shopt -s nullglob
for f in "$DIR"/*.py; do
  if python3 -m py_compile "$f" && python3 -m pyflakes "$f"; then
    checked=$((checked + 1))
  else
    echo "FAIL  $f" >&2
    failed=$((failed + 1))
  fi
done
echo "Python scripts checked: $checked, failed: $failed"
[ "$failed" -eq 0 ]
