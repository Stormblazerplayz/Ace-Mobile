# @title Generators and Yield
# @category Basics
# @kind Console program
# @where Save as generators.py and run: python3 generators.py
# @keywords python generator, python yield, python next function, python lazy sequence
# @about Shows how yield makes functions that hand out values one at a time, even forever.

def count_up_to(limit):
    n = 1
    while n <= limit:
        yield n       # hand back one value, then pause here until asked for the next
        n += 1


def fibonacci():
    a, b = 0, 1
    while True:      # an endless generator is fine, it only runs when asked
        yield a
        a, b = b, a + b


def countdown_words(start):
    for n in range(start, 0, -1):
        yield f"{n}..."
    yield "Go!"


print("Count up:", list(count_up_to(5)))

fib = fibonacci()
print("First 10 Fibonacci numbers:", [next(fib) for _ in range(10)])

for word in countdown_words(3):
    print(word)

# A generator expression looks like a list comprehension with () instead of []
total = sum(n * n for n in range(1, 1001))
print("Sum of squares 1 to 1000:", total)
