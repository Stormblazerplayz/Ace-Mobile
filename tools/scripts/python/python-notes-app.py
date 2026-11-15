# @title Quick Notes
# @category Tools
# @kind Console program
# @where Save as notes.py and run: python3 notes.py. Notes are saved in notes.txt next to it.
# @keywords python notes app, python append to file, python search notes, python timestamp notes
# @about Jot down quick notes with the date and time, then list or search them later.

from datetime import datetime
from pathlib import Path

FILE = Path(__file__).with_name("notes.txt")

while True:
    choice = input("\n(w)rite, (l)ist, (s)earch or (q)uit? ").strip().lower()
    if choice == "w":
        note = input("Note: ").strip()
        if note:
            stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
            with open(FILE, "a", encoding="utf-8") as f:  # "a" adds to the end
                f.write(f"[{stamp}] {note}\n")
            print("Saved!")
    elif choice == "l":
        if FILE.exists():
            print(FILE.read_text(encoding="utf-8") or "(no notes yet)")
        else:
            print("(no notes yet)")
    elif choice == "s":
        word = input("Search for: ").strip().lower()
        lines = FILE.read_text(encoding="utf-8").splitlines() if FILE.exists() else []
        found = [line for line in lines if word in line.lower()]
        print("\n".join(found) if found else "Nothing found.")
    elif choice == "q":
        break
