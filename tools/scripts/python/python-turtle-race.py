# @title Turtle Race
# @category Games
# @kind Turtle program
# @where Save as race.py and run: python3 race.py. Type your bet in the box that pops up.
# @keywords python turtle race, turtle betting game, turtle random race, turtle textinput
# @about Bet on one of five colorful turtles, then watch them race across the screen to the finish line.

import random
import turtle

screen = turtle.Screen()
screen.setup(700, 450)
screen.title("Turtle Race")
COLORS = ["red", "orange", "green", "blue", "purple"]

bet = screen.textinput("Place your bet", "Which turtle will win? " + ", ".join(COLORS))
bet = (bet or "").strip().lower()

# Draw the finish line
line = turtle.Turtle()
line.hideturtle()
line.speed(0)
line.penup()
line.goto(280, 180)
line.pendown()
line.pensize(4)
line.goto(280, -180)

racers = []
for i, color in enumerate(COLORS):
    t = turtle.Turtle("turtle")
    t.color(color)
    t.penup()
    t.goto(-300, 140 - i * 70)
    racers.append(t)

winner = None
while winner is None:
    for racer in racers:
        racer.forward(random.randint(1, 12))
        if racer.xcor() >= 280:
            winner = racer
            break

name = winner.pencolor()
line.penup()
line.goto(0, 190)
message = f"{name.upper()} wins! " + ("You won the bet!" if name == bet else "Better luck next time.")
line.write(message, align="center", font=("Arial", 18, "bold"))
turtle.done()
