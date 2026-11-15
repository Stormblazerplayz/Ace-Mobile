# @title Sieve of Eratosthenes
# @category Math and school
# @kind Console program
# @where Save as sieve.py and run: python3 sieve.py
# @keywords python sieve of eratosthenes, python find all primes, python prime list fast, python ancient algorithm
# @about Finds every prime number up to a limit super fast using a 2000 year old trick.

limit_text = input("Find all primes up to (Enter for 100): ").strip()
limit = int(limit_text) if limit_text.isdigit() and int(limit_text) >= 2 else 100

# Start by assuming every number is prime, then cross off the multiples
is_prime = [True] * (limit + 1)
is_prime[0] = is_prime[1] = False
for n in range(2, int(limit ** 0.5) + 1):
    if is_prime[n]:
        # Cross off n*n, n*n + n, n*n + 2n ... (smaller multiples were already crossed off)
        for multiple in range(n * n, limit + 1, n):
            is_prime[multiple] = False

primes = [n for n, prime in enumerate(is_prime) if prime]
print(f"There are {len(primes)} primes up to {limit}.")
if len(primes) <= 200:
    for i in range(0, len(primes), 10):
        print("  " + " ".join(f"{p:>5}" for p in primes[i:i + 10]))
else:
    print("The last ten are:", primes[-10:])

# Twin primes are pairs that are 2 apart, like 11 and 13
twins = [(p, p + 2) for p in primes if p + 2 <= limit and is_prime[p + 2]]
print(f"Twin prime pairs: {len(twins)}, for example {twins[:5]}")
