# @title Code Breaker (Mastermind)
# @category Games
# @kind Console program
# @where Save as codebreaker.py and run: python3 codebreaker.py
# @keywords python mastermind, python code breaker, python bulls and cows, python logic puzzle
# @about Crack a secret 4 digit code using hints about right digits in the right and wrong places.

import random

DIGITS = "123456"
secret = [random.choice(DIGITS) for _ in range(4)]
print("Crack the 4 digit code! Digits are 1 to 6 and can repeat. You have 10 tries.")
print("Hint: 'exact' = right digit in the right place, 'close' = right digit, wrong place.")

for turn in range(1, 11):
    guess = input(f"\nTry {turn}: ").strip()
    while len(guess) != 4 or any(ch not in DIGITS for ch in guess):
        guess = input("Type 4 digits from 1 to 6: ").strip()
    exact = sum(g == s for g, s in zip(guess, secret))
    # count matching digits no matter where they are, then remove the exact ones
    common = sum(min(guess.count(d), secret.count(d)) for d in DIGITS)
    close = common - exact
    print(f"exact: {exact}   close: {close}")
    if exact == 4:
        print(f"Code cracked in {turn} tries!")
        break
else:
    print("Out of tries. The code was", "".join(secret))
