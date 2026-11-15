# @title Dice Yahtzee Lite
# @category Games
# @kind Console program
# @where Save as yahtzee.py and run: python3 yahtzee.py
# @keywords python yahtzee, python dice game, python reroll dice, python keep dice
# @about Roll five dice, keep the ones you like, reroll twice, and score points for pairs, straights and Yahtzees.

import random
from collections import Counter


def score(dice):
    counts = sorted(Counter(dice).values(), reverse=True)
    unique = sorted(set(dice))
    if counts[0] == 5:
        return 50, "YAHTZEE!"
    if unique in ([1, 2, 3, 4, 5], [2, 3, 4, 5, 6]):
        return 40, "Large straight"
    if counts[0] == 4:
        return 30, "Four of a kind"
    if counts[:2] == [3, 2]:
        return 25, "Full house"
    if counts[0] == 3:
        return sum(dice), "Three of a kind"
    return sum(dice) // 2, "Nothing special (half points)"


total = 0
for round_number in range(1, 6):
    dice = [random.randint(1, 6) for _ in range(5)]
    print(f"\n=== Round {round_number} ===")
    for roll in range(2):
        print("Dice:", "  ".join(f"[{d}]" for d in dice), "   positions 1 2 3 4 5")
        keep = input("Type the positions to KEEP (like 135), or Enter to reroll all: ").strip()
        for i in range(5):
            if str(i + 1) not in keep:
                dice[i] = random.randint(1, 6)
    points, name = score(dice)
    print("Final dice:", "  ".join(f"[{d}]" for d in dice))
    print(f"{name}: +{points} points")
    total += points

print(f"\nTotal score after 5 rounds: {total}")
