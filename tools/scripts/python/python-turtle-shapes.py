# @title Turtle Square, Triangle and Star
# @category Drawing
# @kind Turtle program
# @where Save as shapes.py and run: python3 shapes.py. A drawing window opens.
# @keywords python turtle basics, turtle draw square, turtle draw star, turtle forward left
# @about Your first turtle drawing: a square, a triangle and a star, each drawn with a loop.

import turtle

t = turtle.Turtle()
t.speed(3)       # 1 is slow, 10 is fast, 0 is instant
t.pensize(3)

# Square: 4 sides, turn 90 degrees each time
t.penup()
t.goto(-250, 0)
t.pendown()
t.color("blue")
for _ in range(4):
    t.forward(120)
    t.left(90)

# Triangle: 3 sides, turn 120 degrees (360 / 3)
t.penup()
t.goto(-60, 0)
t.pendown()
t.color("green")
for _ in range(3):
    t.forward(120)
    t.left(120)

# Star: 5 points, turn 144 degrees
t.penup()
t.goto(120, 60)
t.pendown()
t.color("orange")
t.begin_fill()
for _ in range(5):
    t.forward(150)
    t.right(144)
t.end_fill()

t.hideturtle()
turtle.done()  # keep the window open
