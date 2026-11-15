# @title Tkinter Cookie Clicker
# @category Games
# @kind Console program
# @where Save as clicker_app.py and run: python3 clicker_app.py on a computer (tkinter comes with Python).
# @keywords python tkinter clicker, tkinter idle game, tkinter buttons and labels, tkinter after timer
# @about A tiny idle clicker game with a window: click for cookies, buy helpers that bake cookies for you every second.

import tkinter as tk

state = {"cookies": 0, "per_click": 1, "per_second": 0, "click_cost": 15, "helper_cost": 25}

window = tk.Tk()
window.title("Cookie Clicker")
window.geometry("320x360")

count_label = tk.Label(window, text="0 cookies", font=("Arial", 22, "bold"))
count_label.pack(pady=12)
rate_label = tk.Label(window, text="", font=("Arial", 12))
rate_label.pack()


def refresh():
    count_label.config(text=f"{state['cookies']} cookies")
    rate_label.config(text=f"{state['per_click']} per click, {state['per_second']} per second")
    upgrade_button.config(text=f"Bigger clicks (cost {state['click_cost']})")
    helper_button.config(text=f"Hire a baker (cost {state['helper_cost']})")


def click():
    state["cookies"] += state["per_click"]
    refresh()


def buy_upgrade():
    if state["cookies"] >= state["click_cost"]:
        state["cookies"] -= state["click_cost"]
        state["per_click"] += 1
        state["click_cost"] = int(state["click_cost"] * 1.6)
        refresh()


def buy_helper():
    if state["cookies"] >= state["helper_cost"]:
        state["cookies"] -= state["helper_cost"]
        state["per_second"] += 1
        state["helper_cost"] = int(state["helper_cost"] * 1.5)
        refresh()


def every_second():
    state["cookies"] += state["per_second"]
    refresh()
    window.after(1000, every_second)  # call this again in 1000 ms


tk.Button(window, text="COOKIE", font=("Arial", 24), width=10, height=2, command=click).pack(pady=16)
upgrade_button = tk.Button(window, command=buy_upgrade)
upgrade_button.pack(pady=4)
helper_button = tk.Button(window, command=buy_helper)
helper_button.pack(pady=4)

refresh()
every_second()
window.mainloop()
