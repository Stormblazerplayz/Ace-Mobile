# @title Turtle Etch A Sketch
# @category Drawing
# @kind Turtle program
# @where Save as sketch.py and run: python3 sketch.py. Draw with the arrow keys, press space to lift the pen, c to change color, x to clear.
# @keywords python turtle etch a sketch, turtle keyboard drawing, turtle onkey, turtle drawing toy
# @about Turns the keyboard into an Etch A Sketch: arrow keys draw lines, and other keys change the pen.

import turtle

screen = turtle.Screen()
screen.title("Etch A Sketch: arrows draw, space = pen up/down, c = color, x = clear")
screen.bgcolor("light gray")

pen = turtle.Turtle("turtle")
pen.speed(0)
pen.width(3)
COLORS = ["black", "red", "blue", "green", "purple", "orange"]
state = {"color": 0}


def move(heading):
    pen.setheading(heading)
    pen.forward(10)


def toggle_pen():
    if pen.isdown():
        pen.penup()
    else:
        pen.pendown()


def next_color():
    state["color"] = (state["color"] + 1) % len(COLORS)
    pen.color(COLORS[state["color"]])


def clear_screen():
    pen.clear()  # erase the drawing but keep the turtle where it is


screen.onkeypress(lambda: move(90), "Up")
screen.onkeypress(lambda: move(270), "Down")
screen.onkeypress(lambda: move(180), "Left")
screen.onkeypress(lambda: move(0), "Right")
screen.onkey(toggle_pen, "space")
screen.onkey(next_color, "c")
screen.onkey(clear_screen, "x")
screen.listen()  # start listening for key presses
turtle.done()
