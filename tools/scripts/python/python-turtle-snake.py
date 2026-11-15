# @title Turtle Snake
# @category Games
# @kind Turtle program
# @where Save as turtle_snake.py and run: python3 turtle_snake.py. Steer with the arrow keys.
# @keywords python turtle snake, turtle snake game, turtle segments, turtle game loop ontimer
# @about The Snake game built with turtle graphics: eat the food, grow a tail and avoid the walls.

import random
import turtle

STEP = 20
screen = turtle.Screen()
screen.setup(600, 600)
screen.bgcolor("black")
screen.title("Turtle Snake")
screen.tracer(0)

head = turtle.Turtle("square")
head.color("lime")
head.penup()
food = turtle.Turtle("circle")
food.color("red")
food.penup()
food.goto(100, 100)
pen = turtle.Turtle()
pen.hideturtle()
pen.color("white")
pen.penup()
pen.goto(0, 260)

segments = []
direction = {"dx": STEP, "dy": 0}


def go(dx, dy):
    # Don't allow turning straight back into yourself
    if (dx, dy) != (-direction["dx"], -direction["dy"]):
        direction["dx"], direction["dy"] = dx, dy


def tick():
    # Move each tail piece to where the piece in front of it was
    for i in range(len(segments) - 1, 0, -1):
        segments[i].goto(segments[i - 1].pos())
    if segments:
        segments[0].goto(head.pos())
    head.goto(head.xcor() + direction["dx"], head.ycor() + direction["dy"])

    if head.distance(food) < 15:
        food.goto(random.randrange(-280, 281, STEP), random.randrange(-280, 241, STEP))
        piece = turtle.Turtle("square")
        piece.color("green")
        piece.penup()
        piece.goto(head.pos())
        segments.append(piece)

    crashed = abs(head.xcor()) > 290 or abs(head.ycor()) > 290
    crashed = crashed or any(s.distance(head) < 10 for s in segments)
    pen.clear()
    pen.write(f"Length: {len(segments) + 1}", align="center", font=("Arial", 16, "bold"))
    screen.update()
    if crashed:
        pen.goto(0, 0)
        pen.write("GAME OVER", align="center", font=("Arial", 32, "bold"))
    else:
        screen.ontimer(tick, 110)


screen.listen()
screen.onkeypress(lambda: go(0, STEP), "Up")
screen.onkeypress(lambda: go(0, -STEP), "Down")
screen.onkeypress(lambda: go(-STEP, 0), "Left")
screen.onkeypress(lambda: go(STEP, 0), "Right")
tick()
turtle.done()
