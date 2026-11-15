# @title Hello, Your Name
# @category Basics
# @kind Console program
# @where Save as hello.py and run: python3 hello.py
# @keywords python hello world, python input name, python first program, python greet user
# @about Asks for your name and favorite color, then says hello in a friendly way.

# input() shows a question and waits for you to type an answer.
name = input("What is your name? ").strip()

# If they just pressed Enter, use a fallback name.
if name == "":
    name = "mystery coder"

color = input("What is your favorite color? ").strip().lower()

# print() shows text on the screen. f-strings put variables inside {curly braces}.
print(f"Hello, {name}!")
print(f"Your name has {len(name)} letters.")

if color == "blue":
    print("Blue is a great color. Same as the sky!")
elif color == "":
    print("No favorite color? That's okay too.")
else:
    print(f"{color.capitalize()} is an awesome color.")

print("Welcome to Python!")
