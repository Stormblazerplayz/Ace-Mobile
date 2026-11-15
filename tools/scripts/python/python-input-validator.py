# @title Email and Phone Validator
# @category Tools
# @kind Console program
# @where Save as validator.py and run: python3 validator.py
# @keywords python regex, python validate email, python regular expressions, python phone number check
# @about Uses regular expressions (patterns for text) to check whether emails, phone numbers and usernames look right.

import re

PATTERNS = {
    # something @ something . something
    "email": re.compile(r"^[\w.+-]+@[\w-]+(\.[\w-]+)+$"),
    # 10 digits, with optional dashes, dots, spaces or brackets: 555-123-4567 or (555) 123 4567
    "phone": re.compile(r"^\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$"),
    # 3 to 16 letters, numbers or underscores, starting with a letter
    "username": re.compile(r"^[A-Za-z]\w{2,15}$"),
}

TESTS = ["storm@example.com", "not-an-email@", "555-123-4567", "(555) 123 4567", "12345",
         "storm_blazer", "1coolkid", "ab"]

for value in TESTS:
    kinds = [name for name, pattern in PATTERNS.items() if pattern.match(value)]
    print(f"{value:<20} -> {', '.join(kinds) if kinds else 'not valid for anything'}")

print("\nNow try your own! (Enter to quit)")
while True:
    value = input("Text: ").strip()
    if not value:
        break
    for name, pattern in PATTERNS.items():
        print(f"  {name:<9} {'yes' if pattern.match(value) else 'no'}")
