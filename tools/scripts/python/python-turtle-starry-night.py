# @title Turtle Starry Night
# @category Drawing
# @kind Turtle program
# @where Save as night_sky.py and run: python3 night_sky.py
# @keywords python turtle stars, turtle night sky, turtle random positions, turtle moon drawing
# @about Paints a night sky full of random twinkling stars, a crescent moon and a city skyline.

import random
import turtle

screen = turtle.Screen()
screen.setup(800, 600)
screen.bgcolor("midnight blue")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.penup()


def star(x, y, size, color):
    t.goto(x, y)
    t.color(color)
    t.begin_fill()
    for _ in range(5):
        t.forward(size)
        t.right(144)
    t.end_fill()


# Lots of small dots and a few bigger stars
for _ in range(200):
    t.goto(random.randint(-400, 400), random.randint(-100, 300))
    t.dot(random.randint(1, 4), random.choice(["white", "light yellow", "light blue"]))
for _ in range(12):
    star(random.randint(-380, 380), random.randint(0, 280), random.randint(10, 25), "gold")

# Crescent moon: a white circle with a sky-colored circle on top of it
t.goto(260, 230)
t.dot(110, "ivory")
t.goto(290, 250)
t.dot(100, "midnight blue")

# City skyline
x = -400
while x < 400:
    width = random.randint(40, 90)
    height = random.randint(60, 200)
    t.goto(x, -300)
    t.color("black")
    t.begin_fill()
    for side in (width, height, width, height):
        t.forward(side)
        t.left(90)
    t.end_fill()
    for wy in range(-280, -300 + height - 20, 30):  # lit windows
        for wx in range(x + 10, x + width - 10, 20):
            if random.random() < 0.4:
                t.goto(wx, wy)
                t.dot(6, "yellow")
    x += width

screen.update()
turtle.done()
