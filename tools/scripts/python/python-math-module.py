# @title The Math Module
# @category Basics
# @kind Console program
# @where Save as math_fun.py and run: python3 math_fun.py
# @keywords python math module, python square root, python pi, python round up down, python trig
# @about Shows the handy tools in Python's math module: square roots, pi, rounding and more.

import math

print("Square root of 144:", math.sqrt(144))
print("Pi:", math.pi)
print("2 to the 8th power:", math.pow(2, 8))
print("Round 4.2 UP:", math.ceil(4.2))
print("Round 4.8 DOWN:", math.floor(4.8))
print("Normal round of 4.5:", round(4.5), "(Python rounds .5 to the nearest even number)")
print("Absolute value of -7:", abs(-7))
print("Greatest common divisor of 24 and 36:", math.gcd(24, 36))
print("5 factorial:", math.factorial(5))
print("Hypotenuse of a 3-4 triangle:", math.hypot(3, 4))

# Area and circumference of a circle
radius = 5
print(f"Circle with radius {radius}: area {math.pi * radius ** 2:.2f}, around {2 * math.pi * radius:.2f}")

# Trig works in radians, so convert degrees first
angle = 30
print(f"sin({angle} degrees) = {math.sin(math.radians(angle)):.2f}")
print("Is 0.1 + 0.2 close to 0.3?", math.isclose(0.1 + 0.2, 0.3))
