# @title Tkinter Stopwatch
# @category Tools
# @kind Console program
# @where Save as stopwatch_app.py and run: python3 stopwatch_app.py on a computer (tkinter comes with Python).
# @keywords python tkinter stopwatch, tkinter after loop, tkinter start stop reset, python gui timer
# @about A stopwatch window with big numbers and Start, Stop and Reset buttons.

import time
import tkinter as tk

state = {"running": False, "start": 0.0, "elapsed": 0.0}


def update():
    total = state["elapsed"]
    if state["running"]:
        total += time.perf_counter() - state["start"]
    minutes, seconds = divmod(total, 60)
    label.config(text=f"{int(minutes):02d}:{seconds:05.2f}")
    window.after(30, update)  # refresh about 33 times a second


def start():
    if not state["running"]:
        state["running"] = True
        state["start"] = time.perf_counter()


def stop():
    if state["running"]:
        state["elapsed"] += time.perf_counter() - state["start"]
        state["running"] = False


def reset():
    state["running"] = False
    state["elapsed"] = 0.0


window = tk.Tk()
window.title("Stopwatch")
label = tk.Label(window, text="00:00.00", font=("Courier", 48, "bold"), padx=20, pady=10)
label.pack()
buttons = tk.Frame(window)
buttons.pack(pady=10)
for text, action in [("Start", start), ("Stop", stop), ("Reset", reset)]:
    tk.Button(buttons, text=text, width=8, font=("Arial", 14), command=action).pack(side="left", padx=5)
update()
window.mainloop()
