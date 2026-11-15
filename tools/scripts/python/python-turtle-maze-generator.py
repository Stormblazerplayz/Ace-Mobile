# @title Turtle Maze Generator
# @category Drawing
# @kind Turtle program
# @where Save as maze_maker.py and run: python3 maze_maker.py. Every run makes a brand new maze.
# @keywords python maze generator, turtle maze, python depth first search, python random maze
# @about Builds a random maze with a depth-first search, then draws it with turtle graphics.

import random
import turtle

COLS, ROWS, CELL = 20, 15, 30
# walls[(c, r)] holds which sides of a cell still have walls
walls = {(c, r): {"N", "S", "E", "W"} for c in range(COLS) for r in range(ROWS)}
MOVES = {"N": (0, 1, "S"), "S": (0, -1, "N"), "E": (1, 0, "W"), "W": (-1, 0, "E")}

# Depth-first search: walk to random unvisited neighbors, back up when stuck
stack = [(0, 0)]
visited = {(0, 0)}
while stack:
    c, r = stack[-1]
    options = [(d, (c + dc, r + dr), opposite) for d, (dc, dr, opposite) in MOVES.items()
               if (c + dc, r + dr) in walls and (c + dc, r + dr) not in visited]
    if not options:
        stack.pop()
        continue
    direction, nxt, opposite = random.choice(options)
    walls[(c, r)].discard(direction)   # knock down the wall between the two cells
    walls[nxt].discard(opposite)
    visited.add(nxt)
    stack.append(nxt)
walls[(0, 0)].discard("W")                 # entrance
walls[(COLS - 1, ROWS - 1)].discard("E")   # exit

screen = turtle.Screen()
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.width(3)
left, bottom = -COLS * CELL / 2, -ROWS * CELL / 2


def line(x1, y1, x2, y2):
    t.penup()
    t.goto(x1, y1)
    t.pendown()
    t.goto(x2, y2)


for (c, r), sides in walls.items():
    x, y = left + c * CELL, bottom + r * CELL
    if "S" in sides:
        line(x, y, x + CELL, y)
    if "N" in sides:
        line(x, y + CELL, x + CELL, y + CELL)
    if "W" in sides:
        line(x, y, x, y + CELL)
    if "E" in sides:
        line(x + CELL, y, x + CELL, y + CELL)

screen.update()
turtle.done()
