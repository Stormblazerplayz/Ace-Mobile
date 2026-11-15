# @title Turtle Catch the Falling Stars
# @category Games
# @kind Turtle program
# @where Save as catch.py and run: python3 catch.py. Move the basket with the Left and Right arrow keys.
# @keywords python turtle game, turtle catch game, turtle arrow keys, turtle falling objects
# @about A turtle game where you slide a basket left and right to catch falling stars before they hit the ground.

import random
import turtle

screen = turtle.Screen()
screen.setup(600, 600)
screen.bgcolor("midnight blue")
screen.title("Catch the Stars")
screen.tracer(0)  # we will call screen.update() ourselves, so it's smooth

basket = turtle.Turtle("square")
basket.shapesize(1, 5)  # stretch it into a wide basket
basket.color("orange")
basket.penup()
basket.goto(0, -250)

star = turtle.Turtle("circle")
star.color("yellow")
star.penup()

pen = turtle.Turtle()
pen.hideturtle()
pen.color("white")
pen.penup()
pen.goto(0, 260)

state = {"score": 0, "lives": 3, "speed": 5}


def drop_new_star():
    star.goto(random.randint(-270, 270), 300)


def move_left():
    basket.setx(max(-250, basket.xcor() - 30))


def move_right():
    basket.setx(min(250, basket.xcor() + 30))


def game_loop():
    star.sety(star.ycor() - state["speed"])
    if star.ycor() < -235 and abs(star.xcor() - basket.xcor()) < 60:
        state["score"] += 1
        state["speed"] += 0.3
        drop_new_star()
    elif star.ycor() < -300:
        state["lives"] -= 1
        drop_new_star()
    pen.clear()
    pen.write(f"Score: {state['score']}   Lives: {state['lives']}", align="center", font=("Arial", 18, "bold"))
    screen.update()
    if state["lives"] > 0:
        screen.ontimer(game_loop, 20)  # run again in 20 ms
    else:
        pen.goto(0, 0)
        pen.write("GAME OVER", align="center", font=("Arial", 36, "bold"))


screen.listen()
screen.onkeypress(move_left, "Left")
screen.onkeypress(move_right, "Right")
drop_new_star()
game_loop()
turtle.done()
