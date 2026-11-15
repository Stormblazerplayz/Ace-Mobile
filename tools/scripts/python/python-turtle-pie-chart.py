# @title Turtle Pie Chart
# @category Drawing
# @kind Turtle program
# @where Save as pie_chart.py and run: python3 pie_chart.py. Edit DATA to chart your own numbers.
# @keywords python turtle pie chart, turtle percentages, turtle circle slices, turtle data chart
# @about Draws a pie chart where each slice's size matches its share of the total, with labels.

import turtle

DATA = {"Gaming": 8, "Coding": 6, "School": 7, "Sports": 3, "Sleep": 9}
COLORS = ["tomato", "gold", "medium sea green", "dodger blue", "medium purple"]
RADIUS = 200

screen = turtle.Screen()
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
total = sum(DATA.values())

heading = 0
for i, (label, value) in enumerate(DATA.items()):
    slice_angle = value / total * 360
    t.penup()
    t.goto(0, 0)
    t.setheading(heading)
    t.color("white", COLORS[i % len(COLORS)])
    t.pendown()
    t.begin_fill()
    t.forward(RADIUS)
    t.left(90)
    t.circle(RADIUS, slice_angle)  # draw the curved edge of the slice
    t.goto(0, 0)
    t.end_fill()

    # Put the label halfway around the slice, just outside the circle
    t.penup()
    t.setheading(heading + slice_angle / 2)
    t.forward(RADIUS + 40)
    t.color("black")
    t.write(f"{label} {value / total:.0%}", align="center", font=("Arial", 12, "bold"))
    heading += slice_angle

screen.update()
turtle.done()
