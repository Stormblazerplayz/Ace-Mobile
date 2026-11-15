# @title Hot and Cold Treasure Hunt
# @category Games
# @kind Console program
# @where Save as treasure.py and run: python3 treasure.py
# @keywords python treasure hunt, python hot or cold, python distance hint, python grid search game
# @about Dig for buried treasure on a grid, using hotter and colder hints to find it.

import math
import random

SIZE = 10
treasure = (random.randrange(SIZE), random.randrange(SIZE))
dug = set()
last_distance = None

print(f"Treasure is buried on a {SIZE}x{SIZE} island. Type 'x y' to dig (0 to {SIZE - 1}).")
for turn in range(1, 16):
    parts = input(f"Dig {turn}/15: ").split()
    if len(parts) != 2 or not all(p.isdigit() and int(p) < SIZE for p in parts):
        print("Type two numbers like: 3 7")
        continue
    spot = (int(parts[0]), int(parts[1]))
    if spot == treasure:
        print(f"You found the TREASURE in {turn} digs!")
        break
    dug.add(spot)
    distance = math.dist(spot, treasure)
    if distance < 2:
        word = "BURNING HOT!"
    elif distance < 4:
        word = "Hot"
    elif distance < 6:
        word = "Warm"
    else:
        word = "Cold"
    trend = ""
    if last_distance is not None:
        trend = " (getting warmer)" if distance < last_distance else " (getting colder)"
    print(word + trend)
    last_distance = distance
else:
    print(f"Out of digs! The treasure was at {treasure[0]} {treasure[1]}.")

# Show a map of where you dug
for y in range(SIZE):
    print(" ".join("T" if (x, y) == treasure else "x" if (x, y) in dug else "." for x in range(SIZE)))
