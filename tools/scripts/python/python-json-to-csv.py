# @title Convert JSON to CSV
# @category Files and data
# @kind Console program
# @where Save as json2csv.py and run: python3 json2csv.py, then type a .json file that holds a list of objects (or press Enter for a sample).
# @keywords python json to csv, python flatten json, python export spreadsheet, python list of dicts to csv
# @about Turns a JSON list of objects into a CSV spreadsheet, collecting every key as a column.

import csv
import json
from pathlib import Path

SAMPLE = [
    {"name": "Sword", "damage": 12, "rarity": "rare"},
    {"name": "Bow", "damage": 8, "range": 30},
    {"name": "Potion", "heal": 25},
]

name = input("JSON file (Enter for a sample): ").strip()
if name:
    source = Path(name).expanduser()
    data = json.loads(source.read_text(encoding="utf-8"))
    target = source.with_suffix(".csv")
else:
    data = SAMPLE
    target = Path(__file__).with_name("sample.csv")

if not isinstance(data, list) or not all(isinstance(item, dict) for item in data):
    raise SystemExit("The JSON needs to be a list of objects, like [{...}, {...}].")

# Collect every key that appears anywhere, keeping the order we first see them
columns = []
for item in data:
    for key in item:
        if key not in columns:
            columns.append(key)

with open(target, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=columns, restval="")  # missing values become empty cells
    writer.writeheader()
    writer.writerows(data)

print(target.read_text(encoding="utf-8"))
print(f"Saved {len(data)} rows and {len(columns)} columns to {target}")
