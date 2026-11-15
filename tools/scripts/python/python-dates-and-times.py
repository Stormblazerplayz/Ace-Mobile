# @title Dates and Times
# @category Basics
# @kind Console program
# @where Save as dates.py and run: python3 dates.py
# @keywords python datetime, python today date, python timedelta, python format date, python day of week
# @about Shows today's date and time, does date math and formats dates in different styles.

from datetime import date, datetime, timedelta

now = datetime.now()
today = date.today()

print("Right now:", now)
print("Today:", today)
print("Nice format:", now.strftime("%A, %B %d, %Y at %I:%M %p"))
print("Short format:", today.strftime("%m/%d/%y"))
print("Day of the week:", today.strftime("%A"))

# timedelta is an amount of time you can add or subtract
in_two_weeks = today + timedelta(weeks=2)
print("Two weeks from now:", in_two_weeks)
print("100 days ago:", today - timedelta(days=100))

# How many days until New Year's Day?
new_year = date(today.year + 1, 1, 1)
print("Days until New Year:", (new_year - today).days)

# Turn text into a date with strptime
birthday = datetime.strptime("2014-03-15", "%Y-%m-%d").date()
age_days = (today - birthday).days
print(f"Someone born on {birthday} is {age_days} days old")
