# @title Square Roots by Guessing (Newton's Method)
# @category Math and school
# @kind Console program
# @where Save as newton.py and run: python3 newton.py
# @keywords python newton method, python square root by hand, python approximation, python babylonian method
# @about Finds square roots by making a guess and improving it, the same way calculators do it.

import math


def newton_sqrt(n, show=True):
    guess = n / 2 if n > 1 else 1.0
    for step in range(1, 30):
        better = (guess + n / guess) / 2  # average the guess and n divided by the guess
        if show:
            print(f"  step {step}: {better:.10f}")
        if abs(better - guess) < 1e-12:  # stop when the guess stops changing
            return better
        guess = better
    return guess


text = input("Find the square root of (Enter for 2): ").strip()
try:
    n = float(text) if text else 2.0
except ValueError:
    n = 2.0
if n < 0:
    raise SystemExit("Negative numbers don't have real square roots.")
if n == 0:
    raise SystemExit("The square root of 0 is 0.")

answer = newton_sqrt(n)
print(f"\nNewton's method: {answer:.10f}")
print(f"math.sqrt says:  {math.sqrt(n):.10f}")
print(f"Check: {answer:.6f} x {answer:.6f} = {answer * answer:.6f}")
