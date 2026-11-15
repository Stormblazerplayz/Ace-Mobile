# @title Turtle Flower
# @category Drawing
# @kind Turtle program
# @where Save as flower.py and run: python3 flower.py
# @keywords python turtle flower, turtle circle arcs, turtle petals, turtle draw stem
# @about Draws a flower with petals made from circle arcs, a center and a stem with a leaf.

import turtle

t = turtle.Turtle()
t.speed(0)
turtle.Screen().bgcolor("lavender")


def petal(size):
    # Two arcs back to back make a leaf or petal shape
    for _ in range(2):
        t.circle(size, 60)
        t.left(120)


# Stem
t.penup()
t.goto(0, -250)
t.pendown()
t.color("green")
t.width(8)
t.setheading(90)
t.forward(250)

# Leaf
t.width(1)
t.penup()
t.goto(0, -150)
t.pendown()
t.setheading(30)
t.begin_fill()
petal(100)
t.end_fill()

# Petals
t.color("deep pink", "hot pink")
for _ in range(12):
    t.penup()
    t.goto(0, 0)
    t.pendown()
    t.begin_fill()
    petal(120)
    t.end_fill()
    t.left(30)

# Center
t.penup()
t.goto(0, -25)
t.color("orange", "gold")
t.begin_fill()
t.circle(25)
t.end_fill()

t.hideturtle()
turtle.done()
