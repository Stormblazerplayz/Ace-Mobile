# @title Search Inside Files
# @category Tools
# @kind Console program
# @where Save as search_files.py and run: python3 search_files.py, then type a folder and a word to find.
# @keywords python search in files, python grep, python find text in folder, python line numbers
# @about Searches every text file in a folder for a word and shows the file, line number and line where it appears.

from pathlib import Path

folder = Path(input("Folder to search: ").strip() or ".").expanduser()
word = input("Word or phrase to find: ").strip()
if not word:
    raise SystemExit("Type something to search for.")
ext = input("Only files ending in (like .py, Enter for .txt .py .md .json .lua .swift): ").strip()
extensions = {ext} if ext else {".txt", ".py", ".md", ".json", ".lua", ".swift", ".csv"}

matches = 0
for path in sorted(folder.rglob("*")):
    if not path.is_file() or path.suffix.lower() not in extensions:
        continue
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (UnicodeDecodeError, OSError):
        continue  # skip files that aren't plain text
    for number, line in enumerate(lines, start=1):
        if word.lower() in line.lower():
            matches += 1
            print(f"{path}:{number}: {line.strip()[:100]}")

print(f"\n{matches} matches found.")
