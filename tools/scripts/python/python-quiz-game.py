# @title Quiz Game
# @category Games
# @kind Console program
# @where Save as quiz.py and run: python3 quiz.py
# @keywords python quiz game, python multiple choice quiz, python trivia questions, python score quiz
# @about A multiple choice trivia quiz that shuffles the questions and gives you a score at the end.

import random

QUESTIONS = [
    {"q": "What planet is known as the Red Planet?", "choices": ["Venus", "Mars", "Jupiter", "Saturn"], "answer": "Mars"},
    {"q": "How many legs does a spider have?", "choices": ["6", "8", "10", "12"], "answer": "8"},
    {"q": "What language are these quiz questions written in?", "choices": ["Lua", "Swift", "Python", "C++"], "answer": "Python"},
    {"q": "What is 9 x 7?", "choices": ["56", "63", "72", "49"], "answer": "63"},
    {"q": "Which gas do plants breathe in?", "choices": ["Oxygen", "Helium", "Carbon dioxide", "Nitrogen"], "answer": "Carbon dioxide"},
    {"q": "What is the biggest ocean?", "choices": ["Atlantic", "Indian", "Arctic", "Pacific"], "answer": "Pacific"},
    {"q": "How many sides does a hexagon have?", "choices": ["5", "6", "7", "8"], "answer": "6"},
]

random.shuffle(QUESTIONS)
score = 0

for number, item in enumerate(QUESTIONS, start=1):
    print(f"\nQuestion {number}: {item['q']}")
    choices = item["choices"][:]
    random.shuffle(choices)
    letters = "abcd"
    for letter, choice in zip(letters, choices):
        print(f"  {letter}) {choice}")
    pick = input("Your answer (a, b, c or d): ").strip().lower()
    if pick in letters and choices[letters.index(pick)] == item["answer"]:
        print("Correct!")
        score += 1
    else:
        print(f"Not quite. The answer was {item['answer']}.")

percent = score / len(QUESTIONS) * 100
print(f"\nYou got {score} out of {len(QUESTIONS)} ({percent:.0f}%).")
print("Quiz master!" if percent >= 80 else "Nice try, play again to beat your score!")
