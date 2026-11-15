# @title Turtle Fractal Tree
# @category Drawing
# @kind Turtle program
# @where Save as tree_art.py and run: python3 tree_art.py
# @keywords python fractal tree, turtle recursion tree, turtle branches, turtle random tree
# @about Grows a tree with recursion: each branch splits into two smaller branches, with a bit of randomness.

import random
import turtle


def branch(t, length, width):
    if length < 8:
        # Tiny branches get a leaf
        t.color("forest green")
        t.dot(6)
        t.color("sienna")
        return
    t.width(width)
    t.forward(length)
    angle = random.randint(15, 35)
    shrink = random.uniform(0.65, 0.8)
    t.left(angle)
    branch(t, length * shrink, width * 0.7)   # left branch
    t.right(angle * 2)
    branch(t, length * shrink, width * 0.7)   # right branch
    t.left(angle)
    t.penup()
    t.backward(length)                         # walk back to where this branch started
    t.pendown()


screen = turtle.Screen()
screen.bgcolor("light cyan")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.color("sienna")
t.penup()
t.goto(0, -280)
t.setheading(90)
t.pendown()
branch(t, 110, 12)
screen.update()
turtle.done()
