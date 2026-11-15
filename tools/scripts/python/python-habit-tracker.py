# @title Habit Tracker
# @category Tools
# @kind Console program
# @where Save as habits.py and run: python3 habits.py once a day. Data is saved in habits.json.
# @keywords python habit tracker, python daily streak, python json dates, python check in
# @about Tracks daily habits like reading or practicing, and shows your current streak for each one.

import json
from datetime import date, timedelta
from pathlib import Path

FILE = Path(__file__).with_name("habits.json")
data = json.loads(FILE.read_text()) if FILE.exists() else {}  # habit name -> list of dates done


def streak(days):
    """Count how many days in a row (ending today or yesterday) the habit was done."""
    done = set(days)
    day = date.today()
    if day.isoformat() not in done:
        day -= timedelta(days=1)  # today isn't over yet, so start from yesterday
    count = 0
    while day.isoformat() in done:
        count += 1
        day -= timedelta(days=1)
    return count


while True:
    today = date.today().isoformat()
    print("\n=== Habits ===")
    names = sorted(data)
    for i, name in enumerate(names, start=1):
        mark = "x" if today in data[name] else " "
        print(f"{i}. [{mark}] {name}  (streak: {streak(data[name])} days)")
    choice = input("Number to check in, 'new' to add a habit, or 'q' to quit: ").strip().lower()
    if choice == "q":
        break
    if choice == "new":
        name = input("Habit name: ").strip()
        if name:
            data.setdefault(name, [])
    elif choice.isdigit() and 1 <= int(choice) <= len(names):
        days = data[names[int(choice) - 1]]
        if today not in days:
            days.append(today)
            print("Nice work! Checked in.")
    FILE.write_text(json.dumps(data, indent=2))
