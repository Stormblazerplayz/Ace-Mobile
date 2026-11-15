# @title Functions
# @category Basics
# @kind Console program
# @where Save as functions.py and run: python3 functions.py
# @keywords python functions, python def, python return value, python parameters
# @about Shows how to make your own functions with def, pass them values and get answers back with return.

# A function is a reusable chunk of code with a name.
def say_hi():
    print("Hi there!")


# Parameters are the inputs a function needs.
def greet(name):
    print(f"Hello, {name}!")


# return sends an answer back to whoever called the function.
def add(a, b):
    return a + b


def area_of_rectangle(width, height):
    return width * height


# A function can return True or False to answer a yes or no question.
def is_even(number):
    return number % 2 == 0


# A function can use other functions!
def describe(number):
    kind = "even" if is_even(number) else "odd"
    return f"{number} is {kind}"


say_hi()
greet("Storm")
greet("Doodle")
print("3 + 4 =", add(3, 4))
print("A 5 by 8 rectangle has area", area_of_rectangle(5, 8))
for n in range(1, 6):
    print(describe(n))
