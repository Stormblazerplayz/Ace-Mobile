# @title Turtle Bar Chart
# @category Drawing
# @kind Turtle program
# @where Save as bar_chart.py and run: python3 bar_chart.py. Change the DATA dictionary to chart your own numbers.
# @keywords python turtle bar chart, turtle graph data, turtle labels, turtle draw chart
# @about Draws a labeled bar chart from a dictionary of numbers, scaling the bars to fit the window.

import turtle

DATA = {"Mon": 3, "Tue": 5, "Wed": 2, "Thu": 7, "Fri": 6, "Sat": 9, "Sun": 4}
TITLE = "Hours of coding this week"
COLORS = ["tomato", "orange", "gold", "yellow green", "turquoise", "royal blue", "orchid"]

screen = turtle.Screen()
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.penup()

LEFT, BOTTOM, MAX_HEIGHT, BAR_WIDTH = -300, -200, 380, 60
biggest = max(DATA.values())

# Axis line
t.goto(LEFT - 10, BOTTOM)
t.pendown()
t.goto(LEFT + len(DATA) * (BAR_WIDTH + 20), BOTTOM)
t.penup()

for i, (label, value) in enumerate(DATA.items()):
    x = LEFT + i * (BAR_WIDTH + 20)
    height = value / biggest * MAX_HEIGHT   # scale so the tallest bar fits
    t.goto(x, BOTTOM)
    t.color("black", COLORS[i % len(COLORS)])
    t.pendown()
    t.begin_fill()
    for side in (BAR_WIDTH, height, BAR_WIDTH, height):
        t.forward(side)
        t.left(90)
    t.end_fill()
    t.penup()
    t.goto(x + BAR_WIDTH / 2, BOTTOM + height + 5)
    t.write(str(value), align="center", font=("Arial", 12, "bold"))
    t.goto(x + BAR_WIDTH / 2, BOTTOM - 25)
    t.write(label, align="center", font=("Arial", 12, "normal"))

t.goto(0, BOTTOM + MAX_HEIGHT + 30)
t.write(TITLE, align="center", font=("Arial", 18, "bold"))
screen.update()
turtle.done()
