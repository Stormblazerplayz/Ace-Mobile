# @title Number Guessing Game
# @category Games
# @kind Console program
# @where Save as guess.py and run: python3 guess.py
# @keywords python number guessing game, python guess the number, python higher or lower hints, python random game
# @about The computer picks a secret number and tells you higher or lower until you find it.

import random

print("I'm thinking of a number from 1 to 100.")
secret = random.randint(1, 100)
tries = 0
best_possible = 7  # binary search can always win in 7 tries

while True:
    text = input("Your guess: ").strip()
    if not text.isdigit():
        print("Type a whole number.")
        continue
    guess = int(text)
    tries += 1
    if guess < secret:
        print("Higher!" + (" (Getting warm)" if secret - guess <= 5 else ""))
    elif guess > secret:
        print("Lower!" + (" (Getting warm)" if guess - secret <= 5 else ""))
    else:
        print(f"You got it in {tries} tries!")
        if tries <= best_possible:
            print("That's expert level guessing.")
        break
