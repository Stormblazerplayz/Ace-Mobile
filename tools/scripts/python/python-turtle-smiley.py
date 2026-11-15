# @title Turtle Smiley Face
# @category Drawing
# @kind Turtle program
# @where Save as smiley.py and run: python3 smiley.py
# @keywords python turtle smiley, turtle face drawing, turtle circle extent, turtle dot
# @about Draws a big yellow smiley face with eyes, cheeks and a smile using circles and arcs.

import turtle

t = turtle.Turtle()
t.speed(0)
t.width(4)


def jump(x, y):
    t.penup()
    t.goto(x, y)
    t.pendown()


# Face
jump(0, -200)
t.color("black", "gold")
t.begin_fill()
t.circle(200)
t.end_fill()

# Eyes: dot() draws a filled circle of a given size
for x in (-70, 70):
    jump(x, 60)
    t.dot(50, "white")
    t.dot(24, "black")

# Rosy cheeks
for x in (-120, 120):
    jump(x, -20)
    t.dot(45, "light coral")

# Smile: an arc that goes only part way around a circle
jump(-100, -40)
t.setheading(-60)
t.circle(115, 120)  # radius 115, but only 120 degrees of it

t.hideturtle()
jump(0, 220)
t.write("Have a great day!", align="center", font=("Arial", 22, "bold"))
turtle.done()
