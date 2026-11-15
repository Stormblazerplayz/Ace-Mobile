# @title Turtle Checkerboard
# @category Drawing
# @kind Turtle program
# @where Save as checkerboard.py and run: python3 checkerboard.py
# @keywords python turtle checkerboard, turtle nested loops grid, turtle chess board, turtle squares pattern
# @about Draws an 8 by 8 checkerboard with nested loops and puts checkers pieces on the dark squares.

import turtle

SIZE = 60
screen = turtle.Screen()
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.penup()


def square(x, y, color):
    t.goto(x, y)
    t.color(color)
    t.begin_fill()
    for _ in range(4):
        t.forward(SIZE)
        t.left(90)
    t.end_fill()


start = -4 * SIZE
for row in range(8):
    for col in range(8):
        dark = (row + col) % 2 == 1
        x, y = start + col * SIZE, start + row * SIZE
        square(x, y, "saddle brown" if dark else "wheat")
        # Checkers pieces sit on dark squares in the first 3 and last 3 rows
        if dark and (row < 3 or row > 4):
            t.goto(x + SIZE / 2, y + SIZE / 2)
            t.dot(SIZE * 0.75, "black" if row < 3 else "red")

screen.update()
turtle.done()
