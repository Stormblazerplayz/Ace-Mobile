# @title Turtle Graphing Calculator
# @category Drawing
# @kind Turtle program
# @where Save as grapher.py and run: python3 grapher.py. Edit the FUNCTIONS list to graph your own math.
# @keywords python graph function, turtle plot equation, turtle graphing calculator, turtle axes grid
# @about Draws a grid with x and y axes and plots math functions like a parabola, a sine wave and a line.

import math
import turtle

SCALE = 30  # pixels per unit
FUNCTIONS = [
    ("y = x^2 / 4 - 3", lambda x: x * x / 4 - 3, "red"),
    ("y = 3 sin(x)", lambda x: 3 * math.sin(x), "blue"),
    ("y = 0.5x + 1", lambda x: 0.5 * x + 1, "green"),
]

screen = turtle.Screen()
screen.setup(700, 700)
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()

# Grid lines
t.color("light gray")
for i in range(-10, 11):
    for start, end in (((i, -10), (i, 10)), ((-10, i), (10, i))):
        t.penup()
        t.goto(start[0] * SCALE, start[1] * SCALE)
        t.pendown()
        t.goto(end[0] * SCALE, end[1] * SCALE)

# Axes
t.color("black")
t.width(2)
for start, end in (((-10, 0), (10, 0)), ((0, -10), (0, 10))):
    t.penup()
    t.goto(start[0] * SCALE, start[1] * SCALE)
    t.pendown()
    t.goto(end[0] * SCALE, end[1] * SCALE)

# Plot each function by connecting lots of tiny steps
for row, (label, func, color) in enumerate(FUNCTIONS):
    t.color(color)
    t.penup()
    x = -10.0
    while x <= 10:
        y = func(x)
        if abs(y) <= 10:
            t.goto(x * SCALE, y * SCALE)
            t.pendown()
        else:
            t.penup()  # off the graph, so don't draw
        x += 0.05
    t.penup()
    t.goto(-320, 320 - row * 22)
    t.write(label, font=("Arial", 13, "bold"))

screen.update()
turtle.done()
