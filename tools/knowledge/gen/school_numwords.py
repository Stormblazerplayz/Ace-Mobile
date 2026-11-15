#!/usr/bin/env python3
"""Writes number-writing facts to data/school/gen_math_numwords.txt:
    numbers written in words (0 to 100, hundreds, and big round numbers), US style
    ordinal numbers written in words (1st to 31st for dates, then tens, 100th, 1000th)
    whole numbers written in binary (base 2) and a few in hexadecimal (base 16), with the place values

Source: no outside data. The words follow standard US English number spelling (hyphens from 21 to 99,
no "and" after hundred). Binary and hex values are computed here. Public domain facts, no license needed.

Run from the repo root:  python3 tools/knowledge/gen/school_numwords.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from school_math import KNOW, Writer, load_taken  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_math_numwords.txt")

ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = {2: "twenty", 3: "thirty", 4: "forty", 5: "fifty", 6: "sixty", 7: "seventy", 8: "eighty", 9: "ninety"}

ORD_ONES = {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 7: "seventh",
            8: "eighth", 9: "ninth", 10: "tenth", 11: "eleventh", 12: "twelfth", 13: "thirteenth",
            14: "fourteenth", 15: "fifteenth", 16: "sixteenth", 17: "seventeenth", 18: "eighteenth",
            19: "nineteenth"}

# extra tip for numbers whose spelling trips people up
NUM_TIP = {
    4: "Four keeps its u in fourteen but drops it in forty.",
    14: "It keeps the u from four, unlike forty.",
    40: "There is no u in forty, even though four has one.",
    5: "In fifteen and fifty, five changes to fif.",
    15: "Five changes to fif, as in fifty.",
    50: "Five changes to fif, as in fifteen.",
    8: "Eighteen has only one t, and eighty has one t too.",
    18: "There is only one t in the middle, not two.",
    80: "There is only one t: eight plus y.",
    9: "Nine keeps its e in nineteen and ninety, but not in ninth.",
    19: "It keeps the e from nine.",
    90: "It keeps the e from nine, unlike ninth.",
    3: "In thirteen and thirty, three changes to thir.",
    13: "Three changes to thir, as in thirty.",
    30: "Three changes to thir, as in thirteen.",
    2: "Watch the homophones: two is the number, to and too are different words.",
    12: "Twelve is one of the irregular number words, like eleven.",
    11: "Eleven and twelve are irregular; the teen pattern starts at thirteen.",
    0: "Zero is also called nought or oh, as in a phone number.",
}

ORD_TIP = {
    1: "First, second and third are irregular. From fourth on, most ordinals just add th.",
    2: "First, second and third are irregular. From fourth on, most ordinals just add th.",
    3: "First, second and third are irregular. From fourth on, most ordinals just add th.",
    5: "The ve in five changes to f.",
    8: "Eight just adds h, so there is only one t.",
    9: "Nine drops its e: ninth, not nineth.",
    12: "The ve in twelve changes to f.",
    20: "For tens, change the y to ie and add th.",
}


def words(n):
    if n < 20:
        return ONES[n]
    if n < 100:
        t, o = divmod(n, 10)
        return TENS[t] + ("" if o == 0 else "-" + ONES[o])
    if n < 1000:
        h, r = divmod(n, 100)
        return ONES[h] + " hundred" + ("" if r == 0 else " " + words(r))
    for size, name in ((10 ** 9, "billion"), (10 ** 6, "million"), (1000, "thousand")):
        if n >= size:
            a, r = divmod(n, size)
            return words(a) + " " + name + ("" if r == 0 else " " + words(r))
    raise ValueError(n)


def ordinal_words(n):
    if n in ORD_ONES:
        return ORD_ONES[n]
    if n < 100:
        t, o = divmod(n, 10)
        if o == 0:
            return TENS[t][:-1] + "ieth"
        return TENS[t] + "-" + ORD_ONES[o]
    if n == 100:
        return "one hundredth"
    if n == 1000:
        return "one thousandth"
    raise ValueError(n)


def suffix(n):
    if 10 <= n % 100 <= 20:
        return "th"
    return {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")


def numbers_block(w):
    w.tag("school.math.number-words")
    nums = list(range(0, 101)) + list(range(200, 1001, 100)) + [101, 110, 150, 250, 500, 999, 1001,
                                                               1500, 2000, 5000, 10000, 100000, 1000000,
                                                               1000000000]
    seen = set()
    for n in nums:
        if n in seen:
            continue
        seen.add(n)
        wd = words(n)
        shown = f"{n:,}"
        qs = [f"how do you write {n} in words", f"{n} in words", f"how do you spell {n}",
              f"what is {n} in words"]
        ans = f'The number {shown} is written "{wd}" in words.'
        if n in NUM_TIP:
            ans += " " + NUM_TIP[n]
        elif 21 <= n <= 99 and n % 10:
            ans += " Numbers from 21 to 99 that aren't whole tens get a hyphen."
        elif 100 < n < 1000 and n % 100:
            ans += ' In US English there is no "and" after hundred; in British English people say "' + \
                   wd.replace("hundred ", "hundred and ") + '".'
        elif n in (200, 300, 500, 900):
            ans += " Hundred doesn't take an s after a number: five hundred, not five hundreds."
        elif n >= 10000:
            ans += f" It has {len(str(n)) - 1} zeros."
        w.add(qs, ans)


def ordinals_block(w):
    w.tag("school.math.ordinal-words")
    for n in list(range(1, 32)) + [40, 50, 60, 70, 80, 90, 100, 1000]:
        o = f"{n}{suffix(n)}"
        wd = ordinal_words(n)
        qs = [f"how do you write {o} in words", f"{o} in words", f"how do you spell {o}",
              f"what is {o} written out"]
        ans = f'The ordinal {o} is written "{wd}".'
        if n in ORD_TIP:
            ans += " " + ORD_TIP[n]
        elif 21 <= n <= 99 and n % 10:
            ans += f" Only the last part changes: {words(n)} becomes {wd}."
        elif n % 10 == 0 and 30 <= n <= 90:
            ans += " For tens, change the y to ie and add th."
        w.add(qs, ans)


def binary_block(w):
    w.tag("school.math.binary")
    nums = list(range(0, 33)) + [50, 64, 100, 127, 128, 200, 255, 256, 1000, 1024]
    for n in nums:
        b = bin(n)[2:]
        qs = [f"what is {n} in binary", f"{n} in binary", f"convert {n} to binary",
              f"how do you write {n} in binary"]
        if n < 2:
            ans = f"In binary, {n} is written {n}, the same as in our usual base 10."
        else:
            parts = [str(2 ** i) for i, d in enumerate(reversed(b)) if d == "1"][::-1]
            if len(parts) == 1:
                ans = (f"In binary, {n:,} is written {b}. It's a power of 2, so it's a 1 followed by "
                       f"{len(b) - 1} zero{'s' if len(b) > 2 else ''}.")
            elif set(b) == {"1"}:
                ans = (f"In binary, {n:,} is written {b}, one less than {n + 1:,}. A number made of "
                       f"all 1s in binary is always one less than a power of 2.")
            elif len(parts) <= 6:
                ans = f"In binary, {n:,} is written {b}, because {' + '.join(parts)} = {n:,}."
            else:
                ans = f"In binary, {n:,} is written {b}."
        w.add(qs, ans)

    w.tag("school.math.hexadecimal")
    for n in [10, 11, 12, 13, 14, 15, 16, 20, 32, 100, 255, 256]:
        h = format(n, "X")
        qs = [f"what is {n} in hexadecimal", f"{n} in hex", f"convert {n} to hex",
              f"how do you write {n} in hex"]
        if n < 16:
            ans = (f"In hexadecimal (base 16), {n} is written {h}. Hex uses 0 to 9, then A to F "
                   f"for 10 to 15.")
        else:
            hi, lo = divmod(n, 16)
            if n < 256:
                ans = (f"In hexadecimal (base 16), {n} is written {h}, because {hi} × 16 + {lo} = {n}. "
                       f"Hex uses 0 to 9 and A to F for 10 to 15.")
            else:
                ans = (f"In hexadecimal (base 16), {n} is written {h}. Hex place values are 1, 16 and 256, "
                       f"so 100 means one 256.")
        w.add(qs, ans)


def main():
    taken, keys = load_taken({os.path.abspath(OUT)})
    w = Writer(taken, keys)
    numbers_block(w)
    ordinals_block(w)
    binary_block(w)
    head = ("# Generated by tools/knowledge/gen/school_numwords.py (standard US number spelling; "
            "binary and hex computed).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n = w.write(OUT, head)
    print(f"wrote {n} entries to gen_math_numwords.txt")


if __name__ == "__main__":
    main()
