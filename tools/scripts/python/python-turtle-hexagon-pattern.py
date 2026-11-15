# @title Turtle Honeycomb Pattern
# @category Drawing
# @kind Turtle program
# @where Save as honeycomb.py and run: python3 honeycomb.py
# @keywords python turtle hexagons, turtle honeycomb, turtle tiling pattern, turtle tessellation
# @about Tiles the screen with hexagons like a honeycomb, coloring each one in a gradient.

import math
import turtle

SIDE = 30
screen = turtle.Screen()
screen.colormode(255)
screen.bgcolor(40, 30, 10)
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.penup()

width = SIDE * math.sqrt(3)       # how wide one hexagon is
for row in range(-8, 9):
    for col in range(-9, 10):
        # Every other row shifts right by half a hexagon so they fit together
        x = col * width + (width / 2 if row % 2 else 0)
        y = row * SIDE * 1.5
        shade = max(0, min(255, int(255 - math.hypot(x, y) / 2)))
        t.goto(x, y - SIDE)
        t.setheading(30)
        t.color((90, 60, 10), (255, shade, 0))
        t.pendown()
        t.begin_fill()
        for _ in range(6):
            t.forward(SIDE)
            t.left(60)
        t.end_fill()
        t.penup()

screen.update()
turtle.done()
