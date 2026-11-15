# @title Turtle Analog Clock
# @category Drawing
# @kind Turtle program
# @where Save as clock.py and run: python3 clock.py. The clock keeps ticking until you close the window.
# @keywords python turtle clock, turtle analog clock, turtle ontimer, turtle real time hands
# @about A working analog clock with hour, minute and second hands that move in real time.

import turtle
from datetime import datetime

screen = turtle.Screen()
screen.bgcolor("white")
screen.mode("logo")  # in logo mode, heading 0 points UP, like 12 o'clock
screen.tracer(0)

face = turtle.Turtle()
face.hideturtle()
face.penup()
for hour in range(12):
    face.goto(0, 0)
    face.setheading(hour * 30)
    face.forward(200)
    face.pendown()
    face.forward(20)
    face.penup()
    face.forward(25)
    face.write(str(hour or 12), align="center", font=("Arial", 16, "bold"))

hands = turtle.Turtle()
hands.hideturtle()


def draw_hand(angle, length, width, color):
    hands.penup()
    hands.goto(0, 0)
    hands.setheading(angle)
    hands.width(width)
    hands.color(color)
    hands.pendown()
    hands.forward(length)


def tick():
    now = datetime.now()
    hands.clear()
    draw_hand((now.hour % 12 + now.minute / 60) * 30, 110, 8, "black")
    draw_hand((now.minute + now.second / 60) * 6, 170, 5, "dim gray")
    draw_hand(now.second * 6, 190, 2, "red")
    hands.penup()
    hands.goto(0, 0)
    hands.dot(14, "black")
    screen.update()
    screen.ontimer(tick, 1000)  # redraw every second


tick()
turtle.done()
