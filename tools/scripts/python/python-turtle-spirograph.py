# @title Turtle Spirograph
# @category Drawing
# @kind Turtle program
# @where Save as spirograph.py and run: python3 spirograph.py. Change R, r and d for new patterns.
# @keywords python spirograph, turtle hypotrochoid, turtle math art, turtle parametric curve
# @about Draws spirograph patterns using the math of a small wheel rolling inside a big one.

import math
import turtle

R, r, d = 200, 73, 110   # big wheel, small wheel, pen distance from the small wheel's center

screen = turtle.Screen()
screen.bgcolor("black")
screen.colormode(255)
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.width(2)


def point(angle):
    """Where the pen is after the small wheel has rolled 'angle' radians."""
    x = (R - r) * math.cos(angle) + d * math.cos((R - r) / r * angle)
    y = (R - r) * math.sin(angle) - d * math.sin((R - r) / r * angle)
    return x, y


# The pattern repeats after r / gcd(R, r) trips around
turns = r // math.gcd(R, r)
steps = 3000
t.penup()
t.goto(point(0))
t.pendown()
for i in range(1, steps + 1):
    angle = i / steps * turns * 2 * math.pi
    shade = int(127 + 127 * math.sin(i / 200))
    t.color(255, shade, 255 - shade)
    t.goto(point(angle))
    if i % 100 == 0:
        screen.update()

screen.update()
turtle.done()
