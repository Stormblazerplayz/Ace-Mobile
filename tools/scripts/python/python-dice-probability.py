# @title Dice Probability Experiment
# @category Math and school
# @kind Console program
# @where Save as dice_odds.py and run: python3 dice_odds.py
# @keywords python probability, python dice simulation, python experimental vs theoretical, python histogram
# @about Rolls two dice thousands of times and compares the results with the math-predicted chances.

import random
from collections import Counter
from itertools import product

ROLLS = 36000
results = Counter(random.randint(1, 6) + random.randint(1, 6) for _ in range(ROLLS))

# Theory: list every possible pair of dice (36 of them) and count each total
theory = Counter(a + b for a, b in product(range(1, 7), repeat=2))

print(f"Rolled two dice {ROLLS:,} times.\n")
print("Total  Expected  Got     Bar")
for total in range(2, 13):
    expected = theory[total] / 36 * ROLLS
    bar = "#" * round(results[total] / ROLLS * 150)
    print(f"{total:>5}  {expected:>8.0f}  {results[total]:>6}  {bar}")

print("\n7 is the most common total because 6 different pairs make it:")
print("  ", [pair for pair in product(range(1, 7), repeat=2) if sum(pair) == 7])
doubles = sum(1 for _ in range(10000) if random.randint(1, 6) == random.randint(1, 6))
print(f"Chance of doubles: about {doubles / 100:.1f}% (the math says 1 in 6 = 16.7%)")
