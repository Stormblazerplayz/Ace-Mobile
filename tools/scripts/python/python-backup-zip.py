# @title Backup a Folder to Zip
# @category Tools
# @kind Console program
# @where Save as backup.py and run: python3 backup.py, then type the folder to back up and where to save it.
# @keywords python backup folder, python zipfile, python make zip, python timestamp backup
# @about Packs a whole folder into a zip file with the date and time in its name, so you have a backup.

import zipfile
from datetime import datetime
from pathlib import Path

source = Path(input("Folder to back up: ").strip() or ".").expanduser().resolve()
if not source.is_dir():
    raise SystemExit("That folder doesn't exist.")
dest_dir = Path(input("Save the zip where? (Enter for the folder above it): ").strip() or source.parent).expanduser()
dest_dir.mkdir(parents=True, exist_ok=True)

stamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
zip_path = dest_dir / f"{source.name}_backup_{stamp}.zip"

count = 0
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for path in source.rglob("*"):
        if path.is_file() and path != zip_path:
            # arcname keeps the folders inside the zip relative to the source folder
            zf.write(path, arcname=path.relative_to(source))
            count += 1
            if count % 50 == 0:
                print(f"  {count} files packed...")

size_mb = zip_path.stat().st_size / 1_000_000
print(f"Backed up {count} files to {zip_path} ({size_mb:.2f} MB)")
