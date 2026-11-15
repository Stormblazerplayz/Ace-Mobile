# @title Numbers to Words
# @category Math and school
# @kind Console program
# @where Save as num_words.py and run: python3 num_words.py
# @keywords python number to words, python write numbers in english, python check writing, python spell numbers
# @about Spells out any whole number in English words, like 1234 becoming one thousand two hundred thirty-four.

ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
BIG = [(10 ** 12, "trillion"), (10 ** 9, "billion"), (10 ** 6, "million"), (1000, "thousand")]


def under_1000(n):
    words = []
    if n >= 100:
        words.append(ONES[n // 100] + " hundred")
        n %= 100
    if n >= 20:
        words.append(TENS[n // 10] + ("-" + ONES[n % 10] if n % 10 else ""))
    elif n > 0:
        words.append(ONES[n])
    return " ".join(words)


def to_words(n):
    if n == 0:
        return "zero"
    if n < 0:
        return "minus " + to_words(-n)
    parts = []
    for value, name in BIG:  # handle each big chunk, like the "millions" part
        if n >= value:
            parts.append(under_1000(n // value) + " " + name)
            n %= value
    if n:
        parts.append(under_1000(n))
    return " ".join(parts)


for example in [7, 15, 42, 100, 1234, 1000001, 987654321]:
    print(f"{example:>12,}: {to_words(example)}")

while True:
    text = input("\nYour number (Enter to quit): ").strip().replace(",", "")
    if not text:
        break
    if text.lstrip("-").isdigit() and abs(int(text)) < 10 ** 15:
        print(to_words(int(text)))
    else:
        print("Type a whole number.")
