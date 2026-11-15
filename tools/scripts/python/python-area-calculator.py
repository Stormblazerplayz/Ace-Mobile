# @title Area and Perimeter Calculator
# @category Math and school
# @kind Console program
# @where Save as area.py and run: python3 area.py
# @keywords python area calculator, python perimeter, python shapes math, python circle triangle rectangle
# @about Calculates the area and perimeter of rectangles, triangles, circles and trapezoids, showing the formula.

import math


def num(prompt):
    while True:
        try:
            value = float(input(prompt))
            if value > 0:
                return value
        except ValueError:
            pass
        print("  Please type a number bigger than 0.")


SHAPES = ["rectangle", "triangle", "circle", "trapezoid"]
for i, shape in enumerate(SHAPES, start=1):
    print(f"{i}. {shape}")
choice = input("Pick a shape: ").strip()

if choice == "1":
    w, h = num("width: "), num("height: ")
    print(f"Area = width x height = {w * h:g}")
    print(f"Perimeter = 2 x (width + height) = {2 * (w + h):g}")
elif choice == "2":
    a, b, c = num("side a: "), num("side b: "), num("side c: ")
    if a + b <= c or a + c <= b or b + c <= a:
        print("Those sides can't make a triangle!")
    else:
        s = (a + b + c) / 2  # Heron's formula uses half the perimeter
        print(f"Area (Heron's formula) = {math.sqrt(s * (s - a) * (s - b) * (s - c)):.4g}")
        print(f"Perimeter = a + b + c = {a + b + c:g}")
elif choice == "3":
    r = num("radius: ")
    print(f"Area = pi x r^2 = {math.pi * r * r:.4g}")
    print(f"Circumference = 2 x pi x r = {2 * math.pi * r:.4g}")
elif choice == "4":
    a, b, h = num("top side: "), num("bottom side: "), num("height: ")
    print(f"Area = (top + bottom) / 2 x height = {(a + b) / 2 * h:g}")
else:
    print("Pick 1 to 4 next time.")
