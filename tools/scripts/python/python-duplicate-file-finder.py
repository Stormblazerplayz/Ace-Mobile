# @title Duplicate File Finder
# @category Tools
# @kind Console program
# @where Save as duplicates.py and run: python3 duplicates.py, then type a folder. It only lists duplicates; it never deletes.
# @keywords python duplicate files, python hashlib, python find copies, python file fingerprint
# @about Finds files that are exact copies of each other (even with different names) using a SHA-256 fingerprint.

import hashlib
from collections import defaultdict
from pathlib import Path


def fingerprint(path):
    """Read the file in chunks and make a SHA-256 hash. Same content = same hash."""
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha.update(chunk)
    return sha.hexdigest()


folder = Path(input("Folder to scan: ").strip() or ".").expanduser()
if not folder.is_dir():
    raise SystemExit("That folder doesn't exist.")

# First group by size (fast), then only hash files that share a size
by_size = defaultdict(list)
for path in folder.rglob("*"):
    if path.is_file():
        by_size[path.stat().st_size].append(path)

by_hash = defaultdict(list)
for size, paths in by_size.items():
    if len(paths) > 1 and size > 0:
        for path in paths:
            by_hash[fingerprint(path)].append(path)

groups = [paths for paths in by_hash.values() if len(paths) > 1]
wasted = 0
for paths in groups:
    size = paths[0].stat().st_size
    wasted += size * (len(paths) - 1)
    print(f"\n{len(paths)} copies ({size:,} bytes each):")
    for path in paths:
        print("  ", path)
print(f"\nFound {len(groups)} groups of duplicates, wasting {wasted / 1_000_000:.1f} MB.")
