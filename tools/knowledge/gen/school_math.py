#!/usr/bin/env python3
"""Writes computed school math facts to data/school/:
    gen_math_numbers.txt  primes, factors, prime factorizations, Roman numerals (1 to 100, hundreds, and years 1900 to 2040)
    gen_math_shapes.txt   polygon names and angles, faces/edges/vertices of solids

Source: no outside data. Every answer is computed here from the number itself (trial division for primes and
factors, the standard Roman numeral rules) or from standard formulas (a polygon's angles add up to
(n - 2) x 180 degrees, a regular polygon's exterior angle is 360 / n, it has n(n - 3) / 2 diagonals).
Polygon and solid names are the usual English math names. Public domain facts, no license needed.

Run from the repo root:  python3 tools/knowledge/gen/school_math.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import glob
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, KNOW)
import check_data  # noqa: E402

OUT_DIR = os.path.join(KNOW, "data", "school")
OUT_NUM = os.path.join(OUT_DIR, "gen_math_numbers.txt")
OUT_SHAPE = os.path.join(OUT_DIR, "gen_math_shapes.txt")


# ---------- dedupe against the rest of the pack ----------

def load_taken(skip):
    taken = set(check_data.core_wordings())
    keys = {check_data.keyset(k) for k in taken if len(check_data.keyset(k)) >= 2}
    for path in glob.glob(os.path.join(KNOW, "data", "**", "*.txt"), recursive=True):
        if os.path.abspath(path) in skip:
            continue
        entries, _ = check_data.parse_txt(path)
        for _, _, qs, _ in entries:
            for q in qs:
                taken.add(check_data.norm(q))
                ks = check_data.keyset(q)
                if len(ks) >= 2:
                    keys.add(ks)
    return taken, keys


class Writer:
    def __init__(self, taken, keys):
        self.taken, self.keys = taken, keys
        self.blocks = []

    def tag(self, t):
        self.blocks.append((t, []))

    def add(self, qs, answer):
        ok = []
        for q in qs:
            n = check_data.norm(q)
            ks = check_data.keyset(q)
            if n in self.taken or (len(ks) >= 2 and ks in self.keys):
                continue
            if any(check_data.keyset(o) == ks and len(ks) >= 2 for o in ok):
                ok.append(q)  # same entry, same key set is fine
                continue
            ok.append(q)
        if len(ok) < 2:
            return
        for q in ok:
            self.taken.add(check_data.norm(q))
            ks = check_data.keyset(q)
            if len(ks) >= 2:
                self.keys.add(ks)
        self.blocks[-1][1].append((ok[:6], answer))

    def write(self, path, header):
        n = 0
        with open(path, "w", encoding="utf-8") as f:
            f.write(header)
            for t, items in self.blocks:
                if not items:
                    continue
                f.write(f"\n# tag: {t}\n")
                for qs, a in items:
                    f.write(" | ".join(qs) + " => " + a + "\n")
                    n += 1
        return n


# ---------- number facts ----------

def factors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


def is_prime(n):
    return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))


def prime_factors(n):
    out, d = [], 2
    while n > 1:
        while n % d == 0:
            out.append(d)
            n //= d
        d += 1
    return out


SUP = str.maketrans("0123456789", "⁰¹²³⁴⁵⁶⁷⁸⁹")


def exp_form(pf):
    parts = []
    for p in sorted(set(pf)):
        c = pf.count(p)
        parts.append(f"{p}" + (str(c).translate(SUP) if c > 1 else ""))
    return " × ".join(parts)


def join_list(xs):
    xs = [str(x) for x in xs]
    return xs[0] if len(xs) == 1 else ", ".join(xs[:-1]) + " and " + xs[-1]


def roman(n):
    vals = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    out = ""
    for v, s in vals:
        while n >= v:
            out += s
            n -= v
    return out


def numbers(w):
    w.tag("school.math.prime")
    for n in range(2, 201):
        qs = [f"is {n} prime", f"is {n} a prime number", f"is {n} prime or composite", f"is {n} composite"]
        if n == 2:
            a = "Yes, 2 is prime. It's the only even prime number, because every other even number can be divided by 2."
        elif is_prime(n):
            a = f"Yes, {n} is a prime number. Its only factors are 1 and {n}."
        else:
            pf = prime_factors(n)
            small = pf[0]
            a = (f"No, {n} is not prime, it's composite. It can be divided by {small} ({n} = {small} × {n // small}), "
                 f"and its prime factorization is {' × '.join(map(str, pf))}.")
        w.add(qs, a)

    w.tag("school.math.factors")
    for n in range(2, 151):
        fs = factors(n)
        qs = [f"what are the factors of {n}", f"factors of {n}", f"list all the factors of {n}",
              f"what numbers go into {n}"]
        if len(fs) == 2:
            a = f"The factors of {n} are just 1 and {n}, because {n} is a prime number."
        else:
            pairs = [f"{d} × {n // d}" for d in fs if d * d <= n]
            a = f"The factors of {n} are {join_list(fs)}. That's {len(fs)} factors, in the pairs {join_list(pairs)}."
            if len(a) > 340:
                a = f"The factors of {n} are {join_list(fs)}. That's {len(fs)} factors."
        w.add(qs, a)

    w.tag("school.math.prime-factorization")
    for n in range(4, 201):
        if is_prime(n):
            continue
        pf = prime_factors(n)
        qs = [f"what is the prime factorization of {n}", f"prime factorization of {n}", f"factor tree for {n}",
              f"write {n} as a product of primes", f"prime factors of {n}"]
        plain = " × ".join(map(str, pf))
        ef = exp_form(pf)
        a = f"The prime factorization of {n} is {plain}."
        if ef != plain:
            a += f" With exponents, that's {ef}."
        distinct = sorted(set(pf))
        a += f" Its prime factors are {join_list(distinct)}." if len(distinct) > 1 else f" Its only prime factor is {distinct[0]}."
        w.add(qs, a)

    w.tag("school.math.roman")
    nums = (list(range(1, 101)) + list(range(200, 1001, 100)) + [1500]
            + list(range(1900, 1990, 10)) + list(range(1990, 2041)))  # years people often ask about
    for n in nums:
        r = roman(n)
        qs = [f"what is {n} in roman numerals", f"{n} in roman numerals", f"how do you write {n} in roman numerals",
              f"what number is {r.lower()} in roman numerals"]
        how = ""
        if n > 3 and n not in (5, 10, 50, 100, 500, 1000):
            pieces = []
            m = n
            for v, s in [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"),
                         (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]:
                c = 0
                while m >= v:
                    m -= v
                    c += 1
                if c:
                    pieces.append((s * c, v * c))
            if len(pieces) > 1:
                how = " That's " + " + ".join(f"{s} ({v})" for s, v in pieces) + "."
        a = f"{n} is {r} in Roman numerals.{how}"
        w.add(qs, a)


# ---------- shapes ----------

POLY = {3: "triangle", 4: "quadrilateral", 5: "pentagon", 6: "hexagon", 7: "heptagon", 8: "octagon",
        9: "nonagon", 10: "decagon", 11: "hendecagon", 12: "dodecagon", 13: "tridecagon", 14: "tetradecagon",
        15: "pentadecagon", 16: "hexadecagon", 17: "heptadecagon", 18: "octadecagon", 19: "enneadecagon",
        20: "icosagon"}
ALSO = {7: "It's also called a septagon.", 9: "It's also called an enneagon.", 11: "It's also called an undecagon."}
WORDS = {3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten", 11: "eleven",
         12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen", 16: "sixteen", 17: "seventeen",
         18: "eighteen", 19: "nineteen", 20: "twenty"}


def fmt(x):
    if abs(x - round(x)) < 1e-9:
        return str(int(round(x)))
    return f"about {x:.2f}".rstrip("0").rstrip(".")


def art(word):
    return "an" if word[0] in "aeiou" else "a"


def shapes(w):
    w.tag("school.math.polygon")
    for n, name in POLY.items():
        a = f"A {n}-sided polygon is called {art(name)} {name}."
        if n in ALSO:
            a += " " + ALSO[n]
        if n == 4:
            a += " Squares, rectangles, rhombuses, parallelograms, kites and trapezoids are all quadrilaterals."
        w.add([f"what is a {n} sided shape called", f"what do you call a shape with {n} sides",
               f"name of a {WORDS[n]} sided polygon", f"what is a {WORDS[n]} sided shape called"], a)
        if n != 3:
            w.add([f"how many sides does {art(name)} {name} have", f"{name} sides", f"how many corners does {art(name)} {name} have",
                   f"what is {art(name)} {name}"],
                  f"{art(name).capitalize()} {name} has {n} sides and {n} corners (vertices). It's a polygon with {WORDS[n]} straight sides.")
        s = (n - 2) * 180
        w.add([f"what do the angles in {art(name)} {name} add up to", f"sum of interior angles of {art(name)} {name}",
               f"how many degrees are in {art(name)} {name}", f"interior angle sum of {art(name)} {name}"],
              f"The interior angles of any {name} add up to {s} degrees. That comes from ({n} - 2) × 180 = {s}.")
        if n <= 12 or n in (15, 20):
            each = s / n
            w.add([f"what is each angle of a regular {name}", f"interior angle of a regular {name}",
                   f"how big is one angle in a regular {name}"],
                  f"Each interior angle of a regular {name} is {fmt(each)} degrees. All {n} angles are equal and add up to {s}°, so it's {s} ÷ {n}.")
            w.add([f"exterior angle of a regular {name}", f"what is the exterior angle of a regular {name}",
                   f"outside angle of a regular {name}"],
                  f"Each exterior angle of a regular {name} is {fmt(360 / n)} degrees, because the exterior angles of any polygon add up to 360° and 360 ÷ {n} = {fmt(360 / n).replace('about ', '')}.")
        if n >= 4 and n <= 12:
            d = n * (n - 3) // 2
            w.add([f"how many diagonals does {art(name)} {name} have", f"number of diagonals in {art(name)} {name}",
                   f"diagonals of {art(name)} {name}"],
                  f"{art(name).capitalize()} {name} has {d} diagonals. The formula is n(n - 3) ÷ 2, so {n} × {n - 3} ÷ 2 = {d}.")

    w.tag("school.math.solid")
    solids = [  # name, faces, edges, vertices, face note
        ("cube", 6, 12, 8, "6 square faces"),
        ("rectangular prism", 6, 12, 8, "6 rectangle faces"),
        ("triangular prism", 5, 9, 6, "2 triangles and 3 rectangles"),
        ("pentagonal prism", 7, 15, 10, "2 pentagons and 5 rectangles"),
        ("hexagonal prism", 8, 18, 12, "2 hexagons and 6 rectangles"),
        ("octagonal prism", 10, 24, 16, "2 octagons and 8 rectangles"),
        ("square pyramid", 5, 8, 5, "1 square base and 4 triangles"),
        ("triangular pyramid", 4, 6, 4, "4 triangles"),
        ("pentagonal pyramid", 6, 10, 6, "1 pentagon base and 5 triangles"),
        ("hexagonal pyramid", 7, 12, 7, "1 hexagon base and 6 triangles"),
        ("tetrahedron", 4, 6, 4, "4 triangles"),
        ("octahedron", 8, 12, 6, "8 triangles"),
        ("dodecahedron", 12, 30, 20, "12 pentagons"),
        ("icosahedron", 20, 30, 12, "20 triangles"),
    ]
    for name, f, e, v, note in solids:
        a_ = art(name)
        tail = f"Faces + vertices - edges = {f} + {v} - {e} = 2, which is Euler's formula."
        w.add([f"how many faces does {a_} {name} have", f"{name} faces", f"number of faces on {a_} {name}"],
              f"{a_.capitalize()} {name} has {f} faces: {note}. It also has {e} edges and {v} vertices.")
        w.add([f"how many edges does {a_} {name} have", f"{name} edges", f"number of edges on {a_} {name}"],
              f"{a_.capitalize()} {name} has {e} edges. It also has {f} faces and {v} vertices. {tail}")
        w.add([f"how many vertices does {a_} {name} have", f"{name} vertices", f"how many corners does {a_} {name} have"],
              f"{a_.capitalize()} {name} has {v} vertices (corners). It also has {f} faces and {e} edges.")


def main():
    skip = {os.path.abspath(OUT_NUM), os.path.abspath(OUT_SHAPE)}
    taken, keys = load_taken(skip)
    w = Writer(taken, keys)
    numbers(w)
    head = ("# Generated by tools/knowledge/gen/school_math.py (computed, no outside data).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n1 = w.write(OUT_NUM, head)
    w2 = Writer(w.taken, w.keys)
    shapes(w2)
    n2 = w2.write(OUT_SHAPE, head)
    print(f"wrote {n1} entries to gen_math_numbers.txt and {n2} to gen_math_shapes.txt")


if __name__ == "__main__":
    main()
