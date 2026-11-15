# @title Tkinter Tic Tac Toe
# @category Games
# @kind Console program
# @where Save as ttt_window.py and run: python3 ttt_window.py on a computer (tkinter comes with Python).
# @keywords python tkinter tic tac toe, tkinter grid buttons, tkinter messagebox, tkinter game window
# @about Tic tac toe in a real window with clickable buttons, a winner popup and a restart.

import tkinter as tk
from tkinter import messagebox

LINES = [(0, 1, 2), (3, 4, 5), (6, 7, 8), (0, 3, 6), (1, 4, 7), (2, 5, 8), (0, 4, 8), (2, 4, 6)]

window = tk.Tk()
window.title("Tic Tac Toe")
turn = {"player": "X"}
buttons = []


def check_winner():
    marks = [b["text"] for b in buttons]
    for a, b, c in LINES:
        if marks[a] and marks[a] == marks[b] == marks[c]:
            return marks[a]
    if all(marks):
        return "tie"
    return None


def reset():
    for b in buttons:
        b.config(text="", state="normal")
    turn["player"] = "X"


def clicked(index):
    button = buttons[index]
    if button["text"]:
        return  # already taken
    button.config(text=turn["player"], fg="red" if turn["player"] == "X" else "blue")
    result = check_winner()
    if result:
        messagebox.showinfo("Game over", "It's a tie!" if result == "tie" else f"{result} wins!")
        reset()
        return
    turn["player"] = "O" if turn["player"] == "X" else "X"


for i in range(9):
    # lambda i=i remembers THIS button's number
    b = tk.Button(window, text="", font=("Arial", 32, "bold"), width=3, height=1, command=lambda i=i: clicked(i))
    b.grid(row=i // 3, column=i % 3)
    buttons.append(b)

tk.Button(window, text="Restart", command=reset).grid(row=3, column=0, columnspan=3, sticky="we")
window.mainloop()
