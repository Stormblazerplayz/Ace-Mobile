# @title Long Division Step by Step
# @category Math and school
# @kind Console program
# @where Save as long_division.py and run: python3 long_division.py
# @keywords python long division, python division steps, python remainder, python homework helper
# @about Shows every step of long division just like on paper, ending with the answer and remainder.

text = input("Type the division like 7452 / 6: ").replace(" ", "").split("/")
if len(text) != 2 or not all(t.isdigit() for t in text) or int(text[1]) == 0:
    text = ["7452", "6"]
    print("Using the example 7452 / 6")
dividend, divisor = text[0], int(text[1])

quotient = ""
remainder = 0
step = 1
for digit in dividend:
    current = remainder * 10 + int(digit)   # bring down the next digit
    times = current // divisor
    remainder = current - times * divisor
    quotient += str(times)
    print(f"Step {step}: bring down {digit} -> {current}. "
          f"{divisor} goes into {current} {times} time(s). {times} x {divisor} = {times * divisor}. "
          f"Leftover: {remainder}")
    step += 1

quotient = quotient.lstrip("0") or "0"
print(f"\n{dividend} / {divisor} = {quotient} remainder {remainder}")
print(f"As a decimal: {int(dividend) / divisor:g}")
print(f"Check: {quotient} x {divisor} + {remainder} = {int(quotient) * divisor + remainder}")
