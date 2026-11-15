# @title Tkinter To-Do App
# @category Tools
# @kind Console program
# @where Save as todo_app.py and run: python3 todo_app.py on a computer. Tasks save to todo_app.json.
# @keywords python tkinter to do app, tkinter listbox, tkinter save json, python gui task list
# @about A to-do list app with a window: type tasks, add them, double-click to mark done, and it saves automatically.

import json
import tkinter as tk
from pathlib import Path

FILE = Path(__file__).with_name("todo_app.json")
tasks = json.loads(FILE.read_text()) if FILE.exists() else []


def save_and_show():
    FILE.write_text(json.dumps(tasks, indent=2))
    listbox.delete(0, tk.END)
    for task in tasks:
        listbox.insert(tk.END, ("[done] " if task["done"] else "") + task["text"])


def add_task(event=None):
    text = entry.get().strip()
    if text:
        tasks.append({"text": text, "done": False})
        entry.delete(0, tk.END)
        save_and_show()


def toggle_done(event=None):
    for index in listbox.curselection():
        tasks[index]["done"] = not tasks[index]["done"]
    save_and_show()


def delete_selected():
    for index in reversed(listbox.curselection()):
        tasks.pop(index)
    save_and_show()


window = tk.Tk()
window.title("To-Do")
entry = tk.Entry(window, font=("Arial", 14), width=28)
entry.grid(row=0, column=0, padx=6, pady=6)
entry.bind("<Return>", add_task)  # pressing Enter also adds
tk.Button(window, text="Add", command=add_task).grid(row=0, column=1, padx=6)
listbox = tk.Listbox(window, font=("Arial", 14), width=34, height=12)
listbox.grid(row=1, column=0, columnspan=2, padx=6)
listbox.bind("<Double-Button-1>", toggle_done)
tk.Button(window, text="Delete selected", command=delete_selected).grid(row=2, column=0, columnspan=2, pady=6)
save_and_show()
window.mainloop()
