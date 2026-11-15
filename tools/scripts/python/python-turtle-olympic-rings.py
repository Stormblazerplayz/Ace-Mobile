# @title Turtle Olympic Rings
# @category Drawing
# @kind Turtle program
# @where Save as rings.py and run: python3 rings.py
# @keywords python turtle olympic rings, turtle circles loop, turtle list of tuples, turtle pensize
# @about Draws the five Olympic rings using a list of colors and positions and one loop.

import turtle

t = turtle.Turtle()
t.speed(4)
t.width(12)

# (color, x, y) for each ring
RINGS = [("blue", -220, 0), ("black", 0, 0), ("red", 220, 0), ("gold", -110, -100), ("green", 110, -100)]
RADIUS = 100

for color, x, y in RINGS:
    t.penup()
    t.goto(x, y - RADIUS)  # circle() starts drawing at the bottom of the circle
    t.pendown()
    t.color(color)
    t.circle(RADIUS)

t.hideturtle()
turtle.done()
