# @title Save Python Objects with Pickle
# @category Files and data
# @kind Console program
# @where Save as pickle_demo.py and run: python3 pickle_demo.py twice to see your objects come back.
# @keywords python pickle, python save objects, python serialize class, python load object from file
# @about Saves whole Python objects (even your own classes) to a file with pickle and loads them back.

import pickle
from pathlib import Path

PATH = Path(__file__).with_name("world.pickle")


class Creature:
    def __init__(self, name, hp, position):
        self.name = name
        self.hp = hp
        self.position = position

    def __repr__(self):
        return f"Creature({self.name!r}, hp={self.hp}, at={self.position})"


if PATH.exists():
    with open(PATH, "rb") as f:   # "rb" = read bytes
        world = pickle.load(f)
    print("Loaded the saved world!")
    world["day"] += 1
    for creature in world["creatures"]:
        creature.hp -= 5  # a hard day
else:
    world = {"day": 1, "creatures": [Creature("Slime", 30, (2, 5)), Creature("Wolf", 50, (8, 1))]}
    print("Made a brand new world.")

print("Day", world["day"])
for creature in world["creatures"]:
    print("  ", creature)

with open(PATH, "wb") as f:       # "wb" = write bytes
    pickle.dump(world, f)
print("Saved. Run me again!")
print("Safety tip: only load pickle files YOU made. A pickle from a stranger can run bad code.")
