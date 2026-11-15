# @title Folder Organizer
# @category Tools
# @kind Console program
# @where Save as organizer.py and run: python3 organizer.py, then type a messy folder (like your Downloads). It asks before moving anything.
# @keywords python organize files, python sort downloads folder, python shutil move, python file types
# @about Tidies a messy folder by moving files into subfolders like Images, Videos, Documents and Code.

import shutil
from pathlib import Path

TYPES = {
    "Images": {".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".svg"},
    "Videos": {".mp4", ".mov", ".avi", ".mkv"},
    "Music": {".mp3", ".wav", ".m4a", ".flac"},
    "Documents": {".pdf", ".doc", ".docx", ".txt", ".md", ".pages", ".xlsx", ".pptx"},
    "Code": {".py", ".lua", ".swift", ".cpp", ".js", ".html", ".css", ".json"},
    "3D Models": {".stl", ".3mf", ".obj", ".gcode"},
    "Archives": {".zip", ".rar", ".7z", ".tar", ".gz"},
}

folder = Path(input("Folder to organize: ").strip() or ".").expanduser()
if not folder.is_dir():
    raise SystemExit("That folder doesn't exist.")

moves = []
for path in folder.iterdir():
    if not path.is_file() or path.name.startswith("."):
        continue
    group = next((name for name, exts in TYPES.items() if path.suffix.lower() in exts), "Other")
    moves.append((path, folder / group / path.name))

if not moves:
    raise SystemExit("Nothing to organize.")
for old, new in moves:
    print(f"  {old.name}  ->  {new.parent.name}/")

if input(f"\nMove these {len(moves)} files? (yes/no) ").strip().lower() == "yes":
    for old, new in moves:
        new.parent.mkdir(exist_ok=True)
        if new.exists():
            new = new.with_name(f"{new.stem}_copy{new.suffix}")  # don't overwrite
        shutil.move(str(old), str(new))
    print("All tidy!")
else:
    print("Nothing was moved.")
