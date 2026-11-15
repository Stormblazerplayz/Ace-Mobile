# @title Math Quiz with Levels
# @category Math and school
# @kind Console program
# @where Save as math_quiz.py and run: python3 math_quiz.py
# @keywords python math quiz, python arithmetic practice, python difficulty levels, python adaptive quiz
# @about A mixed math quiz that gets harder as you get answers right and easier when you miss.

import operator
import random

OPS = [("+", operator.add), ("-", operator.sub), ("x", operator.mul)]
level = 1
best_level = 1
score = 0

for number in range(1, 16):
    top = 5 * level  # bigger numbers at higher levels
    symbol, func = random.choice(OPS[:1 + min(level, 2)])  # level 1 is only +, then - and x unlock
    a, b = random.randint(1, top), random.randint(1, top)
    if symbol == "-" and b > a:
        a, b = b, a  # no negative answers
    answer = func(a, b)
    reply = input(f"[Level {level}] Q{number}: {a} {symbol} {b} = ").strip()
    if reply.lstrip("-").isdigit() and int(reply) == answer:
        score += level
        print("  Correct!")
        level = min(10, level + 1)
        best_level = max(best_level, level)
    else:
        print(f"  It was {answer}.")
        level = max(1, level - 1)

print(f"\nFinal score: {score} points. Highest level reached: {best_level} out of 10.")
