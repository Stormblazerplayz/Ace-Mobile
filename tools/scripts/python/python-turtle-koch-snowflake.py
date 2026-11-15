# @title Turtle Koch Snowflake
# @category Drawing
# @kind Turtle program
# @where Save as snowflake.py and run: python3 snowflake.py
# @keywords python koch snowflake, turtle fractal, turtle recursive drawing, turtle snowflake
# @about Draws the famous Koch snowflake fractal, where every line gets a bump, and every bump gets bumps.

import turtle


def koch(t, length, depth):
    if depth == 0:
        t.forward(length)
        return
    # Split the line in 3 and make a pointy bump in the middle third
    for angle in (60, -120, 60, 0):
        koch(t, length / 3, depth - 1)
        t.left(angle)


screen = turtle.Screen()
screen.bgcolor("navy")
screen.tracer(0)  # draw instantly

t = turtle.Turtle()
t.hideturtle()
t.color("white", "light cyan")
t.penup()
t.goto(-200, 115)
t.pendown()

t.begin_fill()
for _ in range(3):  # three sides make a triangle shaped snowflake
    koch(t, 400, 4)  # try depth 0, 1, 2 or 5
    t.right(120)
t.end_fill()

screen.update()
turtle.done()
