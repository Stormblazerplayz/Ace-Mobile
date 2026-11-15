# @title Try and Except
# @category Basics
# @kind Console program
# @where Save as errors.py and run: python3 errors.py
# @keywords python try except, python error handling, python exceptions, python valueerror, python finally
# @about Shows how to catch errors so your program keeps running instead of crashing.

def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        print("  You can't divide by zero!")
        return None


print("10 / 2 =", safe_divide(10, 2))
print("10 / 0 =", safe_divide(10, 0))

# Turning text into a number can fail, so we catch ValueError.
for text in ["42", "hello", "3.5", "7"]:
    try:
        number = int(text)
        print(f"'{text}' became the number {number}")
    except ValueError:
        print(f"'{text}' is not a whole number")

# else runs if there was no error. finally ALWAYS runs.
scores = {"Storm": 90}
try:
    score = scores["Doodle"]
except KeyError as error:
    print("No score saved for", error)
else:
    print("Score:", score)
finally:
    print("Done checking scores.")

# Keep asking until the input is good.
while True:
    answer = input("Type a number from 1 to 10: ")
    try:
        value = int(answer)
        if 1 <= value <= 10:
            print("Thanks! You picked", value)
            break
        print("That's not between 1 and 10.")
    except ValueError:
        print("That's not a number. Try again.")
