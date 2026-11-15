# @title Days Until...
# @category Tools
# @kind Console program
# @where Save as days_until.py and run: python3 days_until.py
# @keywords python days until birthday, python countdown to date, python date difference, python event countdown
# @about Counts the days, weeks and sleeps until your birthday, a holiday or any date you choose.

from datetime import date


def next_date(month, day):
    """The next time this month and day happens (this year or next year)."""
    today = date.today()
    target = date(today.year, month, day)
    if target < today:
        target = date(today.year + 1, month, day)
    return target


today = date.today()
events = {
    "New Year's Day": next_date(1, 1),
    "Halloween": next_date(10, 31),
    "Winter holidays": next_date(12, 25),
    "Summer start": next_date(6, 21),
}

text = input("Your birthday as MM-DD (or press Enter to skip): ").strip()
if text:
    try:
        month, day = (int(part) for part in text.split("-"))
        events["Your birthday"] = next_date(month, day)
    except ValueError:
        print("Hmm, that date didn't work. Use a format like 03-15.")

for name, when in sorted(events.items(), key=lambda item: item[1]):
    days = (when - today).days
    if days == 0:
        print(f"{name} is TODAY!")
    else:
        print(f"{name}: {days} days ({days // 7} weeks and {days % 7} days) on {when.strftime('%a %b %d')}")
