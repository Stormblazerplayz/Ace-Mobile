# @title Tkinter Paint App
# @category Drawing
# @kind Console program
# @where Save as paint.py and run: python3 paint.py on a computer (tkinter comes with Python). Drag the mouse to paint.
# @keywords python tkinter paint, tkinter canvas drawing, tkinter mouse drag, tkinter colorchooser
# @about A little paint program: drag to draw, pick colors and brush sizes, and clear the canvas.

import tkinter as tk
from tkinter import colorchooser

window = tk.Tk()
window.title("Paint")
state = {"color": "black", "size": 6, "last": None}

canvas = tk.Canvas(window, width=700, height=480, bg="white", cursor="crosshair")
canvas.pack()


def paint(event):
    if state["last"]:
        x, y = state["last"]
        # Draw a line from the last spot to this one so fast strokes have no gaps
        canvas.create_line(x, y, event.x, event.y, fill=state["color"], width=state["size"],
                           capstyle=tk.ROUND, smooth=True)
    state["last"] = (event.x, event.y)


def stop(event):
    state["last"] = None


def pick_color():
    chosen = colorchooser.askcolor(color=state["color"])[1]  # [1] is the color as "#rrggbb"
    if chosen:
        state["color"] = chosen


def set_size(value):
    state["size"] = int(value)


canvas.bind("<B1-Motion>", paint)          # B1 = left mouse button held down
canvas.bind("<ButtonRelease-1>", stop)

bar = tk.Frame(window)
bar.pack(fill="x", pady=4)
for color in ["black", "red", "orange", "gold", "green", "blue", "purple", "white"]:
    tk.Button(bar, bg=color, width=2, command=lambda c=color: state.update(color=c)).pack(side="left", padx=2)
tk.Button(bar, text="More colors", command=pick_color).pack(side="left", padx=6)
size = tk.Scale(bar, from_=1, to=40, orient="horizontal", label="Brush", command=set_size)
size.set(state["size"])
size.pack(side="left", padx=6)
tk.Button(bar, text="Clear", command=lambda: canvas.delete("all")).pack(side="right", padx=6)
window.mainloop()
