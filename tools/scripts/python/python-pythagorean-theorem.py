# @title Pythagorean Theorem Helper
# @category Math and school
# @kind Console program
# @where Save as pythagoras.py and run: python3 pythagoras.py
# @keywords python pythagorean theorem, python right triangle, python hypotenuse, python missing side
# @about Finds the missing side of a right triangle and lists some whole number Pythagorean triples.

import math

print("Right triangle: a and b are the legs, c is the long side (hypotenuse).")
print("Type the two sides you know and leave the missing one blank.")


def ask(name):
    text = input(f"{name}: ").strip()
    return float(text) if text else None


a, b, c = ask("a"), ask("b"), ask("c")
try:
    if c is None and a and b:
        print(f"c = sqrt({a:g}^2 + {b:g}^2) = {math.sqrt(a * a + b * b):.4g}")
    elif b is None and a and c:
        print(f"b = sqrt({c:g}^2 - {a:g}^2) = {math.sqrt(c * c - a * a):.4g}")
    elif a is None and b and c:
        print(f"a = sqrt({c:g}^2 - {b:g}^2) = {math.sqrt(c * c - b * b):.4g}")
    else:
        print("Leave exactly one side blank.")
except ValueError:
    print("The hypotenuse must be the longest side!")

# Bonus: triangles where every side is a whole number
triples = [(x, y, int(math.hypot(x, y))) for x in range(1, 30) for y in range(x, 30)
           if math.hypot(x, y).is_integer()]
print("\nWhole number triangles:", triples[:8])
