# @title Coordinate Geometry Helper
# @category Math and school
# @kind Console program
# @where Save as coords.py and run: python3 coords.py
# @keywords python coordinate geometry, python slope, python midpoint, python distance formula, python line equation
# @about Takes two points and finds the distance, midpoint, slope and equation of the line through them.

import math


def ask_point(name):
    while True:
        parts = input(f"Point {name} as x y: ").replace(",", " ").split()
        try:
            x, y = (float(p) for p in parts)
            return x, y
        except ValueError:
            print("Type two numbers like: 3 -2")


(x1, y1), (x2, y2) = ask_point("A"), ask_point("B")
distance = math.hypot(x2 - x1, y2 - y1)
print(f"\nDistance: sqrt(({x2:g} - {x1:g})^2 + ({y2:g} - {y1:g})^2) = {distance:.4g}")
print(f"Midpoint: ({(x1 + x2) / 2:g}, {(y1 + y2) / 2:g})")

if x1 == x2 and y1 == y2:
    print("That's the same point twice!")
elif x1 == x2:
    print(f"The line is straight up and down: x = {x1:g} (its slope is undefined)")
else:
    slope = (y2 - y1) / (x2 - x1)
    intercept = y1 - slope * x1
    print(f"Slope: rise / run = ({y2:g} - {y1:g}) / ({x2:g} - {x1:g}) = {slope:.4g}")
    sign = "+" if intercept >= 0 else "-"
    print(f"Line equation: y = {slope:.4g}x {sign} {abs(intercept):.4g}")
    print(f"The line crosses the x axis at x = {-intercept / slope + 0.0:.4g}" if slope else "The line is flat.")
