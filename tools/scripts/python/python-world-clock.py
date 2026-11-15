# @title World Clock
# @category Tools
# @kind Console program
# @where Save as world_clock.py and run: python3 world_clock.py (on Windows you may need: pip install tzdata)
# @keywords python world clock, python time zones, python zoneinfo, python time in other countries
# @about Shows the current time in cities around the world using Python's built-in time zone support.

from datetime import datetime
from zoneinfo import ZoneInfo

CITIES = {
    "Los Angeles": "America/Los_Angeles",
    "New York": "America/New_York",
    "London": "Europe/London",
    "Paris": "Europe/Paris",
    "Dubai": "Asia/Dubai",
    "Tokyo": "Asia/Tokyo",
    "Sydney": "Australia/Sydney",
}

here = datetime.now().astimezone()
print(f"Your time: {here.strftime('%a %I:%M %p')}\n")
for city, zone in CITIES.items():
    there = datetime.now(ZoneInfo(zone))
    hour = there.hour
    icon = "day" if 7 <= hour < 19 else "night"
    # utcoffset tells how many hours ahead or behind UTC the city is
    offset = there.utcoffset().total_seconds() / 3600
    print(f"{city:<12} {there.strftime('%a %I:%M %p')}  ({icon}, UTC{offset:+.0f})")
