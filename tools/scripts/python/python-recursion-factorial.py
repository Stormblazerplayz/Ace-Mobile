# @title Recursion: Factorial and Countdown
# @category Basics
# @kind Console program
# @where Save as recursion.py and run: python3 recursion.py
# @keywords python recursion, python factorial, python recursive function, python base case
# @about Explains recursion (a function calling itself) with factorial, countdown and sum of digits.

# Every recursive function needs a BASE CASE (when to stop)
# and a RECURSIVE CASE (call itself with a smaller problem).

def factorial(n):
    if n <= 1:          # base case
        return 1
    return n * factorial(n - 1)  # recursive case


def countdown(n):
    if n == 0:
        print("Blast off!")
        return
    print(n)
    countdown(n - 1)


def sum_of_digits(n):
    if n < 10:
        return n
    return n % 10 + sum_of_digits(n // 10)


def reverse(text):
    if text == "":
        return ""
    return reverse(text[1:]) + text[0]


for i in range(1, 8):
    print(f"{i}! = {factorial(i)}")

countdown(5)
print("Sum of digits of 98765:", sum_of_digits(98765))
print("Reverse of 'recursion':", reverse("recursion"))
