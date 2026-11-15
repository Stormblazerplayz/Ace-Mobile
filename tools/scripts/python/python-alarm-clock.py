# @title Alarm Clock
# @category Tools
# @kind Console program
# @where Save as alarm.py and run: python3 alarm.py, then type a time like 07:30 (24 hour clock).
# @keywords python alarm clock, python wake up time, python check current time, python snooze
# @about Waits until the time you set, then rings (beeps and prints) with an option to snooze.

import time
from datetime import datetime, timedelta

text = input("Alarm time (HH:MM, 24 hour): ").strip()
try:
    alarm_time = datetime.strptime(text, "%H:%M").time()
except ValueError:
    raise SystemExit("Please use a time like 07:30 or 18:05.")

now = datetime.now()
alarm = datetime.combine(now.date(), alarm_time)
if alarm <= now:
    alarm += timedelta(days=1)  # that time already passed today, so it means tomorrow
message = input("Alarm message: ").strip() or "WAKE UP!"

while True:
    print(f"Alarm set for {alarm.strftime('%A %H:%M')}. Press Ctrl+C to cancel.")
    try:
        while datetime.now() < alarm:
            time.sleep(1)
    except KeyboardInterrupt:
        raise SystemExit("\nAlarm cancelled.")
    for _ in range(5):
        print(f"\a*** {message} ***")
        time.sleep(0.5)
    if input("Snooze for 5 minutes? (y/n) ").strip().lower() != "y":
        break
    alarm = datetime.now() + timedelta(minutes=5)
print("Have a great day!")
