# @title Turtle Click to Draw
# @category Drawing
# @kind Turtle program
# @where Save as click_draw.py and run: python3 click_draw.py. Click to connect dots, drag the turtle to draw freehand.
# @keywords python turtle mouse, turtle onclick, turtle ondrag, turtle connect the dots
# @about Draw with the mouse: click anywhere to draw a line there, or drag the turtle to draw freehand.

import random
import turtle

screen = turtle.Screen()
screen.title("Click to draw lines. Drag the turtle to scribble. Right-click for a new color.")
pen = turtle.Turtle("circle")
pen.shapesize(0.5)
pen.speed(0)
pen.width(4)


def line_to(x, y):
    pen.goto(x, y)


def drag(x, y):
    pen.ondrag(None)       # stop listening while we move (prevents lag)
    pen.goto(x, y)
    pen.ondrag(drag)


def random_color(x, y):
    pen.color(random.random(), random.random(), random.random())


screen.onclick(line_to)            # left click
screen.onclick(random_color, 3)    # right click (button 3)
pen.ondrag(drag)
turtle.done()
