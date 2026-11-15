# @title Fraction Calculator
# @category Math and school
# @kind Console program
# @where Save as fractions_calc.py and run: python3 fractions_calc.py, then type math like 1/2 + 3/4
# @keywords python fractions, python fraction calculator, python simplify fraction, python mixed numbers
# @about Adds, subtracts, multiplies and divides fractions exactly and shows the answer as a mixed number.

from fractions import Fraction


def mixed(f):
    """Turn 7/4 into '1 3/4'."""
    whole, rest = divmod(abs(f.numerator), f.denominator)
    sign = "-" if f < 0 else ""
    if rest == 0:
        return f"{sign}{whole}"
    if whole == 0:
        return f"{sign}{rest}/{f.denominator}"
    return f"{sign}{whole} {rest}/{f.denominator}"


print("Type fraction math like: 1/2 + 3/4   or   2/3 * 9/10   (Enter to quit)")
while True:
    parts = input("> ").split()
    if not parts:
        break
    if len(parts) != 3 or parts[1] not in "+-*/":
        print("Use: fraction space operator space fraction")
        continue
    try:
        a, b = Fraction(parts[0]), Fraction(parts[2])
        result = {"+": a + b, "-": a - b, "*": a * b, "/": a / b if b else None}[parts[1]]
    except (ValueError, ZeroDivisionError):
        print("Those don't look like fractions.")
        continue
    if result is None:
        print("You can't divide by zero!")
        continue
    print(f"= {result}   (mixed number: {mixed(result)}, decimal: {float(result):.4g})")
