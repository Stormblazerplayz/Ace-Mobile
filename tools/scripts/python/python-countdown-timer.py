# @title Countdown Timer
# @category Tools
# @kind Console program
# @where Save as timer.py and run: python3 timer.py, then type a time like 5m, 90s or 1m30s.
# @keywords python countdown timer, python timer minutes seconds, python carriage return, python beep
# @about A countdown timer that updates in place on one line and beeps when time is up.

import re
import time

text = input("How long? (like 5m, 90s or 1m30s): ").strip().lower()
match = re.fullmatch(r"(?:(\d+)m)?\s*(?:(\d+)s?)?", text)
if not text or not match:
    raise SystemExit("I didn't understand that time.")

minutes = int(match.group(1) or 0)
seconds = int(match.group(2) or 0)
total = minutes * 60 + seconds
if total <= 0:
    raise SystemExit("The timer needs more than 0 seconds.")

end = time.time() + total
try:
    while True:
        left = round(end - time.time())
        if left <= 0:
            break
        m, s = divmod(left, 60)
        # \r jumps back to the start of the line so the timer updates in place
        print(f"\r  {m:02d}:{s:02d} left  ", end="", flush=True)
        time.sleep(0.2)
except KeyboardInterrupt:
    raise SystemExit("\nTimer cancelled.")

print("\r  00:00  TIME'S UP!\a")  # \a makes a beep in many terminals
