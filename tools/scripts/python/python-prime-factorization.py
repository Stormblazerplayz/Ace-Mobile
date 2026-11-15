# @title Prime Factorization
# @category Math and school
# @kind Console program
# @where Save as factors.py and run: python3 factors.py
# @keywords python prime factorization, python factor tree, python prime factors, python exponents
# @about Breaks any number into its prime factors and draws a simple factor tree.

from collections import Counter


def prime_factors(n):
    factors = []
    d = 2
    while d * d <= n:
        while n % d == 0:   # divide by d as many times as we can
            factors.append(d)
            n //= d
        d += 1
    if n > 1:
        factors.append(n)   # whatever is left is prime
    return factors


text = input("Number to factor (Enter for 360): ").strip()
n = int(text) if text.isdigit() and int(text) > 1 else 360
factors = prime_factors(n)

# Factor tree: keep splitting off the smallest prime
print("\nFactor tree:")
remaining = n
for depth, p in enumerate(factors):
    print("   " * depth + f"{remaining}")
    print("   " * depth + f"|- {p}")
    remaining //= p

counts = Counter(factors)
pretty = " x ".join(f"{p}^{c}" if c > 1 else str(p) for p, c in sorted(counts.items()))
print(f"\n{n} = {' x '.join(map(str, factors))}")
print(f"With exponents: {n} = {pretty}")
print("It is prime!" if len(factors) == 1 else f"It has {len(factors)} prime factors ({len(counts)} different ones).")
