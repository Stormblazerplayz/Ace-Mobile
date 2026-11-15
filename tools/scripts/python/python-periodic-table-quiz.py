# @title Element Symbols Quiz
# @category Math and school
# @kind Console program
# @where Save as elements.py and run: python3 elements.py
# @keywords python periodic table, python chemistry quiz, python element symbols, python science quiz
# @about Quizzes you on chemical element symbols both ways: name to symbol and symbol to name.

import random

ELEMENTS = {
    "H": "Hydrogen", "He": "Helium", "Li": "Lithium", "C": "Carbon", "N": "Nitrogen", "O": "Oxygen",
    "Na": "Sodium", "Mg": "Magnesium", "Al": "Aluminum", "Si": "Silicon", "Cl": "Chlorine", "K": "Potassium",
    "Ca": "Calcium", "Fe": "Iron", "Cu": "Copper", "Zn": "Zinc", "Ag": "Silver", "Au": "Gold",
    "Hg": "Mercury", "Pb": "Lead", "Sn": "Tin", "Ne": "Neon", "U": "Uranium", "Ti": "Titanium",
}

score = 0
QUESTIONS = 12
for number in range(1, QUESTIONS + 1):
    symbol, name = random.choice(list(ELEMENTS.items()))
    if random.random() < 0.5:
        answer = input(f"{number}. What is the symbol for {name}? ").strip()
        correct = answer == symbol  # capitals matter in symbols: Co is not CO!
        right = symbol
    else:
        answer = input(f"{number}. What element is {symbol}? ").strip()
        correct = answer.lower() == name.lower()
        right = name
    if correct:
        score += 1
        print("  Correct!")
    else:
        print(f"  It's {right}.")

print(f"\nScore: {score}/{QUESTIONS}")
print("Tip: Au (gold) comes from the Latin word aurum, and Fe (iron) from ferrum!")
