# @title Turtle Pong
# @category Games
# @kind Turtle program
# @where Save as turtle_pong.py and run: python3 turtle_pong.py. Left paddle: W and S. Right paddle: Up and Down.
# @keywords python turtle pong, turtle two player game, turtle paddles, turtle bouncing ball game
# @about Classic two player Pong made with turtle graphics, with a score at the top.

import turtle

screen = turtle.Screen()
screen.setup(800, 500)
screen.bgcolor("black")
screen.title("Turtle Pong")
screen.tracer(0)


def make(shape, x, stretch=1.0):
    t = turtle.Turtle(shape)
    t.color("white")
    t.penup()
    t.shapesize(stretch, 1)
    t.goto(x, 0)
    return t


left = make("square", -350, 5)
right = make("square", 350, 5)
ball = make("circle", 0)
pen = turtle.Turtle()
pen.hideturtle()
pen.color("white")
pen.penup()
pen.goto(0, 210)
state = {"dx": 4, "dy": 3, "left": 0, "right": 0}


def move(paddle, amount):
    paddle.sety(max(-200, min(200, paddle.ycor() + amount)))


def loop():
    ball.goto(ball.xcor() + state["dx"], ball.ycor() + state["dy"])
    if abs(ball.ycor()) > 235:
        state["dy"] *= -1
    # Paddle hit: ball is near the paddle's x and within 50 of its middle
    if -350 < ball.xcor() < -330 and abs(ball.ycor() - left.ycor()) < 55 and state["dx"] < 0:
        state["dx"] *= -1.05
    if 330 < ball.xcor() < 350 and abs(ball.ycor() - right.ycor()) < 55 and state["dx"] > 0:
        state["dx"] *= -1.05
    if ball.xcor() > 390:
        state["left"] += 1
        ball.goto(0, 0)
        state["dx"] = -4
    if ball.xcor() < -390:
        state["right"] += 1
        ball.goto(0, 0)
        state["dx"] = 4
    pen.clear()
    pen.write(f"{state['left']}   {state['right']}", align="center", font=("Courier", 28, "bold"))
    screen.update()
    screen.ontimer(loop, 16)


screen.listen()
screen.onkeypress(lambda: move(left, 25), "w")
screen.onkeypress(lambda: move(left, -25), "s")
screen.onkeypress(lambda: move(right, 25), "Up")
screen.onkeypress(lambda: move(right, -25), "Down")
loop()
turtle.done()
