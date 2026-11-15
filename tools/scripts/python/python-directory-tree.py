# @title Folder Tree Printer
# @category Files and data
# @kind Console program
# @where Save as tree.py and run: python3 tree.py, then type a folder.
# @keywords python directory tree, python folder tree, python recursive folders, python list subfolders
# @about Prints a folder and everything inside it as a tree, with lines connecting each file to its folder.

from pathlib import Path

counts = {"folders": 0, "files": 0}


def tree(folder, prefix="", depth=0, max_depth=4):
    try:
        items = sorted(folder.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
    except PermissionError:
        return
    items = [p for p in items if not p.name.startswith(".")]  # skip hidden files
    for i, item in enumerate(items):
        last = i == len(items) - 1
        print(prefix + ("`-- " if last else "|-- ") + item.name + ("/" if item.is_dir() else ""))
        if item.is_dir():
            counts["folders"] += 1
            if depth < max_depth:
                # The child's lines continue the bar unless this was the last item
                tree(item, prefix + ("    " if last else "|   "), depth + 1, max_depth)
        else:
            counts["files"] += 1


start = Path(input("Folder (Enter for this one): ").strip() or ".").expanduser().resolve()
print(start.name + "/")
tree(start)
print(f"\n{counts['folders']} folders, {counts['files']} files")
