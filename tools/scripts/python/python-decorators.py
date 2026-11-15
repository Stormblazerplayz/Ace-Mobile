# @title Decorators
# @category Basics
# @kind Console program
# @where Save as decorators.py and run: python3 decorators.py
# @keywords python decorator, python wrapper function, python timer decorator, python @ syntax
# @about Makes two decorators that wrap other functions: one that times them and one that announces them.

import functools
import time


def timer(func):
    """Measures how long the function takes."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        print(f"  {func.__name__} took {time.perf_counter() - start:.4f} seconds")
        return result
    return wrapper


def announce(func):
    """Prints a message before and after the function runs."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        print(f"Starting {func.__name__}...")
        result = func(*args, **kwargs)
        print(f"Finished {func.__name__}!")
        return result
    return wrapper


# Putting @timer on top is the same as writing: add_numbers = timer(add_numbers)
@timer
def add_numbers(limit):
    return sum(range(limit))


@announce
@timer
def make_greeting(name):
    time.sleep(0.2)
    return f"Hey {name}!"


print("Sum:", add_numbers(1_000_000))
print(make_greeting("Storm"))
