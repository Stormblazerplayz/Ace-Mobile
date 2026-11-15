# @title Quadratic Equation Solver
# @category Math and school
# @kind Console program
# @where Save as quadratic.py and run: python3 quadratic.py
# @keywords python quadratic formula, python solve ax2 bx c, python discriminant, python complex roots
# @about Solves equations like ax squared + bx + c = 0 with the quadratic formula, showing each step.

import cmath
import math


def ask(name):
    while True:
        try:
            return float(input(f"{name} = "))
        except ValueError:
            print("Type a number.")


print("Solve ax^2 + bx + c = 0")
a, b, c = ask("a"), ask("b"), ask("c")
if a == 0:
    if b == 0:
        print("That's not an equation with x in it.")
    else:
        print(f"That's a straight line. x = {-c / b:g}")
else:
    d = b * b - 4 * a * c  # the discriminant tells us how many answers there are
    print(f"Discriminant: b^2 - 4ac = {d:g}")
    if d > 0:
        r1 = (-b + math.sqrt(d)) / (2 * a)
        r2 = (-b - math.sqrt(d)) / (2 * a)
        print(f"Two answers: x = {r1:g} or x = {r2:g}")
    elif d == 0:
        print(f"One answer: x = {-b / (2 * a) + 0.0:g}")
    else:
        r1 = (-b + cmath.sqrt(d)) / (2 * a)
        r2 = (-b - cmath.sqrt(d)) / (2 * a)
        print(f"No real answers. Complex answers: {r1:.3g} and {r2:.3g}")
    vertex_x = -b / (2 * a) + 0.0  # adding 0.0 turns -0.0 into 0.0
    print(f"The curve turns at x = {vertex_x:g}, y = {a * vertex_x ** 2 + b * vertex_x + c:g}")
