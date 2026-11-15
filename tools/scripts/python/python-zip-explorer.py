# @title Look Inside a Zip File
# @category Files and data
# @kind Console program
# @where Save as zip_explorer.py and run: python3 zip_explorer.py, then type a .zip file (or press Enter to make a test one).
# @keywords python read zip, python zipfile list, python extract zip, python compressed size
# @about Lists what's inside a zip file, how much each file was squished, and can unzip it into a folder.

import zipfile
from pathlib import Path

name = input("Zip file (Enter to make a test one): ").strip()
if name:
    path = Path(name).expanduser()
else:
    path = Path(__file__).with_name("test.zip")
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("readme.txt", "Hello! " * 200)
        zf.writestr("levels/level1.txt", "#####\n#P  #\n#####\n" * 20)
    print("Made test.zip")

with zipfile.ZipFile(path) as zf:
    print(f"\n{'File':<30}{'Size':>10}{'Zipped':>10}{'Saved':>7}")
    for info in zf.infolist():
        if info.is_dir():
            continue
        saved = 1 - info.compress_size / info.file_size if info.file_size else 0
        print(f"{info.filename:<30}{info.file_size:>10,}{info.compress_size:>10,}{saved:>7.0%}")
    if input("\nUnzip it into a folder? (y/n) ").strip().lower() == "y":
        target = path.with_suffix("")
        zf.extractall(target)
        print("Unzipped to", target)
