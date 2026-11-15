# @title World Capitals Quiz
# @category Math and school
# @kind Console program
# @where Save as capitals.py and run: python3 capitals.py
# @keywords python capitals quiz, python geography quiz, python countries and capitals, python study geography
# @about A geography quiz on world capitals that forgives small spelling mistakes.

import difflib
import random

CAPITALS = {
    "France": "Paris", "Japan": "Tokyo", "Canada": "Ottawa", "Australia": "Canberra", "Brazil": "Brasilia",
    "Egypt": "Cairo", "India": "New Delhi", "Italy": "Rome", "Mexico": "Mexico City", "Spain": "Madrid",
    "Germany": "Berlin", "Kenya": "Nairobi", "South Korea": "Seoul", "Argentina": "Buenos Aires",
    "United Kingdom": "London", "Norway": "Oslo", "Thailand": "Bangkok", "Peru": "Lima",
}

countries = random.sample(list(CAPITALS), 10)
score = 0
for country in countries:
    guess = input(f"Capital of {country}? ").strip()
    right = CAPITALS[country]
    # difflib gives a similarity from 0 to 1, so "Canbera" still counts
    closeness = difflib.SequenceMatcher(None, guess.lower(), right.lower()).ratio()
    if closeness == 1:
        print("  Correct!")
        score += 1
    elif closeness > 0.8:
        print(f"  Close enough! It's spelled {right}.")
        score += 1
    else:
        print(f"  No, it's {right}.")
print(f"\nYou got {score}/10.")
