# @title Merge CSV Files
# @category Files and data
# @kind Console program
# @where Save as merge_csv.py and run: python3 merge_csv.py, then type a folder of .csv files that share the same columns.
# @keywords python merge csv, python combine spreadsheets, python join csv files, python glob csv
# @about Combines every CSV file in a folder into one big CSV, adding a column that says which file each row came from.

import csv
from pathlib import Path

folder = Path(input("Folder with CSV files: ").strip() or ".").expanduser()
files = sorted(p for p in folder.glob("*.csv") if p.name != "merged.csv")
if not files:
    raise SystemExit("No .csv files found there.")

all_rows = []
columns = ["source_file"]
for path in files:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for column in reader.fieldnames or []:
            if column not in columns:
                columns.append(column)
        for row in reader:
            row["source_file"] = path.name
            all_rows.append(row)
    print(f"Read {path.name}")

out = folder / "merged.csv"
with open(out, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=columns, restval="")
    writer.writeheader()
    writer.writerows(all_rows)

print(f"\nMerged {len(all_rows)} rows from {len(files)} files into {out}")
print("Columns:", ", ".join(columns))
