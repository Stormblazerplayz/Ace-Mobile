# @title Prime Number Checker
# @category Math and school
# @kind Console program
# @where Save as primes.py and run: python3 primes.py
# @keywords python prime number, python is prime, python check divisors, python square root trick
# @about Checks whether a number is prime and, if not, shows what it can be divided by.

import math


def is_prime(n):
    if n < 2:
        return False
    if n < 4:
        return True       # 2 and 3 are prime
    if n % 2 == 0:
        return False
    # We only need to check odd divisors up to the square root of n
    for d in range(3, math.isqrt(n) + 1, 2):
        if n % d == 0:
            return False
    return True


def divisors(n):
    small = [d for d in range(1, math.isqrt(n) + 1) if n % d == 0]
    return sorted(set(small + [n // d for d in small]))


print("Primes under 100:", [n for n in range(100) if is_prime(n)])
while True:
    text = input("\nNumber to check (Enter to quit): ").strip()
    if not text:
        break
    if not text.isdigit():
        print("Type a whole number.")
        continue
    n = int(text)
    if is_prime(n):
        print(f"{n} is PRIME!")
    elif n < 2:
        print(f"{n} is not prime (primes start at 2).")
    else:
        print(f"{n} is not prime. Its divisors are: {divisors(n)}")
