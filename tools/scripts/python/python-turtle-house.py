# @title Turtle House Scene
# @category Drawing
# @kind Turtle program
# @where Save as house.py and run: python3 house.py
# @keywords python turtle house, turtle scene, turtle fill color, turtle helper functions
# @about Draws a house with a roof, door, windows, a sun and grass using small helper functions.

import turtle

screen = turtle.Screen()
screen.bgcolor("sky blue")
t = turtle.Turtle()
t.speed(0)


def jump(x, y):
    t.penup()
    t.goto(x, y)
    t.pendown()


def rectangle(x, y, w, h, color):
    jump(x, y)
    t.color("black", color)  # outline color, fill color
    t.begin_fill()
    for side in (w, h, w, h):
        t.forward(side)
        t.left(90)
    t.end_fill()


def triangle(x, y, w, h, color):
    jump(x, y)
    t.color("black", color)
    t.begin_fill()
    t.goto(x + w, y)
    t.goto(x + w / 2, y + h)
    t.goto(x, y)
    t.end_fill()


def circle(x, y, r, color):
    jump(x, y - r)  # circle() draws from the bottom
    t.color(color, color)
    t.begin_fill()
    t.circle(r)
    t.end_fill()


rectangle(-400, -300, 800, 150, "forest green")   # grass
rectangle(-150, -150, 300, 200, "light yellow")   # walls
triangle(-180, 50, 360, 140, "firebrick")         # roof
rectangle(-30, -150, 60, 110, "saddle brown")     # door
circle(18, -95, 5, "gold")                        # door knob
rectangle(-120, -60, 60, 60, "light blue")        # windows
rectangle(60, -60, 60, 60, "light blue")
circle(250, 200, 50, "yellow")                    # sun

t.hideturtle()
turtle.done()
