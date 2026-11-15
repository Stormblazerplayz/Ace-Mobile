# @title Hangman
# @category Games
# @kind Console program
# @where Save as hangman.py and run: python3 hangman.py
# @keywords python hangman, python word guessing game, python guess the letters, hangman in python
# @about Guess the secret word one letter at a time before the stick figure is finished.

import random

WORDS = ["python", "robot", "planet", "castle", "dragon", "rocket", "pizza", "jungle", "lightning", "printer"]

# Each picture shows one more body part. Index = number of wrong guesses.
PICTURES = [
    "  +---+\n      |\n      |\n      |\n     ===",
    "  +---+\n  O   |\n      |\n      |\n     ===",
    "  +---+\n  O   |\n  |   |\n      |\n     ===",
    "  +---+\n  O   |\n /|   |\n      |\n     ===",
    "  +---+\n  O   |\n /|\\  |\n      |\n     ===",
    "  +---+\n  O   |\n /|\\  |\n /    |\n     ===",
    "  +---+\n  O   |\n /|\\  |\n / \\  |\n     ===",
]


def play():
    secret = random.choice(WORDS)
    guessed = set()
    wrong = 0
    while wrong < len(PICTURES) - 1:
        shown = " ".join(ch if ch in guessed else "_" for ch in secret)
        print("\n" + PICTURES[wrong])
        print("Word:", shown)
        print("Tried:", " ".join(sorted(guessed)) or "nothing yet")
        if "_" not in shown:
            print(f"You got it! The word was {secret}.")
            return
        letter = input("Guess a letter: ").strip().lower()
        if len(letter) != 1 or not letter.isalpha():
            print("Please type one letter.")
        elif letter in guessed:
            print("You already tried that one.")
        else:
            guessed.add(letter)
            if letter not in secret:
                wrong += 1
                print("Nope!")
    print("\n" + PICTURES[-1])
    print(f"Out of guesses! The word was {secret}.")


while True:
    play()
    if input("\nPlay again? (y/n) ").strip().lower() != "y":
        break
