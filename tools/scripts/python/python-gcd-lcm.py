# @title GCD and LCM
# @category Math and school
# @kind Console program
# @where Save as gcd_lcm.py and run: python3 gcd_lcm.py
# @keywords python gcd, python lcm, python greatest common divisor, python euclid algorithm
# @about Finds the greatest common divisor and least common multiple of two numbers, showing Euclid's steps.

def gcd_with_steps(a, b):
    print(f"Euclid's algorithm for {a} and {b}:")
    while b != 0:
        print(f"  {a} = {a // b} x {b} + {a % b}")
        a, b = b, a % b   # replace the pair with (smaller, remainder)
    return a


text = input("Type two whole numbers (like 48 180): ").split()
if len(text) == 2 and all(t.isdigit() and int(t) > 0 for t in text):
    a, b = int(text[0]), int(text[1])
else:
    a, b = 48, 180
    print("Using the example 48 and 180.")

g = gcd_with_steps(max(a, b), min(a, b))
lcm = a * b // g
print(f"\nGreatest common divisor: {g}")
print(f"Least common multiple: {lcm}")
print(f"Simplified fraction {a}/{b} = {a // g}/{b // g}")
