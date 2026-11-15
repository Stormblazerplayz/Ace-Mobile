# @title Turtle Rainbow Spiral
# @category Drawing
# @kind Turtle program
# @where Save as spiral.py and run: python3 spiral.py
# @keywords python turtle spiral, turtle rainbow colors, turtle colormode, turtle growing lines
# @about Draws a glowing rainbow spiral on a black background by turning a little and stepping farther each time.

import colorsys
import turtle

screen = turtle.Screen()
screen.bgcolor("black")
screen.colormode(1.0)  # colors as (red, green, blue) from 0 to 1

t = turtle.Turtle()
t.speed(0)
t.width(2)
screen.tracer(4)  # draw 4 steps at a time so it's quicker

for step in range(360):
    hue = step / 360                        # slowly go around the color wheel
    t.color(colorsys.hsv_to_rgb(hue, 1, 1))  # turn the hue into red, green, blue
    t.forward(step * 0.8)
    t.left(59)                              # try 89, 91, 121 or 144 for different spirals!

t.hideturtle()
screen.update()
turtle.done()
