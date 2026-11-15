# @title Roman Numerals Converter
# @category Math and school
# @kind Console program
# @where Save as roman.py and run: python3 roman.py
# @keywords python roman numerals, python convert to roman, python roman to number, python history math
# @about Converts normal numbers into Roman numerals and Roman numerals back into numbers.

VALUES = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
          (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]


def to_roman(n):
    result = ""
    for value, letters in VALUES:  # biggest first
        while n >= value:
            result += letters
            n -= value
    return result


def from_roman(text):
    single = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    total = 0
    for i, ch in enumerate(text):
        value = single[ch]
        # A smaller letter before a bigger one is subtracted (IV = 4)
        if i + 1 < len(text) and single[text[i + 1]] > value:
            total -= value
        else:
            total += value
    return total


for year in [4, 9, 14, 40, 90, 400, 1999, 2026]:
    print(f"{year:>5} = {to_roman(year)}")

while True:
    text = input("\nNumber (1-3999) or Roman numeral (Enter to quit): ").strip().upper()
    if not text:
        break
    if text.isdigit() and 1 <= int(text) <= 3999:
        print(f"{text} = {to_roman(int(text))}")
    elif text and all(ch in "IVXLCDM" for ch in text) and to_roman(from_roman(text)) == text:
        print(f"{text} = {from_roman(text)}")
    else:
        print("That's not a valid number or Roman numeral.")
