# @title Bulk File Renamer
# @category Tools
# @kind Console program
# @where Save as renamer.py and run: python3 renamer.py, then type the folder path. It shows a preview before changing anything.
# @keywords python rename files, python bulk rename, python os rename, python number files
# @about Renames every file in a folder to a neat numbered pattern like photo_001.jpg, with a preview first.

from pathlib import Path

folder = Path(input("Folder to rename files in: ").strip() or ".").expanduser()
if not folder.is_dir():
    raise SystemExit("That folder doesn't exist.")

prefix = input("New name start (like 'photo'): ").strip() or "file"
only_ext = input("Only files ending in (like .jpg, or Enter for all): ").strip().lower()

files = sorted(p for p in folder.iterdir() if p.is_file() and (not only_ext or p.suffix.lower() == only_ext))
if not files:
    raise SystemExit("No matching files found.")

# Work out the new names first, so we can show a preview
plan = []
for number, path in enumerate(files, start=1):
    new_path = path.with_name(f"{prefix}_{number:03d}{path.suffix.lower()}")
    plan.append((path, new_path))

print("\nPreview:")
for old, new in plan:
    print(f"  {old.name}  ->  {new.name}")

if input(f"\nRename these {len(plan)} files? (yes/no) ").strip().lower() != "yes":
    raise SystemExit("Nothing was changed.")

# Rename to temporary names first so two files can't bump into each other
temps = []
for i, (old, new) in enumerate(plan):
    temp = old.with_name(f".renaming_{i}{old.suffix}")
    old.rename(temp)
    temps.append((temp, new))
for temp, new in temps:
    temp.rename(new)
print("Done!")
