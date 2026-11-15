# @title Turtle Pixel Art
# @category Drawing
# @kind Turtle program
# @where Save as pixel_art.py and run: python3 pixel_art.py. Edit the PICTURE rows to make your own sprite.
# @keywords python pixel art, turtle sprite drawing, turtle grid of colors, turtle draw from list
# @about Draws a pixel art sprite from rows of letters, where each letter stands for a color.

import turtle

# Each letter is one pixel. Change these to make your own 16x16 art!
PICTURE = [
    "......RRRRR.....",
    ".....RRRRRRRRR..",
    ".....BBBSSBS....",
    "....BSBSSSBSSS..",
    "....BSBBSSSBSSS.",
    "....BBSSSSBBBB..",
    "......SSSSSSS...",
    ".....RRORRR.....",
    "....RRRORRORRR..",
    "...RRRROOOORRRR.",
    "...SSROYOOYORSS.",
    "...SSSOOOOOOSSS.",
    "...SSOOOOOOOOSS.",
    ".....OOO..OOO...",
    "....BBB....BBB..",
    "...BBBB....BBBB.",
]
COLORS = {"R": "red", "B": "saddle brown", "S": "peach puff", "O": "blue", "Y": "yellow"}
PIXEL = 25

screen = turtle.Screen()
screen.bgcolor("sky blue")
screen.tracer(0)
t = turtle.Turtle()
t.hideturtle()
t.penup()

top = len(PICTURE) * PIXEL / 2
left = -len(PICTURE[0]) * PIXEL / 2
for row, line in enumerate(PICTURE):
    for col, letter in enumerate(line):
        if letter in COLORS:
            t.goto(left + col * PIXEL, top - row * PIXEL)
            t.color(COLORS[letter])
            t.begin_fill()
            for _ in range(4):
                t.forward(PIXEL)
                t.right(90)
            t.end_fill()

screen.update()
turtle.done()
