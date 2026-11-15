# @title Write a CSV File
# @category Files and data
# @kind Console program
# @where Save as csv_writer.py and run: python3 csv_writer.py. Open the grades.csv it makes in Numbers, Excel or Google Sheets.
# @keywords python csv writer, python write spreadsheet, python dictwriter, python save table
# @about Asks for class grades and saves them to a CSV file you can open in any spreadsheet app.

import csv
from pathlib import Path

path = Path(__file__).with_name("grades.csv")
rows = []
print("Enter your classes and grades. Press Enter on an empty class name to finish.")
while True:
    subject = input("Class: ").strip()
    if not subject:
        break
    grade = input("Grade (0-100): ").strip()
    if not grade.isdigit():
        print("Grades need to be numbers.")
        continue
    rows.append({"class": subject, "grade": int(grade), "passed": "yes" if int(grade) >= 60 else "no"})

if not rows:
    rows = [{"class": "Math", "grade": 92, "passed": "yes"}, {"class": "Science", "grade": 88, "passed": "yes"}]
    print("No classes typed, so I'll save an example.")

with open(path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["class", "grade", "passed"])
    writer.writeheader()      # the first line holds the column names
    writer.writerows(rows)

print(f"Saved {len(rows)} rows to {path}")
print(path.read_text())
