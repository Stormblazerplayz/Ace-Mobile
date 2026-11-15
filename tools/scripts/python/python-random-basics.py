# @title Random Numbers
# @category Basics
# @kind Console program
# @where Save as random_fun.py and run: python3 random_fun.py
# @keywords python random, python randint, python random choice, python shuffle list
# @about Shows how to roll dice, pick random items and shuffle lists with the random module.

import random

# A whole number from 1 to 6 (both ends included)
print("Dice roll:", random.randint(1, 6))

# A decimal number between 0 and 1
print("Random decimal:", round(random.random(), 3))

# Pick one item from a list
snacks = ["chips", "cookies", "grapes", "pretzels"]
print("Snack of the day:", random.choice(snacks))

# Pick several different items
print("Two different snacks:", random.sample(snacks, 2))

# Shuffle a list in place, like a deck of cards
cards = ["A", "2", "3", "4", "5", "J", "Q", "K"]
random.shuffle(cards)
print("Shuffled cards:", cards)

# Roll two dice 1000 times and count how often we get 7
sevens = 0
for _ in range(1000):
    if random.randint(1, 6) + random.randint(1, 6) == 7:
        sevens += 1
print(f"Rolled a 7 about {sevens} times out of 1000 (around 167 is normal)")

# A seed makes "random" numbers repeat the same way every time
random.seed(42)
print("Seeded rolls:", [random.randint(1, 6) for _ in range(5)])
