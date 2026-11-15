#!/usr/bin/env python3
"""Builds Ace/Resources/sass_pack.json, Sassy mode's own data set.

    python3 tools/sass_pack/build.py          # build and check
    python3 tools/sass_pack/build.py --check  # only check, fail if the file is out of date

Checks every line for banned words, and that no two answers claim the same question
(using a copy of Ace's own word matching from Ace/Brain/TextKit.swift).

Every line and answer gets a sass level for the slider in Settings:
1 = Mild (light quips, from mild.py), 2 = Spicy, 3 = Extra (stage directions, ALL CAPS,
big comebacks). Mild picks level 1, Spicy picks level 2, Extra picks levels 2 and 3.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

from lines import LINES  # noqa: E402
from mild import MILD, MILD_OPEN, MILD_CLOSE, LEVELS  # noqa: E402
from talk import TALK, JOKE_ASKS, JOKES  # noqa: E402
from facts import COUNTRIES, BABIES, GROUPS, SHAPES, SYMBOLS, FACTS  # noqa: E402

OUT = os.path.join(ROOT, "Ace", "Resources", "sass_pack.json")
TEXTKIT = os.path.join(ROOT, "Ace", "Brain", "TextKit.swift")

# Kept in step with Sass.banned in Ace/Brain/Sass.swift (SassTests checks the app side too).
# Insults and swears: never anywhere.
BANNED = ["stupid", "dumb", "idiot", "moron", "ugly", "fat", "loser", "shut up", "hate you", "damn", "hell",
          "crap", "suck", "sucks", "pathetic", "worthless", "brainless", "freak", "weirdo", "shut it",
          "drunk", "beer", "wine"]
# Fine in a checked fact ("your heart pumps blood"), never in a sassy line, small talk or a joke.
GRIM = ["kill", "die", "dead", "blood"]

# MARK: A copy of Ace's word matching (TextKit.swift), so the builder sees questions the way the app does.

src = open(TEXTKIT, encoding="utf-8").read()


def swift_set(name):
    block = re.search(r"static let " + name + r": Set<String> = \[(.*?)\]", src, re.S).group(1)
    return set(re.findall(r'"([^"]*)"', block))


STOPWORDS = swift_set("stopwords")
SUBJECT_AT_END = swift_set("subjectAtEnd")
SAME_MEANING = dict(re.findall(r'"([^"]+)": "([^"]+)"',
                               re.search(r"static let sameMeaning: \[String: String\] = \[(.*?)\n    \]", src, re.S).group(1)))
SAME_PHRASES = [(p, w) for p, w in re.findall(r'\(#"(.*?)"#, "(.*?)"\)',
                                                re.search(r"static let samePhrases.*?\n    \]", src, re.S).group(0))]
CONTRACTIONS = dict(re.findall(r'"([^"]+)": "([^"]+)"',
                               re.search(r"let contractions = \[(.*?)\]", src, re.S).group(1)))


def normalize(text):
    s = text.lower().replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    words = [w for w in re.split(r"[ \n\t]+", s) if w]
    words = [CONTRACTIONS.get(w.strip('?!,;:"()[]{}'), w.strip('?!,;:"()[]{}')) for w in words]
    s = " ".join(words)
    s = re.sub(r"[^\w\s\+\-\*/\.%'°#&]|_", " ", s)
    s = re.sub(r"\s+", " ", s)
    return s.strip(" ").strip(".")


def canonical(s):
    for p, w in SAME_PHRASES:
        py = re.sub(r"\$(\d)", r"\\\1", w)
        s = re.sub(p, py, s)
    return s


def words(text):
    out = []
    for w in canonical(normalize(text)).split(" "):
        w = w.strip(".'")
        if w.endswith("'s") and len(w) > 3:
            w = w[:-2]
        if w:
            out.append(w)
    return out


def stem(w):
    if w in SAME_MEANING:
        return SAME_MEANING[w]
    if len(w) <= 3 or not w.isalpha():
        return w
    if w.endswith("ies") and len(w) > 4:
        return w[:-3] + "y"
    if w.endswith("sses"):
        return w[:-2]
    if w.endswith("ing") and len(w) > 5:
        base = w[:-3]
        if len(base) >= 2 and base[-1] == base[-2] and base[-1] not in "lsz":
            return base[:-1]
        return base
    if w.endswith("ed") and len(w) > 4:
        return w[:-2]
    if w.endswith("es") and len(w) > 4 and any(w[:-2].endswith(x) for x in ["ch", "sh", "x", "ss"]):
        return w[:-2]
    if w.endswith("s") and not w.endswith("ss") and not w.endswith("us") and not w.endswith("is"):
        return w[:-1]
    return w


def keywords(text):
    ws = words(text)
    return [stem(w) for i, w in enumerate(ws)
            if w not in STOPWORDS or (i == len(ws) - 1 and w in SUBJECT_AT_END)]


# Filler that doesn't change a small-talk question ("hey ace, how are you please").
FILLER = {"hey", "hi", "hello", "ace", "please", "pls", "plz", "so", "um", "uh", "oh", "well", "yo"}


def phrase_key(text):
    ws = [w for w in words(text) if w not in FILLER]
    return " ".join(ws)


def keyword_key(text):
    k = sorted(set(keywords(text)))
    return " ".join(k) if k else None


# MARK: Sass levels

# Words and phrases that make a line Extra (level 3) rather than Spicy (level 2).
STRONG = ["again", "shocking", "original", "seriously", "literally", "framing", "try a map", "nap",
          "interrupt", "rude", "not.", "only saying it once", "secretary", "electrician", "tech support",
          "poster", "record", "word for word", "singing", "mind reader", "no refunds", "you asked for this",
          "empire", "reluctantly", "always leave", "bold", "the things i do", "fine, fine", "my favorite. not",
          "prepare to lose", "window", "drama", "trophy", "please clap", "mic drop", "obviously i know"]
# Short words in capitals that are just names, not shouting.
NOT_SHOUTING = {"UK", "USA", "US", "TV", "OK", "DNA", "NASA", "AM", "PM", "UN", "EU", "CPU", "GPS", "ISS", "ON", "I"}


def heat(text):
    """2 (Spicy) or 3 (Extra) for one of the sassy lines from lines.py, talk.py and the fact wording."""
    if re.search(r"\*[A-Za-z][A-Za-z ']{0,38}\*", text):
        return 3
    for w in re.findall(r"[A-Za-z]{2,}", text):
        if w.isupper() and w not in NOT_SHOUTING:
            return 3
    low = text.lower()
    if text.count("!") >= 2 or any(p in low for p in STRONG):
        return 3
    return 2


# Which levels each slider stop picks from.
POOLS = {1: {1}, 2: {2}, 3: {2, 3}}


# MARK: Sassy wording for plain facts

OPEN = [
    "*sigh* Fine.", "Ugh, okay.", "Oh, you need help AGAIN? Shocking.", "Easy.",
    "Hold on, let me pretend this is hard. Okay.", "Wow, I know this one in my sleep.",
    "*rolls eyes* Obviously I know this.", "Ugh, fine, genius time.", "Oh, this one? Too easy.",
    "*cracks knuckles* Okay.", "Fine, I'll tell you. Since it's you.", "*dramatic sigh* Here.",
    "Buckle up, here comes a fact.", "Oh, look at you, learning stuff.", "Ask and you shall receive.",
    "*hair flip* Of course I know.",
]
CLOSE = [
    "Obviously.", "Write that down.", "You're welcome.", "Mic drop.", "Next time, ask me something hard.",
    "*hair flip*", "Too easy.", "Remember who told you that.", "Boom.", "Nailed it. As always.",
    "Please clap.", "Case closed.", "You heard it here first.", "Somebody give me a trophy.",
]

CAPITAL_TEMPLATES = [
    "Ugh, fine. The capital of {name} is {cap}. Obviously.",
    "*sigh* It's {cap}. Next time, try a map. Kidding. The capital of {name} is {cap}.",
    "Oh, you need help AGAIN? Shocking. The capital of {name} is {cap}.",
    "{Cap}. The capital of {name} is {cap}, and I knew that instantly. Just saying.",
    "Easy. The capital of {name} is {cap}. *hair flip*",
    "Hold on, let me pretend this is hard. Okay. The capital of {name} is {cap}.",
    "*rolls eyes* {Cap}. The capital of {name} is {cap}. Write that down.",
    "The capital of {name}? {Cap}. Mic drop.",
]
CONTINENT_TEMPLATES = [
    "Ugh, fine. {Name} is in {cont}. Obviously.",
    "*sigh* {Name} is in {cont}. Next time, try a map. Kidding.",
    "Easy. {Name} is in {cont}. *hair flip*",
    "Oh, this one? {Name} is in {cont}. Too easy.",
]


def cap_first(s):
    return s[:1].upper() + s[1:]


def dressed(index, answer):
    """Three sassy versions of one plain answer: a line before, a line after, and both."""
    o1 = OPEN[index % len(OPEN)]
    c1 = CLOSE[index % len(CLOSE)]
    o2 = OPEN[(index * 7 + 3) % len(OPEN)]
    c2 = CLOSE[(index * 5 + 2) % len(CLOSE)]
    return [f"{o1} {answer}", f"{answer} {c1}", f"{o2} {answer} {c2}"]


def mild(index, answer):
    """The Mild version of a plain answer: a light quip before or after it."""
    if index % 2 == 0:
        return f"{MILD_OPEN[index % len(MILD_OPEN)]} {answer}"
    return f"{answer} {MILD_CLOSE[index % len(MILD_CLOSE)]}"


def build():
    answers = []

    def add(topic, asks, said, exact=False, plain=None):
        levels = [heat(a) for a in said]
        if plain is not None:
            # One light version for the Mild stop.
            said = said + [mild(len(answers), plain)]
            levels = levels + [1]
        answers.append({"id": f"{topic}-{len(answers) + 1}", "topic": topic, "exact": exact, "q": asks, "a": said,
                        "lv": levels})

    for topic, asks, said in TALK:
        add(topic, asks, said, exact=True)
    add("joke", JOKE_ASKS, JOKES, exact=True)

    for i, (q, name, capital, cont, extra) in enumerate(COUNTRIES):
        asks = [f"what is the capital of {q}", f"what is the capital city of {q}", f"{q} capital"]
        said = []
        for k in range(3):
            t = CAPITAL_TEMPLATES[(i + k * 3) % len(CAPITAL_TEMPLATES)]
            line = t.format(name=name, cap=capital, Cap=cap_first(capital))
            said.append(line + (" " + extra if extra and k == 0 else ""))
        add("capital", asks, said, plain=f"The capital of {name} is {capital}.")
    for i, (q, name, capital, cont, extra) in enumerate(COUNTRIES):
        if not cont:
            continue
        asks = [f"what continent is {q} in", f"which continent is {q} in", f"{q} continent"]
        said = [CONTINENT_TEMPLATES[(i + k) % len(CONTINENT_TEMPLATES)].format(Name=cap_first(name), cont=cont)
                for k in range(2)]
        add("continent", asks, said, plain=f"{cap_first(name)} is in {cont}.")

    for i, (animal, baby, extra) in enumerate(BABIES):
        plain = f"A baby {animal} is called {baby}." + (" " + extra if extra else "")
        add("animals", [f"what is a baby {animal} called", f"what do you call a baby {animal}"], dressed(i, plain)[:2], plain=plain)
    for i, (animals, group) in enumerate(GROUPS):
        plain = f"A group of {animals} is called {group}."
        add("animals", [f"what is a group of {animals} called", f"what do you call a group of {animals}"],
            dressed(i + 3, plain)[:2], plain=plain)
    for i, (shape, sides) in enumerate(SHAPES):
        plain = f"A {shape} has {sides} sides."
        add("math", [f"how many sides does a {shape} have", f"how many sides on a {shape}"], dressed(i + 5, plain)[:2], plain=plain)
    for i, (element, symbol) in enumerate(SYMBOLS):
        plain = f"The chemical symbol for {element} is {symbol}."
        add("science", [f"what is the chemical symbol for {element}", f"what is the symbol for {element}"],
            dressed(i + 7, plain)[:2], plain=plain)
    for i, (topic, asks, plain) in enumerate(FACTS):
        add(topic, asks, dressed(i, plain), plain=plain)

    # Lines: the mild ones first (level 1), then the sassy ones (level 2 or 3).
    lines, levels = {}, {}
    for key in list(LINES) + [k for k in list(MILD) + list(LEVELS) if k not in LINES]:
        said = MILD.get(key, []) + LINES.get(key, [])
        lv = [1] * len(MILD.get(key, [])) + [heat(x) for x in LINES.get(key, [])]
        if key in LEVELS:
            said = LEVELS[key]
            lv = [{"level.mild": 1, "level.spicy": 2, "level.extra": 3}[key]] * len(said)
        lines[key], levels[key] = said, lv

    return {"version": 2, "lines": lines, "levels": levels, "answers": answers}


def check(pack):
    problems = []

    def banned_in(text, grim=True):
        low = " " + re.sub(r"[^a-z' ]", " ", text.lower()) + " "
        return [b for b in BANNED + (GRIM if grim else []) if f" {b} " in low]

    for key, lines in pack["lines"].items():
        lv = pack["levels"][key]
        if len(lv) != len(lines):
            problems.append(f"levels[{key}] doesn't match its lines")
        if not key.startswith("level."):
            for stop, pool in POOLS.items():
                n = sum(1 for x in lv if x in pool)
                if n < 3:
                    problems.append(f"lines[{key}] has only {n} lines for slider stop {stop}")
        if len(lines) < 3:
            problems.append(f"lines[{key}] has only {len(lines)} lines")
        if len(set(lines)) != len(lines):
            problems.append(f"lines[{key}] has a repeated line")
        for line in lines:
            if banned_in(line):
                problems.append(f"lines[{key}]: banned word {banned_in(line)} in {line!r}")
    exact, by_keys = {}, {}
    for e in pack["answers"]:
        if len(e["lv"]) != len(e["a"]):
            problems.append(f"{e['id']}: levels don't match its answers")
        for a in e["a"]:
            hits = banned_in(a, grim=e["topic"] in ("about", "talk", "joke"))
            if hits:
                problems.append(f"{e['id']}: banned word {hits} in {a!r}")
        for q in e["q"]:
            pk = phrase_key(q)
            if not pk:
                problems.append(f"{e['id']}: empty question {q!r}")
            if pk in exact and exact[pk] != e["id"]:
                problems.append(f"{e['id']}: {q!r} is already {exact[pk]}")
            exact.setdefault(pk, e["id"])
            if not e["exact"]:
                kk = keyword_key(q)
                if kk is None:
                    problems.append(f"{e['id']}: {q!r} has no keywords")
                elif kk in by_keys and by_keys[kk] != e["id"]:
                    problems.append(f"{e['id']}: {q!r} has the same words as {by_keys[kk]}")
                else:
                    by_keys[kk] = e["id"]
    return problems


def main():
    pack = build()
    problems = check(pack)
    lines = sum(len(v) for v in pack["lines"].values())
    said = sum(len(e["a"]) for e in pack["answers"])
    print(f"{len(pack['answers'])} questions with {said} sassy answers, plus {lines} sassy lines = {said + lines} in all")
    every = [x for v in pack["levels"].values() for x in v] + [x for e in pack["answers"] for x in e["lv"]]
    print("By level: " + ", ".join(f"{n} {every.count(k)}" for k, n in [(1, "Mild"), (2, "Spicy"), (3, "Extra")]))
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    text = json.dumps(pack, ensure_ascii=False, indent=1) + "\n"
    if "--check" in sys.argv:
        if not os.path.exists(OUT) or open(OUT, encoding="utf-8").read() != text:
            print("sass_pack.json is out of date. Run python3 tools/sass_pack/build.py")
            sys.exit(1)
        print("sass_pack.json is up to date")
        return
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"Wrote {os.path.relpath(OUT, ROOT)} ({len(text.encode()) // 1024} KB)")


if __name__ == "__main__":
    main()
