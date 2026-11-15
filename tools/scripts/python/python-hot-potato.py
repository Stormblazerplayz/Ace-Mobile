# @title Hot Potato Countdown
# @category Games
# @kind Console program
# @where Save as hot_potato.py and run: python3 hot_potato.py with friends around the computer.
# @keywords python hot potato, python party game, python secret timer, python pass the device
# @about A party game: pass the computer around and answer a category before the secret timer explodes.

import random
import time

CATEGORIES = ["an animal", "a food", "a video game", "a country", "a color", "a sport",
              "something in a kitchen", "a superhero", "a word that rhymes with cat"]

players = input("Type the players' names separated by commas: ").split(",")
players = [p.strip() for p in players if p.strip()] or ["Player 1", "Player 2"]
category = random.choice(CATEGORIES)
fuse = random.uniform(15, 40)  # secret! nobody knows how long
start = time.perf_counter()
used = set()
turn = 0

print(f"\nThe category is: {category.upper()}")
print("Type an answer and press Enter to pass the potato. No repeats!")
while True:
    player = players[turn % len(players)]
    answer = input(f"{player}: ").strip().lower()
    if time.perf_counter() - start > fuse:
        print(f"\nBOOM! The potato exploded on {player}!")
        break
    if not answer or answer in used:
        print("That doesn't count! Try again, quick!")
        continue
    used.add(answer)
    turn += 1

print(f"The fuse was {fuse:.0f} seconds. Answers given: {len(used)}")
