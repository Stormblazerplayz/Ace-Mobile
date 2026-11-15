# @title Turtle Sierpinski Triangle
# @category Drawing
# @kind Turtle program
# @where Save as sierpinski.py and run: python3 sierpinski.py
# @keywords python sierpinski triangle, turtle triangle fractal, turtle recursion colors, turtle midpoint
# @about Draws a Sierpinski triangle: a triangle made of three smaller triangles, made of smaller triangles, and so on.

import turtle

COLORS = ["midnight blue", "blue", "dodger blue", "deep sky blue", "light sky blue", "white"]


def triangle(t, points, color):
    t.fillcolor(color)
    t.penup()
    t.goto(points[0])
    t.pendown()
    t.begin_fill()
    t.goto(points[1])
    t.goto(points[2])
    t.goto(points[0])
    t.end_fill()


def middle(a, b):
    return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)


def sierpinski(t, points, depth):
    triangle(t, points, COLORS[depth % len(COLORS)])
    if depth > 0:
        a, b, c = points
        sierpinski(t, [a, middle(a, b), middle(a, c)], depth - 1)
        sierpinski(t, [b, middle(a, b), middle(b, c)], depth - 1)
        sierpinski(t, [c, middle(c, b), middle(a, c)], depth - 1)


screen = turtle.Screen()
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
sierpinski(t, [(-300, -250), (0, 270), (300, -250)], 5)
screen.update()
turtle.done()
