# @title Word Scramble
# @category Games
# @kind Console program
# @where Save as scramble.py and run: python3 scramble.py
# @keywords python word scramble, python unscramble letters, python anagram game, python jumble
# @about Unscramble mixed-up words to score points, with a hint if you get stuck.

import random

WORDS = ["planet", "guitar", "dragon", "pencil", "castle", "rocket", "monkey", "laptop", "banana", "winter"]


def scramble(word):
    letters = list(word)
    while True:
        random.shuffle(letters)
        mixed = "".join(letters)
        if mixed != word:  # make sure it actually got mixed up
            return mixed


score = 0
random.shuffle(WORDS)
print("Unscramble the words! Type 'hint' for the first letter (costs 1 point).")

for word in WORDS[:5]:
    print(f"\nScrambled: {scramble(word).upper()}")
    points = 3
    for tries in range(3):
        guess = input("Your answer: ").strip().lower()
        if guess == "hint":
            points = max(1, points - 1)
            print("It starts with", word[0].upper())
            continue
        if guess == word:
            print(f"Yes! +{points} points")
            score += points
            break
        points = max(1, points - 1)
        print("Nope, try again.")
    else:
        print("The word was", word.upper())

print(f"\nFinal score: {score}")
