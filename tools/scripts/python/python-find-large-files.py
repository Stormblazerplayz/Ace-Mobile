# @title Find the Biggest Files
# @category Tools
# @kind Console program
# @where Save as bigfiles.py and run: python3 bigfiles.py, then type a folder to scan.
# @keywords python find large files, python disk space, python file sizes, python rglob
# @about Scans a folder and everything inside it, then lists the 15 biggest files so you can free up space.

from pathlib import Path


def human(size):
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


folder = Path(input("Folder to scan (Enter for this folder): ").strip() or ".").expanduser()
files = []
for path in folder.rglob("*"):
    try:
        if path.is_file():
            files.append((path.stat().st_size, path))
    except OSError:
        pass  # skip files we aren't allowed to read

files.sort(reverse=True)
total = sum(size for size, _ in files)
print(f"\n{len(files)} files, {human(total)} total. Biggest ones:")
for size, path in files[:15]:
    print(f"{human(size):>10}  {path}")
