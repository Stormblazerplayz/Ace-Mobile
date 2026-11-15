# @title Variable Scope: Local and Global
# @category Basics
# @kind Console program
# @where Save as scope.py and run: python3 scope.py
# @keywords python scope, python global variable, python local variable, python nonlocal
# @about Explains where a variable can be seen, and why changing a global inside a function needs care.

score = 0  # a global variable: made outside any function


def show_score():
    # Reading a global inside a function is fine.
    print("Score is", score)


def add_points_wrong():
    points = 10  # a local variable: only exists inside this function
    print("Inside the function points =", points)


def add_points_global(amount):
    global score  # says "I mean the global score, not a new local one"
    score += amount


# A better way: pass values in and return the new value
def add_points(current, amount):
    return current + amount


def make_counter():
    count = 0

    def click():
        nonlocal count  # change count from the function around this one
        count += 1
        return count
    return click


show_score()
add_points_wrong()
add_points_global(5)
show_score()
score = add_points(score, 20)
show_score()

counter = make_counter()
counter()
counter()
print("Counter clicked", counter(), "times")
