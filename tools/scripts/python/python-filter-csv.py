# @title Filter and Sort CSV Data
# @category Files and data
# @kind Console program
# @where Save as filter_csv.py and run: python3 filter_csv.py. It uses a built-in sample of planets.
# @keywords python filter csv, python sort data, python query table, python data analysis basics
# @about Asks questions of a table of data: filter rows, sort by a column and save the results to a new CSV.

import csv
import io
from pathlib import Path

DATA = """planet,moons,diameter_km,day_hours,distance_au
Mercury,0,4879,4222.6,0.39
Venus,0,12104,2802.0,0.72
Earth,1,12756,24.0,1.0
Mars,2,6792,24.7,1.52
Jupiter,95,142984,9.9,5.2
Saturn,146,120536,10.7,9.54
Uranus,28,51118,17.2,19.2
Neptune,16,49528,16.1,30.06
"""

rows = list(csv.DictReader(io.StringIO(DATA)))
for row in rows:  # turn number columns into numbers
    for key in ("moons", "diameter_km", "day_hours", "distance_au"):
        row[key] = float(row[key])

print("Columns: moons, diameter_km, day_hours, distance_au")
column = input("Filter on which column? (Enter for moons): ").strip() or "moons"
if column not in rows[0] or column == "planet":
    raise SystemExit("Unknown number column.")
text = input(f"Show planets where {column} is at least: ").strip()
minimum = float(text) if text.replace(".", "", 1).isdigit() else 1

matches = [r for r in rows if r[column] >= minimum]
matches.sort(key=lambda r: r[column], reverse=True)
for r in matches:
    print(f"  {r['planet']:<8} {column} = {r[column]:g}")
print(f"{len(matches)} of {len(rows)} planets match.")

out = Path(__file__).with_name("filtered_planets.csv")
with open(out, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(matches)
print("Saved the results to", out.name)
