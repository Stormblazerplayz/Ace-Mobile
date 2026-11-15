# @title Read a CSV File
# @category Files and data
# @kind Console program
# @where Save as csv_reader.py and run: python3 csv_reader.py. It makes a sample scores.csv the first time.
# @keywords python csv reader, python read spreadsheet, python dictreader, python csv columns
# @about Reads a spreadsheet saved as CSV, prints it as a neat table and finds the top score.

import csv
from pathlib import Path

path = Path(__file__).with_name("scores.csv")
if not path.exists():
    # Make a sample file so the script works right away
    path.write_text("name,game,score\nStorm,Minecraft,980\nDoodle,Roblox,1200\nNova,Minecraft,750\nAce,Fortnite,1100\n")

with open(path, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))  # each row becomes a dictionary like {"name": "Storm", ...}

if not rows:
    raise SystemExit("The file is empty.")

columns = list(rows[0].keys())
widths = {c: max(len(c), *(len(r[c]) for r in rows)) for c in columns}
print("  ".join(c.upper().ljust(widths[c]) for c in columns))
for row in rows:
    print("  ".join(row[c].ljust(widths[c]) for c in columns))

if "score" in columns:
    best = max(rows, key=lambda r: int(r["score"]))
    average = sum(int(r["score"]) for r in rows) / len(rows)
    print(f"\nTop score: {best['name']} with {best['score']}")
    print(f"Average score: {average:.1f}")
