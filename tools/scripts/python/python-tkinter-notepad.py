# @title Tkinter Notepad
# @category Tools
# @kind Console program
# @where Save as notepad.py and run: python3 notepad.py on a computer (tkinter comes with Python).
# @keywords python tkinter notepad, tkinter text editor, tkinter open save file, tkinter menu bar
# @about A simple text editor window with a menu to make, open and save text files, plus a word count.

import tkinter as tk
from tkinter import filedialog, messagebox

window = tk.Tk()
window.title("Notepad")
window.geometry("600x450")
current = {"path": None}

text = tk.Text(window, wrap="word", font=("Courier", 13), undo=True)
text.pack(fill="both", expand=True)
status = tk.Label(window, anchor="w")
status.pack(fill="x")


def update_status(event=None):
    words = len(text.get("1.0", "end").split())
    status.config(text=f"  {words} words   {current['path'] or 'Untitled'}")


def new_file():
    text.delete("1.0", "end")
    current["path"] = None
    update_status()


def open_file():
    path = filedialog.askopenfilename(filetypes=[("Text files", "*.txt *.md *.py"), ("All files", "*.*")])
    if path:
        with open(path, encoding="utf-8") as f:
            text.delete("1.0", "end")
            text.insert("1.0", f.read())
        current["path"] = path
        update_status()


def save_file():
    path = current["path"] or filedialog.asksaveasfilename(defaultextension=".txt")
    if path:
        with open(path, "w", encoding="utf-8") as f:
            f.write(text.get("1.0", "end-1c"))
        current["path"] = path
        update_status()
        messagebox.showinfo("Saved", "Your file was saved.")


menu = tk.Menu(window)
file_menu = tk.Menu(menu, tearoff=0)
file_menu.add_command(label="New", command=new_file)
file_menu.add_command(label="Open...", command=open_file)
file_menu.add_command(label="Save", command=save_file)
file_menu.add_separator()
file_menu.add_command(label="Quit", command=window.destroy)
menu.add_cascade(label="File", menu=file_menu)
window.config(menu=menu)

text.bind("<KeyRelease>", update_status)
update_status()
window.mainloop()
