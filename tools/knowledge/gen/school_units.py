#!/usr/bin/env python3
"""Writes measurement and number-form facts to data/school/gen_math_units.txt:
    unit conversions (US customary, metric, time, area, volume) with how to convert both ways
    common fractions as decimals and percents, with the method

Source: no outside data. Conversion factors are the standard exact definitions (for example
1 inch = 2.54 cm exactly, 1 mile = 5,280 feet); the few customary-to-metric factors that are not
whole numbers are given as "about" values rounded from those exact definitions. Fractions are
computed here. Public domain facts, no license needed.

Run from the repo root:  python3 tools/knowledge/gen/school_units.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import os
import sys
from fractions import Fraction
from math import gcd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from school_math import KNOW, Writer, load_taken  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_math_units.txt")

# big unit, its plural, small unit, its plural, how many smalls in one big
EXACT = [
    # length, US customary
    ("foot", "feet", "inch", "inches", 12),
    ("yard", "yards", "foot", "feet", 3),
    ("yard", "yards", "inch", "inches", 36),
    ("mile", "miles", "foot", "feet", 5280),
    ("mile", "miles", "yard", "yards", 1760),
    # length, metric
    ("meter", "meters", "centimeter", "centimeters", 100),
    ("meter", "meters", "millimeter", "millimeters", 1000),
    ("centimeter", "centimeters", "millimeter", "millimeters", 10),
    ("kilometer", "kilometers", "meter", "meters", 1000),
    ("kilometer", "kilometers", "centimeter", "centimeters", 100000),
    # weight / mass
    ("pound", "pounds", "ounce", "ounces", 16),
    ("ton", "tons", "pound", "pounds", 2000),
    ("kilogram", "kilograms", "gram", "grams", 1000),
    ("gram", "grams", "milligram", "milligrams", 1000),
    ("metric ton", "metric tons", "kilogram", "kilograms", 1000),
    # liquid volume, US customary
    ("gallon", "gallons", "quart", "quarts", 4),
    ("gallon", "gallons", "pint", "pints", 8),
    ("gallon", "gallons", "cup", "cups", 16),
    ("gallon", "gallons", "fluid ounce", "fluid ounces", 128),
    ("quart", "quarts", "pint", "pints", 2),
    ("quart", "quarts", "cup", "cups", 4),
    ("quart", "quarts", "fluid ounce", "fluid ounces", 32),
    ("pint", "pints", "cup", "cups", 2),
    ("pint", "pints", "fluid ounce", "fluid ounces", 16),
    ("cup", "cups", "fluid ounce", "fluid ounces", 8),
    ("cup", "cups", "tablespoon", "tablespoons", 16),
    ("cup", "cups", "teaspoon", "teaspoons", 48),
    ("tablespoon", "tablespoons", "teaspoon", "teaspoons", 3),
    # volume, metric
    ("liter", "liters", "milliliter", "milliliters", 1000),
    ("liter", "liters", "cubic centimeter", "cubic centimeters", 1000),
    ("cubic meter", "cubic meters", "liter", "liters", 1000),
    ("cubic foot", "cubic feet", "cubic inch", "cubic inches", 1728),
    ("cubic yard", "cubic yards", "cubic foot", "cubic feet", 27),
    # area
    ("square foot", "square feet", "square inch", "square inches", 144),
    ("square yard", "square yards", "square foot", "square feet", 9),
    ("acre", "acres", "square foot", "square feet", 43560),
    ("square mile", "square miles", "acre", "acres", 640),
    ("hectare", "hectares", "square meter", "square meters", 10000),
    ("square meter", "square meters", "square centimeter", "square centimeters", 10000),
    ("square kilometer", "square kilometers", "hectare", "hectares", 100),
    # time
    ("minute", "minutes", "second", "seconds", 60),
    ("hour", "hours", "minute", "minutes", 60),
    ("hour", "hours", "second", "seconds", 3600),
    ("day", "days", "hour", "hours", 24),
    ("day", "days", "minute", "minutes", 1440),
    ("day", "days", "second", "seconds", 86400),
    ("week", "weeks", "day", "days", 7),
    ("week", "weeks", "hour", "hours", 168),
    ("fortnight", "fortnights", "day", "days", 14),
    ("year", "years", "month", "months", 12),
    ("decade", "decades", "year", "years", 10),
    ("century", "centuries", "year", "years", 100),
    ("millennium", "millennia", "year", "years", 1000),
    ("century", "centuries", "decade", "decades", 10),
]

# Customary <-> metric: exact or "about" values, written out by hand from the exact definitions.
CROSS = [
    (["how many centimeters in an inch", "inches to centimeters", "how many cm is an inch"],
     "One inch is exactly 2.54 centimeters. Multiply inches by 2.54 to get centimeters, or divide centimeters by 2.54 to get inches."),
    (["how many centimeters in a foot", "feet to centimeters", "how many cm is a foot"],
     "One foot is exactly 30.48 centimeters. Multiply feet by 30.48 to get centimeters."),
    (["how many meters in a yard", "yards to meters", "is a yard longer than a meter"],
     "One yard is exactly 0.9144 meters, so a meter is a little longer than a yard (about 1.09 yards)."),
    (["how many feet in a meter", "meters to feet", "how many feet is a meter"],
     "One meter is about 3.28 feet, or about 39.37 inches. Multiply meters by 3.28 to get feet."),
    (["how many kilometers in a mile", "miles to kilometers", "how many km is a mile"],
     "One mile is about 1.609 kilometers. Multiply miles by 1.609 to get kilometers; one kilometer is about 0.62 miles."),
    (["how many pounds in a kilogram", "kilograms to pounds", "how many pounds is a kilo"],
     "One kilogram is about 2.2 pounds (2.2046). Multiply kilograms by 2.2 to get pounds, or divide pounds by 2.2 to get kilograms."),
    (["how many grams in a pound", "pounds to grams", "how many grams is a pound"],
     "One pound is about 454 grams (453.59). A kilogram is about 2.2 pounds."),
    (["how many grams in an ounce", "ounces to grams", "how many grams is an ounce"],
     "One ounce (weight) is about 28.35 grams. Multiply ounces by 28.35 to get grams."),
    (["how many liters in a gallon", "gallons to liters", "how many liters is a gallon"],
     "One US gallon is about 3.785 liters. Multiply gallons by 3.785 to get liters."),
    (["how many quarts in a liter", "liters to quarts", "is a liter bigger than a quart"],
     "One liter is about 1.057 US quarts, so a liter is a little bigger than a quart."),
    (["how many milliliters in a teaspoon", "teaspoon in ml", "how many ml is a teaspoon"],
     "A US teaspoon is about 4.93 milliliters, usually rounded to 5 mL. A tablespoon is about 15 mL."),
    (["how many milliliters in a cup", "cup in ml", "how many ml is a cup"],
     "A US cup is about 237 milliliters, often rounded to 240 mL. A metric cup, used in some countries, is 250 mL."),
    (["how many acres in a hectare", "hectares to acres", "is a hectare bigger than an acre"],
     "One hectare is about 2.47 acres, so a hectare is bigger. A hectare is 10,000 square meters."),
]


def comma(n):
    return f"{n:,}"


def article(word):
    return "an" if word[0] in "aeiou" else "a"


def units(w):
    w.tag("school.math.units")
    for big, bigs, small, smalls, k in EXACT:
        a = article(big)
        qs = [f"how many {smalls} in {a} {big}", f"how many {smalls} are in {a} {big}",
              f"how many {smalls} make {a} {big}", f"{bigs} to {smalls}",
              f"how many {smalls} is {a} {big}"]
        ans = (f"There are {comma(k)} {smalls} in {a} {big}. To change {bigs} to {smalls}, multiply by {comma(k)}; "
               f"to change {smalls} to {bigs}, divide by {comma(k)}.")
        if big == "year" and small == "month":
            ans += " A year also has 52 weeks plus 1 day (2 in a leap year)."
        if big == "ton":
            ans = ans.replace(f"There are 2,000 pounds in a ton.", "There are 2,000 pounds in a US ton (a short ton).") + \
                  " A metric ton is 1,000 kilograms, about 2,205 pounds."
        if big == "fortnight":
            ans = "A fortnight is 14 days, or two weeks. The word comes from Old English for \"fourteen nights\"."
        w.add(qs, ans)
    for qs, ans in CROSS:
        w.add(qs, ans)


def frac_word(f):
    return f"{f.numerator}/{f.denominator}"


def decimal_str(f):
    """Exact decimal, or the repeating form with a bar note."""
    n, d = f.numerator, f.denominator
    dd = d
    while dd % 2 == 0:
        dd //= 2
    while dd % 5 == 0:
        dd //= 5
    if dd == 1:
        s = f"{n / d:.6f}".rstrip("0")
        return s, None
    # repeating: build digits by long division
    digits, rems, r = "", {}, n % d
    while r and r not in rems:
        rems[r] = len(digits)
        r *= 10
        digits += str(r // d)
        r %= d
    start = rems[r]
    nonrep, rep = digits[:start], digits[start:]
    shown = "0." + nonrep + rep * (3 if len(rep) == 1 else 2)
    return shown + "...", rep


def percent_str(f):
    p = f * 100
    if p.denominator == 1:
        return f"{p.numerator}%"
    whole = p.numerator // p.denominator
    rest = Fraction(p.numerator % p.denominator, p.denominator)
    if rest.denominator in (2, 4, 5, 8, 10):
        return f"{float(p):g}%"
    return f"{whole} {rest.numerator}/{rest.denominator}%, about {float(p):.1f}%"


def fractions_block(w):
    w.tag("school.math.fraction-equivalents")
    for d in range(2, 13):
        for n in range(1, d):
            if gcd(n, d) != 1:
                continue
            f = Fraction(n, d)
            dec, rep = decimal_str(f)
            pc = percent_str(f)
            fw = frac_word(f)
            qs = [f"what is {fw} as a decimal", f"{fw} as a percent", f"what percent is {fw}",
                  f"{fw} in decimal form"]
            if rep:
                ans = (f"{fw} = {dec}, a repeating decimal (the {rep} repeats forever), which is {pc}. "
                       f"You get it by dividing {n} by {d}.")
            else:
                ans = f"{fw} = {dec} = {pc}. You get the decimal by dividing {n} by {d}, then multiply by 100 for the percent."
            w.add(qs, ans[0].upper() + ans[1:] if not ans[0].isdigit() else "The fraction " + ans)


def main():
    taken, keys = load_taken({os.path.abspath(OUT)})
    w = Writer(taken, keys)
    units(w)
    fractions_block(w)
    head = ("# Generated by tools/knowledge/gen/school_units.py (standard unit definitions and computed fractions).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n = w.write(OUT, head)
    print(f"wrote {n} entries to gen_math_units.txt")


if __name__ == "__main__":
    main()
