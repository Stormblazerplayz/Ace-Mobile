# @title Estimate Pi with Random Darts
# @category Math and school
# @kind Console program
# @where Save as pi_darts.py and run: python3 pi_darts.py
# @keywords python estimate pi, python monte carlo, python random simulation, python darts circle
# @about Throws random darts at a square with a circle inside and uses the hits to estimate pi.

import math
import random

# A quarter circle of radius 1 fits in a 1 by 1 square.
# Area of the quarter circle = pi / 4, area of the square = 1.
# So (darts inside the circle) / (all darts) is about pi / 4.
inside = 0
throws = 0
for target in [100, 1000, 10000, 100000, 1000000]:
    while throws < target:
        x, y = random.random(), random.random()
        if x * x + y * y <= 1:
            inside += 1
        throws += 1
    estimate = 4 * inside / throws
    error = abs(estimate - math.pi)
    print(f"{throws:>9,} darts: pi is about {estimate:.5f}  (off by {error:.5f})")

print(f"\nReal pi: {math.pi:.5f}")
print("More darts = a better guess. That's the idea behind Monte Carlo simulations!")

# Another way: a famous series 4 x (1 - 1/3 + 1/5 - 1/7 + ...)
series = 4 * sum((-1) ** k / (2 * k + 1) for k in range(1000000))
print(f"Leibniz series with a million terms: {series:.6f}")
