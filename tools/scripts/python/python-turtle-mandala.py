# @title Turtle Mandala
# @category Drawing
# @kind Turtle program
# @where Save as mandala.py and run: python3 mandala.py
# @keywords python turtle mandala, turtle symmetry art, turtle repeating pattern, turtle rotate shapes
# @about Builds a colorful mandala by repeating the same shapes while rotating around the center.

import turtle

screen = turtle.Screen()
screen.bgcolor("black")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.width(2)

LAYERS = [
    # (how many copies, shape size, color)
    (36, 180, "dark violet"),
    (24, 130, "deep pink"),
    (18, 90, "orange"),
    (12, 55, "gold"),
]

for copies, size, color in LAYERS:
    t.color(color)
    for i in range(copies):
        t.penup()
        t.goto(0, 0)
        t.setheading(i * 360 / copies)
        t.pendown()
        # Each copy is a little diamond made of two arcs
        t.circle(size, 60)
        t.left(120)
        t.circle(size, 60)

t.penup()
t.goto(0, 0)
t.dot(30, "white")
screen.update()
turtle.done()
