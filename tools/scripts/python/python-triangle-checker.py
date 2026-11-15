# @title Triangle Type Checker
# @category Math and school
# @kind Console program
# @where Save as triangles.py and run: python3 triangles.py
# @keywords python triangle type, python equilateral isosceles scalene, python triangle angles, python law of cosines
# @about Tells you if three sides make a triangle, what kind it is, and works out all three angles.

import math

text = input("Type three side lengths (like 3 4 5): ").split()
try:
    a, b, c = sorted(float(t) for t in text)
except ValueError:
    raise SystemExit("Please type exactly three numbers.")

if a <= 0 or a + b <= c:
    raise SystemExit("Those can't make a triangle: the two short sides must add up to more than the long side.")

if a == b == c:
    by_sides = "equilateral (all sides equal)"
elif a == b or b == c:
    by_sides = "isosceles (two sides equal)"
else:
    by_sides = "scalene (no sides equal)"

# Compare a^2 + b^2 with c^2 to find the biggest angle's type
if math.isclose(a * a + b * b, c * c):
    by_angle = "right (has a 90 degree angle)"
elif a * a + b * b > c * c:
    by_angle = "acute (all angles under 90)"
else:
    by_angle = "obtuse (one angle over 90)"


def angle(opposite, x, y):
    """Law of cosines: find the angle across from 'opposite'."""
    cosine = (x * x + y * y - opposite * opposite) / (2 * x * y)
    return math.degrees(math.acos(max(-1.0, min(1.0, cosine))))  # clamp tiny rounding errors


angles = [angle(a, b, c), angle(b, a, c), angle(c, a, b)]
print(f"By its sides it is {by_sides}.")
print(f"By its angles it is {by_angle}.")
print("Angles:", ", ".join(f"{x:.1f} degrees" for x in angles), f"(they add up to {sum(angles):.0f})")
