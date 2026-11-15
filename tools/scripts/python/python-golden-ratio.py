# @title Fibonacci and the Golden Ratio
# @category Math and school
# @kind Console program
# @where Save as golden.py and run: python3 golden.py
# @keywords python golden ratio, python fibonacci ratio, python phi, python nature math
# @about Shows how dividing Fibonacci numbers by the one before them gets closer and closer to the golden ratio.

import math

phi = (1 + math.sqrt(5)) / 2  # the golden ratio, about 1.618
a, b = 1, 1
print(f"{'n':>3} {'Fibonacci':>12} {'ratio':>14} {'off by':>12}")
for n in range(2, 26):
    a, b = b, a + b
    ratio = b / a
    print(f"{n:>3} {b:>12,} {ratio:>14.10f} {abs(ratio - phi):>12.2e}")

print(f"\nThe golden ratio phi = {phi:.10f}")
print(f"Cool trick: phi squared = {phi * phi:.6f} and phi + 1 = {phi + 1:.6f} (the same!)")
print(f"And 1 / phi = {1 / phi:.6f}, which is phi - 1.")
print("You can find these numbers in sunflower seeds, pinecones and seashell spirals.")
