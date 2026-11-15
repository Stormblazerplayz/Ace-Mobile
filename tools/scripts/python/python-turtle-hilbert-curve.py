# @title Turtle Hilbert Curve
# @category Drawing
# @kind Turtle program
# @where Save as hilbert.py and run: python3 hilbert.py
# @keywords python hilbert curve, turtle space filling curve, turtle l-system, turtle recursive pattern
# @about Draws a Hilbert curve, a single line that wiggles through every part of a square without crossing itself.

import turtle


def hilbert(t, level, angle, step):
    if level == 0:
        return
    t.right(angle)
    hilbert(t, level - 1, -angle, step)
    t.forward(step)
    t.left(angle)
    hilbert(t, level - 1, angle, step)
    t.forward(step)
    hilbert(t, level - 1, angle, step)
    t.left(angle)
    t.forward(step)
    hilbert(t, level - 1, -angle, step)
    t.right(angle)


LEVEL = 5          # try 1 to 6
SIZE = 500
step = SIZE / (2 ** LEVEL - 1)

screen = turtle.Screen()
screen.bgcolor("black")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.color("spring green")
t.width(2)
t.penup()
t.goto(-SIZE / 2, -SIZE / 2)
t.pendown()
hilbert(t, LEVEL, 90, step)
screen.update()
turtle.done()
