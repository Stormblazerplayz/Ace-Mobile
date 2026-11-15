# @title Reminder Scheduler
# @category Tools
# @kind Console program
# @where Save as reminders.py and run: python3 reminders.py, then add reminders like "10 drink water" (seconds then message).
# @keywords python reminders, python sched module, python schedule events, python run later
# @about Schedules reminders that pop up after a number of seconds, using Python's sched module.

import sched
import time

scheduler = sched.scheduler(time.time, time.sleep)


def remind(message):
    print(f"\a\n>>> REMINDER: {message} <<<")


print("Add reminders as: <seconds> <message>, for example: 30 stretch your legs")
print("Press Enter on an empty line when you're done adding.")
while True:
    line = input("Reminder: ").strip()
    if not line:
        break
    seconds, _, message = line.partition(" ")
    if not seconds.isdigit() or not message:
        print("Start with a number of seconds, then the message.")
        continue
    scheduler.enter(int(seconds), 1, remind, argument=(message,))
    print(f"Okay! I'll remind you in {seconds} seconds.")

if scheduler.empty():
    print("No reminders set.")
else:
    print(f"Waiting for {len(scheduler.queue)} reminders... (Ctrl+C to cancel)")
    try:
        scheduler.run()  # sleeps until each event is due, then runs it
        print("\nAll reminders done!")
    except KeyboardInterrupt:
        print("\nCancelled.")
