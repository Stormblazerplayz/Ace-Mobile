# @title Turtle Polygon Maker
# @category Drawing
# @kind Turtle program
# @where Save as polygons.py and run: python3 polygons.py
# @keywords python turtle polygon, turtle regular shapes, turtle exterior angle, turtle function with parameters
# @about Draws every regular polygon from a triangle to a decagon using one function and the 360 degree rule.

import turtle

COLORS = ["red", "orange", "gold", "green", "teal", "blue", "purple", "magenta"]

t = turtle.Turtle()
t.speed(0)
t.pensize(2)


def polygon(sides, length):
    # The turtle turns a full 360 degrees in total, so each turn is 360 / sides
    for _ in range(sides):
        t.forward(length)
        t.left(360 / sides)


for i, sides in enumerate(range(3, 11)):
    t.color(COLORS[i])
    t.penup()
    t.goto(-260 + (i % 4) * 140, 80 - (i // 4) * 200)
    t.pendown()
    polygon(sides, 220 / sides)
    t.penup()
    t.sety(t.ycor() - 25)
    t.write(f"{sides} sides", align="left", font=("Arial", 10, "normal"))

t.hideturtle()
turtle.done()
