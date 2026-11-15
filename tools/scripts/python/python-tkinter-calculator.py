# @title Tkinter Calculator
# @category Tools
# @kind Console program
# @where Save as calculator.py and run: python3 calculator.py on a computer (tkinter comes with Python).
# @keywords python tkinter calculator, tkinter button grid, tkinter entry box, python gui calculator
# @about A calculator app with a window and clickable buttons that does safe math without using eval.

import ast
import operator
import tkinter as tk

# A safe mini math reader: only numbers and + - * / are allowed (eval could run any code!)
OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul, ast.Div: operator.truediv}


def calculate(node):
    if isinstance(node, ast.Expression):
        return calculate(node.body)
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return node.value
    if isinstance(node, ast.BinOp) and type(node.op) in OPS:
        return OPS[type(node.op)](calculate(node.left), calculate(node.right))
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
        return -calculate(node.operand)
    raise ValueError("not allowed")


def press(key):
    if key == "C":
        display.set("")
    elif key == "=":
        try:
            result = calculate(ast.parse(display.get(), mode="eval"))
            display.set(f"{result:g}")
        except (ValueError, SyntaxError, ZeroDivisionError):
            display.set("Error")
    else:
        display.set(display.get().replace("Error", "") + key)


window = tk.Tk()
window.title("Calculator")
display = tk.StringVar()
tk.Entry(window, textvariable=display, font=("Arial", 24), justify="right", width=14).grid(row=0, column=0, columnspan=4, pady=6)

KEYS = ["7", "8", "9", "/", "4", "5", "6", "*", "1", "2", "3", "-", "C", "0", ".", "+"]
for i, key in enumerate(KEYS):
    tk.Button(window, text=key, font=("Arial", 18), width=4, height=2,
              command=lambda k=key: press(k)).grid(row=1 + i // 4, column=i % 4)
tk.Button(window, text="=", font=("Arial", 18), height=2, command=lambda: press("=")).grid(
    row=5, column=0, columnspan=4, sticky="we")
window.mainloop()
