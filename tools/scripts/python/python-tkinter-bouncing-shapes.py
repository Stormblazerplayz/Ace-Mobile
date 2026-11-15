# @title Tkinter Bouncing Shapes
# @category Drawing
# @kind Console program
# @where Save as bouncing.py and run: python3 bouncing.py on a computer. Click the window to add more balls.
# @keywords python tkinter canvas animation, tkinter move shapes, tkinter bouncing balls, tkinter click event
# @about Animates colorful balls bouncing around a tkinter canvas, and adds a new ball wherever you click.

import random
import tkinter as tk

WIDTH, HEIGHT = 600, 400
COLORS = ["tomato", "gold", "lime green", "deep sky blue", "orchid", "orange"]

window = tk.Tk()
window.title("Bouncing Shapes (click to add)")
canvas = tk.Canvas(window, width=WIDTH, height=HEIGHT, bg="black")
canvas.pack()
balls = []  # each ball is [canvas id, dx, dy]


def add_ball(x, y):
    r = random.randint(10, 30)
    shape = canvas.create_oval(x - r, y - r, x + r, y + r, fill=random.choice(COLORS), outline="")
    balls.append([shape, random.choice([-1, 1]) * random.uniform(2, 6), random.choice([-1, 1]) * random.uniform(2, 6)])


def animate():
    for ball in balls:
        shape, dx, dy = ball
        canvas.move(shape, dx, dy)
        x1, y1, x2, y2 = canvas.coords(shape)  # where the ball's box is now
        if x1 <= 0 or x2 >= WIDTH:
            ball[1] = -dx
        if y1 <= 0 or y2 >= HEIGHT:
            ball[2] = -dy
    window.after(16, animate)  # about 60 frames per second


canvas.bind("<Button-1>", lambda event: add_ball(event.x, event.y))
for _ in range(5):
    add_ball(random.randint(50, WIDTH - 50), random.randint(50, HEIGHT - 50))
animate()
window.mainloop()
