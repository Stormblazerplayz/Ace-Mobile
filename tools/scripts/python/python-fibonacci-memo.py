# @title Fibonacci with Memory
# @category Basics
# @kind Console program
# @where Save as fib.py and run: python3 fib.py
# @keywords python fibonacci, python memoization, python lru_cache, python fast recursion
# @about Compares a slow recursive Fibonacci with a fast one that remembers answers using a cache.

import time
from functools import lru_cache


def slow_fib(n):
    # Calls itself twice each time, so it repeats a LOT of work.
    if n < 2:
        return n
    return slow_fib(n - 1) + slow_fib(n - 2)


@lru_cache(maxsize=None)
def fast_fib(n):
    # Same code, but lru_cache remembers every answer it has already worked out.
    if n < 2:
        return n
    return fast_fib(n - 1) + fast_fib(n - 2)


start = time.perf_counter()
print("slow_fib(27) =", slow_fib(27))
print(f"  took {time.perf_counter() - start:.3f} seconds")

start = time.perf_counter()
print("fast_fib(27) =", fast_fib(27))
print(f"  took {time.perf_counter() - start:.6f} seconds")

print("fast_fib(200) =", fast_fib(200))
print("First 15 numbers:", [fast_fib(i) for i in range(15)])
