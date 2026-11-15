# @title Enums: Traffic Light
# @category Basics
# @kind Console program
# @where Save as enums.py and run: python3 enums.py
# @keywords python enum, python enumeration, python named constants, python state machine
# @about Uses an Enum to name the traffic light colors and step through them like a state machine.

import time
from enum import Enum


class Light(Enum):
    GREEN = "go"
    YELLOW = "slow down"
    RED = "stop"


# Which light comes next, and how long each one lasts (seconds)
NEXT = {Light.GREEN: Light.YELLOW, Light.YELLOW: Light.RED, Light.RED: Light.GREEN}
TIME = {Light.GREEN: 1.5, Light.YELLOW: 0.5, Light.RED: 1.5}

light = Light.RED
for _ in range(6):
    print(f"{light.name:<6} means {light.value}")
    time.sleep(TIME[light])
    light = NEXT[light]

# Enums can be listed and compared safely
print("All lights:", [l.name for l in Light])
print("Is it red?", light == Light.RED)
print("Look up by value:", Light("stop"))
