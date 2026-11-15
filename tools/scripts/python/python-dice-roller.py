# @title Dice Roller (D&D Style)
# @category Tools
# @kind Console program
# @where Save as dice.py and run: python3 dice.py, then type rolls like 2d6, 1d20+5 or 4d8-1.
# @keywords python dice roller, python d20, python dnd dice, python roll notation, python regex dice
# @about Rolls any dice you type in tabletop style, like 3d6 or 1d20+4, and shows each die.

import random
import re

PATTERN = re.compile(r"(\d*)d(\d+)([+-]\d+)?")
print("Type a roll like 2d6, d20, 1d20+5 or 4d8-1. Press Enter on an empty line to quit.")

while True:
    text = input("\nRoll: ").strip().lower().replace(" ", "")
    if not text:
        break
    match = PATTERN.fullmatch(text)
    if not match:
        print("Try something like 3d6 or 1d20+2.")
        continue
    count = int(match.group(1) or 1)
    sides = int(match.group(2))
    bonus = int(match.group(3) or 0)
    if not (1 <= count <= 100 and 2 <= sides <= 1000):
        print("Use 1 to 100 dice with 2 to 1000 sides.")
        continue
    rolls = [random.randint(1, sides) for _ in range(count)]
    total = sum(rolls) + bonus
    bonus_text = f" {'+' if bonus >= 0 else '-'} {abs(bonus)}" if bonus else ""
    print(f"Dice: {rolls}{bonus_text}  =  {total}")
    if sides == 20 and count == 1:
        if rolls[0] == 20:
            print("NATURAL 20! Critical hit!")
        elif rolls[0] == 1:
            print("Natural 1... oh no.")
