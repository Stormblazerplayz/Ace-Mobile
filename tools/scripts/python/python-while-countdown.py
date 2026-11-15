# @title While Loop Countdown
# @category Basics
# @kind Console program
# @where Save as countdown.py and run: python3 countdown.py
# @keywords python while loop, python countdown, python time sleep, python rocket launch
# @about Counts down from 10 to liftoff using a while loop and a one second pause.

import time

count = 10

# A while loop keeps going as long as its condition is True.
while count > 0:
    print(count, "...")
    time.sleep(1)  # wait one second
    count -= 1     # IMPORTANT: change the variable or the loop never ends!

print("LIFTOFF!")

# Another while loop: keep doubling until we pass 1000.
number = 1
steps = 0
while number < 1000:
    number *= 2
    steps += 1
print("Doubling 1 takes", steps, "steps to pass 1000. It ends at", number)
