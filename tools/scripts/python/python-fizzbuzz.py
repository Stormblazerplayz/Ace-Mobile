# @title FizzBuzz
# @category Basics
# @kind Console program
# @where Save as fizzbuzz.py and run: python3 fizzbuzz.py
# @keywords python fizzbuzz, python modulo, python classic coding challenge, python divisible by
# @about The classic coding challenge: say Fizz for multiples of 3, Buzz for 5 and FizzBuzz for both.

# % gives the remainder. If n % 3 == 0, then n divides evenly by 3.
for n in range(1, 31):
    if n % 15 == 0:      # check both first!
        print("FizzBuzz")
    elif n % 3 == 0:
        print("Fizz")
    elif n % 5 == 0:
        print("Buzz")
    else:
        print(n)

# A shorter way that builds the word piece by piece.
# You can add new rules (like 7 = "Bazz") just by adding to the dictionary.
rules = {3: "Fizz", 5: "Buzz", 7: "Bazz"}
line = []
for n in range(1, 22):
    word = "".join(text for number, text in rules.items() if n % number == 0)
    line.append(word or str(n))
print(", ".join(line))
