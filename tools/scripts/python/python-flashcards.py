# @title Flashcards
# @category Math and school
# @kind Console program
# @where Save as flashcards.py and run: python3 flashcards.py. Edit the CARDS dictionary to study your own subject.
# @keywords python flashcards, python study cards, python spaced repetition, python vocab practice
# @about Quizzes you on flashcards and keeps showing the ones you miss until you know them all.

import random

# Change these to whatever you're studying!
CARDS = {
    "H2O": "water",
    "Largest planet": "jupiter",
    "Capital of Japan": "tokyo",
    "Speed of light (km/s, rounded)": "300000",
    "Author of Harry Potter": "j.k. rowling",
    "Plant food-making process": "photosynthesis",
}

to_study = list(CARDS)
random.shuffle(to_study)
rounds = 0
missed_ever = set()

while to_study:
    rounds += 1
    print(f"\n=== Round {rounds}: {len(to_study)} cards ===")
    missed = []
    for front in to_study:
        answer = input(f"{front}? ").strip().lower()
        if answer == CARDS[front]:
            print("  Correct!")
        else:
            print(f"  The answer is: {CARDS[front]}")
            missed.append(front)
            missed_ever.add(front)
    to_study = missed  # only study the ones you missed
    random.shuffle(to_study)

print(f"\nYou learned all {len(CARDS)} cards in {rounds} rounds!")
if missed_ever:
    print("Review these again tomorrow:", ", ".join(sorted(missed_ever)))
