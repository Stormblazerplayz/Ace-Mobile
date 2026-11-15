# @title Match and Case
# @category Basics
# @kind Console program
# @where Save as match_case.py and run: python3 match_case.py (needs Python 3.10 or newer)
# @keywords python match case, python switch statement, python pattern matching, python command parser
# @about Uses match and case (Python's version of a switch) to understand simple game commands.

def handle(command):
    words = command.lower().split()
    match words:
        case []:
            return "You didn't type anything."
        case ["look"]:
            return "You see a dark forest and a shiny key."
        case ["go", direction] if direction in ("north", "south", "east", "west"):
            return f"You walk {direction}."
        case ["go", _]:
            return "You can only go north, south, east or west."
        case ["take", item]:
            return f"You pick up the {item}."
        case ["quit" | "exit"]:
            return "quit"
        case _:
            return "I don't understand that."


print("Try: look, go north, take key, quit")
while True:
    reply = handle(input("> "))
    if reply == "quit":
        print("Goodbye, adventurer!")
        break
    print(reply)
