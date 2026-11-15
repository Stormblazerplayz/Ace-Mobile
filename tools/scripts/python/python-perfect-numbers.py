# @title Perfect, Abundant and Deficient Numbers
# @category Math and school
# @kind Console program
# @where Save as perfect.py and run: python3 perfect.py
# @keywords python perfect numbers, python sum of divisors, python abundant numbers, python number types
# @about Sorts numbers by adding up their divisors: perfect numbers like 6 and 28 equal their own divisor sum.

def divisor_sum(n):
    """Add up all divisors smaller than n."""
    if n == 1:
        return 0
    total = 1
    d = 2
    while d * d <= n:
        if n % d == 0:
            total += d
            if d != n // d:
                total += n // d
        d += 1
    return total


perfect = [n for n in range(1, 10000) if divisor_sum(n) == n]
print("Perfect numbers under 10,000:", perfect)
for p in perfect:
    divisors = [d for d in range(1, p) if p % d == 0]
    print(f"  {p} = {' + '.join(map(str, divisors))}")

text = input("\nCheck your own number: ").strip()
if text.isdigit() and int(text) > 0:
    n = int(text)
    s = divisor_sum(n)
    kind = "PERFECT" if s == n else "abundant (divisors add up to more)" if s > n else "deficient (divisors add up to less)"
    print(f"{n}: divisors add up to {s}, so it is {kind}.")
