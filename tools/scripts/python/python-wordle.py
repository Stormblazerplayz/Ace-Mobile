# @title Wordle Clone
# @category Games
# @kind Console program
# @where Save as wordle.py and run: python3 wordle.py
# @keywords python wordle, python five letter word game, python green yellow letters, python wordle clone
# @about Guess the secret five letter word in six tries with green, yellow and gray letter hints.

import random

WORDS = ["apple", "brave", "crane", "dance", "eagle", "flame", "grape", "house", "jelly", "knife",
         "lemon", "magic", "night", "ocean", "piano", "queen", "robot", "storm", "tiger", "vivid"]


def score(guess, secret):
    """G = right letter right spot, Y = in the word but wrong spot, - = not in the word."""
    result = ["-"] * 5
    leftover = []
    for i in range(5):
        if guess[i] == secret[i]:
            result[i] = "G"
        else:
            leftover.append(secret[i])
    # Second pass for yellows, so a letter is only counted as many times as it appears
    for i in range(5):
        if result[i] != "G" and guess[i] in leftover:
            result[i] = "Y"
            leftover.remove(guess[i])
    return "".join(result)


secret = random.choice(WORDS)
print("Guess the 5 letter word! G = right spot, Y = wrong spot, - = not in word.")
for attempt in range(1, 7):
    guess = input(f"Guess {attempt}/6: ").strip().lower()
    while len(guess) != 5 or not guess.isalpha():
        guess = input("Please type exactly 5 letters: ").strip().lower()
    hint = score(guess, secret)
    print("        " + " ".join(guess.upper()))
    print("        " + " ".join(hint))
    if hint == "GGGGG":
        print(f"You got it in {attempt}!")
        break
else:
    print(f"Out of tries. The word was {secret.upper()}.")
