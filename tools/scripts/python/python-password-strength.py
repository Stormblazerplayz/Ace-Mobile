# @title Password Strength Checker
# @category Tools
# @kind Console program
# @where Save as strength.py and run: python3 strength.py
# @keywords python password strength, python password checker, python check uppercase digits, python getpass
# @about Rates how strong a password is and gives tips to make it better, without showing it on screen.

import getpass
import string

COMMON = {"password", "123456", "qwerty", "letmein", "iloveyou", "admin", "welcome", "monkey", "dragon"}


def check(password):
    tips = []
    points = 0
    if len(password) >= 12:
        points += 2
    elif len(password) >= 8:
        points += 1
    else:
        tips.append("Use at least 8 characters (12+ is better).")
    if any(c.islower() for c in password):
        points += 1
    else:
        tips.append("Add some lowercase letters.")
    if any(c.isupper() for c in password):
        points += 1
    else:
        tips.append("Add some UPPERCASE letters.")
    if any(c.isdigit() for c in password):
        points += 1
    else:
        tips.append("Add a number.")
    if any(c in string.punctuation for c in password):
        points += 1
    else:
        tips.append("Add a symbol like ! or #.")
    if password.lower() in COMMON:
        points = 0
        tips.insert(0, "This is one of the most common passwords. Hackers try it first!")
    return points, tips


# getpass hides what you type (some editors still show it)
password = getpass.getpass("Type a password to test: ")
points, tips = check(password)
rating = ["Very weak", "Very weak", "Weak", "Okay", "Good", "Strong", "Super strong"][points]
print(f"Strength: {rating} ({points}/6)")
for tip in tips:
    print(" -", tip)
