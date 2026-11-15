# @title Password Generator
# @category Tools
# @kind Console program
# @where Save as passgen.py and run: python3 passgen.py
# @keywords python password generator, python secrets module, python random password, python passphrase
# @about Makes strong random passwords and easy-to-remember passphrases using the secure secrets module.

import secrets
import string

WORDS = ["tiger", "rocket", "pizza", "cloud", "laser", "maple", "ninja", "ocean", "pixel", "storm",
         "comet", "banjo", "crystal", "falcon", "garden", "jungle", "lemon", "marble", "nebula", "quartz"]


def make_password(length=16, symbols=True):
    pool = string.ascii_letters + string.digits + ("!@#$%^&*?" if symbols else "")
    while True:
        # secrets is like random, but safe enough for real passwords
        password = "".join(secrets.choice(pool) for _ in range(length))
        # Make sure it has a lowercase, an uppercase and a digit
        if (any(c.islower() for c in password) and any(c.isupper() for c in password)
                and any(c.isdigit() for c in password)):
            return password


def make_passphrase(words=4):
    picked = [secrets.choice(WORDS) for _ in range(words)]
    return "-".join(picked) + str(secrets.randbelow(100))


text = input("Password length (press Enter for 16): ").strip()
length = int(text) if text.isdigit() and 8 <= int(text) <= 64 else 16
use_symbols = input("Include symbols? (y/n): ").strip().lower() != "n"

print("\nHere are 5 passwords. Pick one you like:")
for _ in range(5):
    print("  " + make_password(length, use_symbols))
print("\nOr an easier-to-remember passphrase:")
print("  " + make_passphrase())
print("\nTip: never share your passwords, and use a different one for every account.")
