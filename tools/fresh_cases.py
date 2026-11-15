"""50 fresh questions Ace has never been tuned on (written Nov 15, 2026, before the
matching and knowledge changes in the same pull request).

Run:  python3 tools/fresh_cases.py
Writes AceTests/fresh_cases.json, which AceTests/FreshQuestionsTests.swift runs
against the real brain and prints as "FRESH SCORE". It isn't a pass mark: it's an
honest check of how Ace does on wordings nobody tuned it for. Don't change the
questions after seeing the score. Write a new set instead.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from smartness_cases import B, S, M, U, BANK, norm  # noqa: E402

OUT = os.path.join(HERE, "..", "AceTests", "fresh_cases.json")

PARAPHRASE = [
    ("why do people yawn so much", B("body.why-do-we-yawn")),
    ("pluto still counts as a planet right", B("space.is-pluto-a-planet")),
    ("what do you call lots of frogs together", B("animals.group.what-is-a-group-of-frogs-called")),
    ("how many continents does the world have", B("earth.how-many-continents-are-there")),
    ("at what temp does water turn to ice", B("science.what-temperature-does-water-freeze")),
    ("what is chocolate made from", B("food.where-does-chocolate-come-from")),
    ("which star is nearest to us", B("space.what-is-the-closest-star")),
    ("tell me about the space station", B("space.what-is-the-iss")),
    ("how many letters does the english alphabet have", B("words.how-many-letters-are-in-the-alphabet")),
    ("what's a baby monkey known as", B("animals.baby.what-is-a-baby-monkey-called")),
    ("why does your body need sleep", B("body.why-do-we-sleep")),
    ("how many years make a decade", B("units.how-many-years-in-a-decade")),
    ("which colors are the primary ones", B("science.what-are-the-primary-colors")),
    ("what age is planet earth", B("space.how-old-is-the-earth")),
    ("what's a bug in programming", B("tech.what-is-a-bug")),
    ("what food do pandas like", B("animals.what-do-pandas-eat")),
    ("how many years can a turtle live", B("animals.how-long-do-turtles-live")),
    ("how much water am i supposed to drink each day", B("body.how-much-water-should-i-drink")),
    ("how does rain happen", B("earth.what-causes-rain")),
    ("what does the cloud mean on computers", B("tech.what-is-the-cloud")),
    ("is a dolphin a kind of fish", B("animals.are-dolphins-fish")),
    ("how long does a minecraft day last", B("minecraft.how-long-is-a-day-in-minecraft")),
    ("what's titanium's chemical symbol", B("chem.symbol.what-is-the-symbol-for-titanium")),
    ("which city is the capital of libya", B("geo.capital.what-is-the-capital-of-libya")),
    ("give me some facts about norway", B("geo.country.tell-me-about-norway")),
]

TYPOS = [
    ("why do we yawm", B("body.why-do-we-yawn")),
    ("how many contenents are there", B("earth.how-many-continents-are-there")),
    ("what do pandas eet", B("animals.what-do-pandas-eat")),
    ("what is the capitol of nepal", B("geo.capital.what-is-the-capital-of-nepal")),
    ("what is the simbol for helium", B("chem.symbol.what-is-the-symbol-for-helium")),
    ("how long do turtels live", B("animals.how-long-do-turtles-live")),
    ("what is pyhton", B("tech.what-is-python")),
    ("how old is the eath", B("space.how-old-is-the-earth")),
]

SKILLS = [
    ("can you start a 12 minute timer", S("timer")),
    ("what's 48 divided by 6", S("math")),
    ("convert 10 inches to centimeters", S("convert")),
    ("how do you say good afternoon in italian", S("translate")),
    ("give me a sprint script for roblox", S("script")),
    ("solve 4x + 1 = 17", S("homework")),
    ("take a note: feed the fish", S("note")),
    ("let's play some trivia", S("game")),
    ("remind me to charge my ipad at 9pm", S("reminder")),
    ("what's the weather like tomorrow", S("weather")),
]

UNKNOWN = [
    "what color is my bedroom",
    "what did i eat for breakfast yesterday",
    "what is my best friend's favorite movie",
    "how many coins are in my piggy bank",
    "what's the password to my school laptop",
]

MULTI = [
    ("what is python and what is the cloud", M(B("tech.what-is-python"), B("tech.what-is-the-cloud"))),
    ("how many teeth does a kid have and why do humans need sleep",
     M(B("body.how-many-teeth-do-kids-have"), B("body.why-do-we-sleep"))),
]


def build():
    cases = []

    def add(category, prompt, expect):
        cases.append({"n": len(cases) + 1, "category": category, "prompt": prompt, "expect": expect})

    for p, e in PARAPHRASE:
        add("paraphrase", p, e)
    for p, e in TYPOS:
        add("typo", p, e)
    for p, e in SKILLS:
        add("skill", p, e)
    for p in UNKNOWN:
        add("unknown", p, U)
    for p, e in MULTI:
        add("multi-part", p, e)
    return cases


def check(cases):
    bank = json.load(open(BANK))["entries"]
    ids = {e["id"] for e in bank}
    wordings = {norm(q) for e in bank for q in e["q"]}
    problems = []

    def ids_in(exp):
        if "bank" in exp:
            return exp["bank"]
        if "multi" in exp:
            return [i for p in exp["multi"] for i in ids_in(p)]
        return []

    seen = set()
    for c in cases:
        n = norm(c["prompt"])
        if n in seen:
            problems.append(f"#{c['n']} repeats another prompt")
        seen.add(n)
        if n in wordings:
            problems.append(f"#{c['n']} is in the answer bank word for word: {c['prompt']}")
        for i in ids_in(c["expect"]):
            if i not in ids:
                problems.append(f"#{c['n']} expects a missing id: {i}")
    if len(cases) != 50:
        problems.append(f"there are {len(cases)} cases, not 50")
    return problems


if __name__ == "__main__":
    cases = build()
    problems = check(cases)
    for p in problems:
        print("PROBLEM:", p)
    if problems:
        sys.exit(1)
    with open(OUT, "w") as f:
        json.dump({"format": "ace-smartness/1", "count": len(cases), "cases": cases}, f, indent=1)
        f.write("\n")
    print(f"Wrote {len(cases)} fresh cases to AceTests/fresh_cases.json")
