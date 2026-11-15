# @title Text Bar Chart from CSV
# @category Files and data
# @kind Console program
# @where Save as csv_chart.py and run: python3 csv_chart.py, then type a .csv file and which columns to chart (or press Enter for a sample).
# @keywords python bar chart, python text chart, python chart csv data, python visualize numbers terminal
# @about Draws a sideways bar chart in the terminal from any two columns of a CSV file.

import csv
import io
from pathlib import Path

SAMPLE = "month,prints_sold\nJan,12\nFeb,18\nMar,9\nApr,25\nMay,31\nJun,22\n"

name = input("CSV file (Enter for a sample): ").strip()
text = Path(name).expanduser().read_text(encoding="utf-8") if name else SAMPLE
reader = csv.DictReader(io.StringIO(text))
rows = list(reader)
columns = reader.fieldnames or []
print("Columns:", ", ".join(columns))

label_col = input(f"Label column (Enter for {columns[0]}): ").strip() or columns[0]
value_col = input(f"Number column (Enter for {columns[-1]}): ").strip() or columns[-1]

data = []
for row in rows:
    try:
        data.append((row[label_col], float(row[value_col])))
    except (KeyError, ValueError):
        pass  # skip rows that don't have a proper number

if not data:
    raise SystemExit("No numbers found in that column.")

biggest = max(value for _, value in data) or 1
width = max(len(label) for label, _ in data)
print(f"\n{value_col} by {label_col}")
for label, value in data:
    bar = "#" * round(value / biggest * 40)
    print(f"{label:>{width}} | {bar} {value:g}")
print(f"\nTotal: {sum(v for _, v in data):g}   Average: {sum(v for _, v in data) / len(data):.1f}")
