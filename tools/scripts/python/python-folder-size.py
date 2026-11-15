# @title Folder Size Report
# @category Tools
# @kind Console program
# @where Save as folder_size.py and run: python3 folder_size.py, then type a folder.
# @keywords python folder size, python directory size, python os walk, python storage report
# @about Shows how much space each subfolder uses, biggest first, with a bar chart made of text.

import os
from pathlib import Path


def folder_size(path):
    total = 0
    for root, _dirs, files in os.walk(path):  # walk visits every folder inside
        for name in files:
            try:
                total += os.path.getsize(os.path.join(root, name))
            except OSError:
                pass
    return total


folder = Path(input("Folder (Enter for this one): ").strip() or ".").expanduser()
sizes = []
for item in folder.iterdir():
    try:
        size = folder_size(item) if item.is_dir() else item.stat().st_size
    except OSError:
        continue
    sizes.append((size, item.name + ("/" if item.is_dir() else "")))

sizes.sort(reverse=True)
biggest = sizes[0][0] if sizes else 1
for size, name in sizes[:20]:
    bar = "#" * max(1, int(size / biggest * 30)) if size else ""
    print(f"{size / 1_000_000:9.2f} MB  {bar:<30} {name}")
print(f"\nTotal: {sum(s for s, _ in sizes) / 1_000_000:.2f} MB")
