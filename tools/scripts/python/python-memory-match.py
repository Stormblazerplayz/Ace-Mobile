# @title Memory Match Cards
# @category Games
# @kind Console program
# @where Save as memory.py and run: python3 memory.py
# @keywords python memory game, python matching pairs, python concentration game, python flip cards
# @about Flip two hidden cards at a time and try to find all the matching pairs in as few turns as possible.

import os
import random
import time

symbols = list("AABBCCDDEEFFGGHH")
random.shuffle(symbols)
found = [False] * 16


def show(open_cards=()):
    os.system("cls" if os.name == "nt" else "clear")
    for row in range(4):
        cells = []
        for col in range(4):
            i = row * 4 + col
            cells.append(symbols[i] if found[i] or i in open_cards else f"{i + 1:>2}")
        print("  ".join(f"{c:>2}" for c in cells))


def pick(message, taken=()):
    while True:
        text = input(message).strip()
        if text.isdigit() and 1 <= int(text) <= 16 and not found[int(text) - 1] and int(text) - 1 not in taken:
            return int(text) - 1
        print("Pick a hidden card number.")


turns = 0
while not all(found):
    show()
    first = pick("First card: ")
    show([first])
    second = pick("Second card: ", taken=[first])
    show([first, second])
    turns += 1
    if symbols[first] == symbols[second]:
        found[first] = found[second] = True
        print("Match!")
    else:
        print("No match. Remember them!")
    time.sleep(1.5)

show()
print(f"You found all pairs in {turns} turns!")
