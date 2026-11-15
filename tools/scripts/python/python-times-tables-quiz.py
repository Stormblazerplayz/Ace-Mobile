# @title Times Tables Quiz
# @category Math and school
# @kind Console program
# @where Save as times_tables.py and run: python3 times_tables.py
# @keywords python times tables, python multiplication quiz, python math practice, python timed quiz
# @about A timed multiplication quiz that tracks your score and shows which facts to practice.

import random
import time

text = input("Which table do you want to practice? (2-12, or Enter for all): ").strip()
tables = [int(text)] if text.isdigit() and 2 <= int(text) <= 12 else list(range(2, 13))

score = 0
mistakes = []
QUESTIONS = 10
start = time.perf_counter()

for number in range(1, QUESTIONS + 1):
    a = random.choice(tables)
    b = random.randint(2, 12)
    answer = input(f"Q{number}: {a} x {b} = ").strip()
    if answer.isdigit() and int(answer) == a * b:
        score += 1
        print("  Yes!")
    else:
        print(f"  Oops, it's {a * b}.")
        mistakes.append(f"{a} x {b} = {a * b}")

seconds = time.perf_counter() - start
print(f"\nScore: {score}/{QUESTIONS} in {seconds:.0f} seconds ({seconds / QUESTIONS:.1f} s per question)")
if mistakes:
    print("Practice these:")
    for fact in mistakes:
        print("  ", fact)
else:
    print("Perfect score!")
