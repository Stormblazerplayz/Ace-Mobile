# @title Turtle Dragon Curve
# @category Drawing
# @kind Turtle program
# @where Save as dragon.py and run: python3 dragon.py
# @keywords python dragon curve, turtle paper folding fractal, turtle string rules, turtle dragon
# @about Draws the dragon curve fractal, the shape you'd get by folding a strip of paper in half over and over.

import turtle

# Build the list of turns: each round is old turns + R + old turns flipped and reversed
turns = ""
for _ in range(12):
    flipped = "".join("L" if c == "R" else "R" for c in reversed(turns))
    turns = turns + "R" + flipped

screen = turtle.Screen()
screen.bgcolor("black")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.width(2)
t.penup()
t.goto(-120, 100)
t.pendown()

colors = ["red", "orange", "yellow", "lime", "cyan", "violet"]
t.forward(5)
for i, turn in enumerate(turns):
    t.color(colors[i * len(colors) // len(turns)])  # change color as we go
    if turn == "R":
        t.right(90)
    else:
        t.left(90)
    t.forward(5)

screen.update()
turtle.done()
