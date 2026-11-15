# @title To-Do List (Saves to JSON)
# @category Tools
# @kind Console program
# @where Save as todo.py and run: python3 todo.py. Your list is saved in todo.json next to it.
# @keywords python to do list, python todo app, python save json, python task list
# @about A to-do list you can add to, tick off and delete from, saved in a JSON file so it remembers your tasks.

import json
from pathlib import Path

FILE = Path(__file__).with_name("todo.json")


def load():
    if FILE.exists():
        return json.loads(FILE.read_text())
    return []


def save(tasks):
    FILE.write_text(json.dumps(tasks, indent=2))


tasks = load()
print("Commands: add <task>, done <number>, del <number>, clear, quit")
while True:
    print("\n--- To-Do ---")
    if not tasks:
        print("(nothing to do!)")
    for i, task in enumerate(tasks, start=1):
        print(f"{i}. [{'x' if task['done'] else ' '}] {task['text']}")
    command, _, rest = input("> ").strip().partition(" ")
    command = command.lower()
    if command == "add" and rest:
        tasks.append({"text": rest, "done": False})
    elif command in ("done", "del") and rest.isdigit() and 1 <= int(rest) <= len(tasks):
        index = int(rest) - 1
        if command == "done":
            tasks[index]["done"] = not tasks[index]["done"]
        else:
            tasks.pop(index)
    elif command == "clear":
        tasks = [t for t in tasks if not t["done"]]  # remove finished tasks
    elif command == "quit":
        break
    else:
        print("Try: add buy milk, done 1, del 2, clear, quit")
    save(tasks)
print("Saved. See you later!")
