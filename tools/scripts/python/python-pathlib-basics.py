# @title Paths and Folders with Pathlib
# @category Files and data
# @kind Console program
# @where Save as paths.py and run: python3 paths.py. It makes a small practice folder next to it.
# @keywords python pathlib, python make folder, python list files, python file extension, python path join
# @about Shows the easy, modern way to work with files and folders using pathlib.

from pathlib import Path

here = Path(__file__).parent          # the folder this script is in
practice = here / "practice_folder"   # the / joins path parts together
practice.mkdir(exist_ok=True)

# Make some files
for name in ["notes.txt", "song.mp3", "photo.png", "code.py"]:
    (practice / name).write_text(f"This is {name}\n")
(practice / "sub").mkdir(exist_ok=True)
(practice / "sub" / "deep.txt").write_text("hidden in a subfolder\n")

print("Folder:", practice)
for path in sorted(practice.iterdir()):
    kind = "folder" if path.is_dir() else f"{path.stat().st_size} bytes"
    print(f"  {path.name:<12} stem={path.stem:<6} suffix={path.suffix or '-':<5} {kind}")

print("\nAll .txt files, even in subfolders:")
for path in practice.rglob("*.txt"):
    print("  ", path.relative_to(here))

info = practice / "code.py"
print("\nParts of a path:", info.parts[-2:])
print("Change the extension:", info.with_suffix(".txt").name)
print("Does it exist?", info.exists())
print("Home folder:", Path.home())
