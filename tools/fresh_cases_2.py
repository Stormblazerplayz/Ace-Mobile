"""Fresh set 2: 50 more questions Ace has never been tuned on.

Written Nov 15, 2026, BEFORE the matching fixes in the same pull request, because the first
fresh set (tools/fresh_cases.py) was used to find those fixes and so isn't fresh any more.
Don't change these after seeing a score. Write a new set instead.

Run:  python3 tools/fresh_cases_2.py
Writes AceTests/fresh_cases_2.json, which AceTests/FreshQuestions2Tests.swift runs against the
real brain and prints as "FRESH2 SCORE". It never fails the build.

Like the knowledge set, a case passes when Ace picks an answer (sure or a guess) whose text has
the right facts, so it doesn't matter which of two answers that say the same thing wins.
  has:     groups of strings. Every group needs one of its strings in the answer.
  skill:   this skill counts as right.
  unknown: Ace should say it doesn't know or ask what you mean, not guess.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "AceTests", "fresh_cases_2.json")


def H(*groups, skill=None):
    e = {"has": [list(g) if isinstance(g, (list, tuple)) else [g] for g in groups]}
    if skill:
        e["skill"] = skill
    return e


def S(skill):
    return {"skill": skill}


U = {"unknown": True}

CASES = [
    # Said a different way than the answer bank says it.
    ("paraphrase", "how many legs has a spider got", H(("8", "eight"))),
    ("paraphrase", "which planet has the most rings", H("Saturn")),
    ("paraphrase", "what gas do plants breathe in", H(("carbon dioxide", "CO2"))),
    ("paraphrase", "how many bones are inside a grown up", H("206")),
    ("paraphrase", "what's the biggest animal on the planet", H("blue whale")),
    ("paraphrase", "which ocean is the largest one", H("Pacific")),
    ("paraphrase", "how hot does the sun get", H(("million", "5,500", "5500", "°"))),
    ("paraphrase", "who was the first guy to walk on the moon", H("Armstrong")),
    ("paraphrase", "what's the tallest mountain on earth", H("Everest")),
    ("paraphrase", "how many days are there in a leap year", H("366")),
    ("paraphrase", "what does a caterpillar turn into", H(("butterfly", "moth"))),
    ("paraphrase", "which animal is the fastest on land", H("cheetah")),
    ("paraphrase", "what's the longest river in the world", H(("Nile", "Amazon"))),
    ("paraphrase", "how many hearts does an octopus have", H(("three", "3"))),
    ("paraphrase", "what is the red planet called", H("Mars")),
    ("paraphrase", "who came up with the light bulb", H("Edison")),
    ("paraphrase", "how many sides does a hexagon have", H(("six", "6"))),
    ("paraphrase", "what's the main language they speak in mexico", H("Spanish")),
    ("paraphrase", "how long does it take earth to go around the sun", H(("365", "year"))),
    ("paraphrase", "what do bees make", H("honey")),
    ("paraphrase", "which organ pumps blood around your body", H("heart")),
    ("paraphrase", "what is h2o", H("water")),
    ("paraphrase", "how many players are on a soccer team on the field", H(("11", "eleven"))),
    ("paraphrase", "what's a group of lions known as", H("pride")),
    ("paraphrase", "what are baby kangaroos called", H("joey")),
    ("paraphrase", "what is the smallest planet", H("Mercury")),
    ("paraphrase", "why is the ocean salty", H(("salt", "mineral"))),
    ("paraphrase", "what does a thermometer measure", H("temperature")),
    ("paraphrase", "how many minutes make an hour", H("60")),
    ("paraphrase", "what is the hardest natural thing", H("diamond")),
    # Typos.
    ("typo", "how many planits are in the solar system", H(("8", "eight"))),
    ("typo", "what is the capitel of japan", H("Tokyo")),
    ("typo", "who painted the mona lsa", H(("Leonardo", "da Vinci"))),
    ("typo", "what do kowalas eat", H("eucalyptus")),
    ("typo", "how fast is the speed of lite", H(("299", "300,000", "186,000", "186000"))),
    ("typo", "what is photosinthesis", H(("sunlight", "light"))),
    ("typo", "how many continants are there in the world", H(("7", "seven"))),
    ("typo", "what is the bigest desert", H(("Antarctic", "Sahara"))),
    # Skills.
    ("skill", "set a timer for 3 minutes please", S("timer")),
    ("skill", "what is 7 times 8", S("math")),
    ("skill", "how do you say thank you in french", S("translate")),
    ("skill", "write me a python script that counts to ten", S("script")),
    ("skill", "remind me to feed the dog at 6", S("reminder")),
    ("skill", "is it going to rain today", S("weather")),
    # Personal things Ace can't know.
    ("unknown", "what's my cousin's favorite color", U),
    ("unknown", "how tall is my brother", U),
    ("unknown", "what did my mom make for dinner last night", U),
    ("unknown", "what time does my soccer practice start", U),
    # Harder wordings.
    ("paraphrase", "if i wanted to know how deep the ocean goes what would the answer be", H(("11,000", "11000", "Mariana", "36,000", "10,9"))),
    ("paraphrase", "yo ace whats the closest planet to the sun", H("Mercury")),
]


def main():
    assert len(CASES) == 50, len(CASES)
    prompts = [c[1] for c in CASES]
    assert len(set(prompts)) == 50, "two cases are the same"
    cases = [{"n": i + 1, "category": c, "prompt": p, "expect": e} for i, (c, p, e) in enumerate(CASES)]
    with open(OUT, "w") as f:
        json.dump({"format": "ace-knowledge/1", "count": len(cases), "cases": cases}, f, indent=1)
        f.write("\n")
    print(f"Wrote {len(cases)} fresh-2 cases to AceTests/fresh_cases_2.json")


if __name__ == "__main__":
    sys.exit(main())
