# @title Calendar Printer
# @category Tools
# @kind Console program
# @where Save as cal.py and run: python3 cal.py
# @keywords python calendar, python print month, python leap year, python weekday of date
# @about Prints a calendar for any month or a whole year, and tells you what day of the week a date falls on.

import calendar
from datetime import date

today = date.today()
text = input(f"Year (Enter for {today.year}): ").strip()
year = int(text) if text.isdigit() else today.year
text = input("Month 1-12 (Enter for the whole year): ").strip()

if text.isdigit() and 1 <= int(text) <= 12:
    print()
    print(calendar.month(year, int(text)))
else:
    print(calendar.calendar(year))

print(f"{year} is {'a leap year' if calendar.isleap(year) else 'not a leap year'}.")
text = input("Check a date (YYYY-MM-DD) to see its weekday, or press Enter: ").strip()
if text:
    try:
        d = date.fromisoformat(text)
        print(f"{d.strftime('%B %d, %Y')} is a {calendar.day_name[d.weekday()]}.")
    except ValueError:
        print("Use the format 2025-07-04.")
