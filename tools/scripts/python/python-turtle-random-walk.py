# @title Turtle Random Walk
# @category Drawing
# @kind Turtle program
# @where Save as random_walk.py and run: python3 random_walk.py
# @keywords python random walk, turtle random art, turtle multiple turtles, turtle wander
# @about Lets five colorful turtles wander randomly, leaving trails that make abstract art.

import random
import turtle

screen = turtle.Screen()
screen.bgcolor("black")
screen.tracer(0)
COLORS = ["red", "orange", "yellow", "lime", "cyan"]

walkers = []
for color in COLORS:
    t = turtle.Turtle()
    t.hideturtle()
    t.color(color)
    t.width(3)
    walkers.append(t)

for step in range(600):
    for t in walkers:
        t.setheading(random.choice([0, 90, 180, 270]))  # pick a random direction
        t.forward(15)
        # If a walker wanders off the screen, bring it back to the middle
        if abs(t.xcor()) > 380 or abs(t.ycor()) > 300:
            t.penup()
            t.goto(0, 0)
            t.pendown()
    if step % 5 == 0:
        screen.update()

screen.update()
turtle.done()
