# @title Variables and Types
# @category Basics
# @kind Console program
# @where Save as variables.py and run: python3 variables.py
# @keywords python variables, python data types, python int float string bool, python type function
# @about Shows the main kinds of values in Python (numbers, text, true or false) and how to change between them.

# A variable is a name that holds a value. Python figures out the type for you.
age = 12              # int: a whole number
height = 1.52         # float: a number with a decimal point
name = "Storm"        # str: text, always in quotes
likes_coding = True   # bool: True or False

print("age is", age, "and its type is", type(age).__name__)
print("height is", height, "and its type is", type(height).__name__)
print("name is", name, "and its type is", type(name).__name__)
print("likes_coding is", likes_coding, "and its type is", type(likes_coding).__name__)

# You can change a value from one type to another ("casting").
age_text = str(age)          # 12 becomes "12"
number = int("42")           # "42" becomes 42
price = float("3.99")        # "3.99" becomes 3.99
print("As text:", age_text + " years")
print("Text to number plus one:", number + 1)
print("Price doubled:", price * 2)

# Variables can change! That's why they are called variables.
score = 0
score = score + 10
score += 5  # short way to add
print("Score is now", score)

# Math with ints and floats
print("7 / 2 =", 7 / 2)    # normal division gives a float
print("7 // 2 =", 7 // 2)  # floor division drops the decimal
print("7 % 2 =", 7 % 2)    # remainder
print("2 ** 10 =", 2 ** 10)  # power
