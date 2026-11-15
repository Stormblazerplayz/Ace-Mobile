# @title Random Name Picker
# @category Tools
# @kind Console program
# @where Save as picker.py and run: python3 picker.py
# @keywords python random name picker, python pick a winner, python random choice no repeats, python raffle
# @about Picks names at random with a drumroll, without picking the same person twice.

import random
import time

names = [n.strip() for n in input("Type names separated by commas: ").split(",") if n.strip()]
if len(names) < 2:
    names = ["Storm", "Doodle", "Nova", "Ace", "Blaze"]
    print("Using example names:", ", ".join(names))

random.shuffle(names)  # shuffle once, then hand them out in order: no repeats!
while names:
    input(f"\n{len(names)} left. Press Enter to pick...")
    for _ in range(12):  # flash random names for a drumroll effect
        print("\r  " + random.choice(names).ljust(20), end="", flush=True)
        time.sleep(0.08)
    print("\r  >>> " + names.pop() + " <<<".ljust(20))
print("\nEveryone has been picked!")
