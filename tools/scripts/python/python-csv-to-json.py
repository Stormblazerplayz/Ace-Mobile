# @title Convert CSV to JSON
# @category Files and data
# @kind Console program
# @where Save as csv2json.py and run: python3 csv2json.py, then type a .csv file path (or press Enter for a sample).
# @keywords python csv to json, python convert spreadsheet, python json dump list, python data conversion
# @about Turns a CSV spreadsheet into a JSON file, converting number columns into real numbers.

import csv
import io
import json
from pathlib import Path

SAMPLE = "name,age,city\nStorm,12,Denver\nNova,13,Austin\n"


def smart(value):
    """Turn '12' into 12 and '3.5' into 3.5, but leave words as words."""
    for kind in (int, float):
        try:
            return kind(value)
        except ValueError:
            pass
    return value


name = input("CSV file (Enter for a sample): ").strip()
if name:
    source = Path(name).expanduser()
    text = source.read_text(encoding="utf-8")
    target = source.with_suffix(".json")
else:
    text = SAMPLE
    target = Path(__file__).with_name("sample.json")

rows = [{key: smart(value) for key, value in row.items()} for row in csv.DictReader(io.StringIO(text))]
target.write_text(json.dumps(rows, indent=2), encoding="utf-8")
print(json.dumps(rows, indent=2))
print(f"\nSaved {len(rows)} records to {target}")
