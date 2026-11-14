#!/usr/bin/env python3
"""Builds Ace/Resources/qa_bank.json, Ace V4's question bank.

Run from the repo root:  python3 tools/build_qa_bank.py
Format is "ace-qa/1" (see docs/qa-format.md). The PC version of Ace V4 uses
the same format, so the two banks can be merged by sync.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import qa_data_world as W  # noqa: E402
import qa_data_general as G  # noqa: E402
import qa_variants as V  # noqa: E402

OUT = os.path.join(HERE, "..", "Ace", "Resources", "qa_bank.json")

entries = []
seen_ids = set()


def slug(text):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:60] or "x"


def add(tag, questions, answers, eid=None):
    qs = []
    for q in questions:
        q = " ".join(q.strip().lower().split())
        if q and q not in qs:
            qs.append(q)
    ans = [a.strip() for a in answers if a.strip()]
    if not qs or not ans:
        raise ValueError(f"empty entry in {tag}: {questions} {answers}")
    base = eid or f"{tag}.{slug(qs[0])}"
    eid = base
    n = 2
    while eid in seen_ids:
        eid = f"{base}-{n}"
        n += 1
    seen_ids.add(eid)
    entries.append({"id": eid, "tag": tag, "q": qs, "a": ans})


def article_name(country):
    """'the United States' style names for sentences."""
    needs_the = {"United States", "United Kingdom", "Netherlands", "Philippines", "Bahamas", "Gambia",
                 "Czech Republic", "Dominican Republic", "Central African Republic", "United Arab Emirates",
                 "Maldives", "Marshall Islands", "Solomon Islands", "Comoros", "Seychelles",
                 "Democratic Republic of the Congo", "Republic of the Congo", "Vatican City"}
    return f"the {country}" if country in needs_the else country


def cap_first(s):
    return s[0].upper() + s[1:] if s else s


# ---------- hand-written general entries ----------
def parse_general():
    tag = "general"
    for raw in G.GENERAL.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("# "):
            tag = line[2:].strip()
            continue
        if "=>" not in line:
            raise ValueError(f"bad line: {line}")
        left, right = line.split("=>", 1)
        qs = [q for q in left.split("|")]
        ans = [a for a in right.split("||")]
        add(tag, qs, V.general(tag, [a.strip() for a in ans if a.strip()]))


# ---------- countries ----------
def countries():
    for country, capital, continent in W.COUNTRIES:
        names = [country.lower()] + W.COUNTRY_ALIASES.get(country, [])
        nice = article_name(country)
        qs = []
        for n in names:
            qs += [f"what is the capital of {n}", f"capital of {n}", f"{n} capital",
                   f"whats the capital city of {n}"]
        add("geo.capital", qs, V.make("capital", nice=nice, capital=capital, continent=continent))
        cap_l = capital.lower()
        add("geo.capital", [f"{cap_l} is the capital of what country", f"what country is {cap_l} the capital of",
                            f"where is {cap_l}", f"{cap_l} is in what country"],
            V.make("capital_same" if capital.lower().startswith(country.lower()) else "capital_of",
                   nice=nice, capital=capital, continent=continent))
        qs = []
        for n in names:
            qs += [f"what continent is {n} in", f"where is {n}", f"is {n} in {continent.lower()}",
                   f"which continent is {n} on"]
        add("geo.continent", qs, V.make("continent", nice=nice, capital=capital, continent=continent))
        cur = W.CURRENCIES.get(country)
        money = f" People there pay with {cur}." if cur else ""
        qs = []
        for n in names:
            qs += [f"tell me about {n}", f"what do you know about {n}", f"facts about {n}"]
        add("geo.country", qs, V.make("country", nice=nice, capital=capital, continent=continent, money=money))
        if cur:
            qs = []
            for n in names:
                qs += [f"what is the currency of {n}", f"what money do they use in {n}", f"{n} currency"]
            add("geo.currency", qs, V.make("currency", nice=nice, cur=cur))


def states():
    for state, capital, abbr in W.US_STATES:
        s = state.lower()
        add("geo.us", [f"what is the capital of {s}", f"capital of {s}", f"{s} capital", f"{s} state capital"],
            V.make("state_capital", state=state, capital=capital))
        add("geo.us", [f"what is the abbreviation for {s}", f"{s} abbreviation", f"what does {abbr.lower()} stand for state",
                       f"{s} postal code"], V.make("state_abbr", state=state, abbr=abbr))
        c = capital.lower()
        add("geo.us", [f"{c} is the capital of what state", f"what state is {c} the capital of"],
            V.make("state_of", state=state, capital=capital))


# ---------- elements ----------
def elements():
    for number, symbol, name in W.ELEMENTS:
        n = name.lower()
        state = "gas" if name in W.GASES else "liquid" if name in W.LIQUIDS else "solid"
        add("chem.symbol", [f"what is the symbol for {n}", f"{n} symbol", f"chemical symbol of {n}",
                            f"what is the element symbol for {n}"],
            V.make("symbol", name=name, symbol=symbol, number=number))
        add("chem.symbol", [f"what element is {symbol.lower()}", f"what is {symbol.lower()} on the periodic table",
                            f"which element has the symbol {symbol.lower()}"],
            V.make("symbol_of", name=name, symbol=symbol, number=number))
        add("chem.number", [f"what is the atomic number of {n}", f"atomic number of {n}", f"{n} atomic number"],
            V.make("atomic_number", name=name, symbol=symbol, number=number))
        add("chem.number", [f"what element is number {number}", f"element {number}", f"which element has atomic number {number}"],
            V.make("element_number", name=name, symbol=symbol, number=number))
        if number >= 100:
            state_text = ("Only a few atoms of it have ever been made, so nobody has seen it as a solid, "
                          "liquid or gas.")
        else:
            if state == "liquid":
                state_text = "It's one of only two elements that are liquid at room temperature."
            else:
                state_text = f"At room temperature it's a {state}."
        add("chem.state", [f"is {n} a solid liquid or gas", f"is {n} a gas", f"what state is {n} at room temperature",
                           f"tell me about {n}"],
            V.make("element_state", name=name, symbol=symbol, number=number, state_text=state_text))


# ---------- words ----------
def words():
    for a, b in G.ANTONYMS:
        add("words.opposite", [f"what is the opposite of {a}", f"opposite of {a}", f"antonym for {a}"],
            V.make("opposite", a=a, b=b))
        add("words.opposite", [f"what is the opposite of {b}", f"opposite of {b}", f"antonym for {b}"],
            V.make("opposite", a=b, b=a))
    for w, syns in G.SYNONYMS:
        add("words.synonym", [f"what is another word for {w}", f"synonym for {w}", f"another word for {w}",
                              f"what's a different word for {w}"], V.make("synonym", w=w, syns=syns))


def animals():
    for animal, baby, sound, group in G.ANIMALS:
        add("animals.baby", [f"what is a baby {animal} called", f"baby {animal} name", f"what do you call a baby {animal}"],
            V.make("baby", animal=animal, baby=baby))
        add("animals.sound", [f"what sound does a {animal} make", f"what noise does a {animal} make", f"what does a {animal} say"],
            V.make("sound", animal=animal, sound=sound))
        many = V.plural(animal)
        qs = [f"what is a group of {many} called", f"group of {many}", f"what do you call a bunch of {many}"]
        if many != animal + "s":
            qs += [f"what is a group of {animal}s called", f"group of {animal}s"]
        add("animals.group", qs, V.make("group", animal=animal, group=group),
            eid=f"animals.group.{slug(f'what is a group of {animal}s called')}")


def languages():
    for lang, hello, thanks, bye in G.GREETINGS:
        l = lang.lower()
        add("lang.hello", [f"how do you say hello in {l}", f"hello in {l}", f"how to say hi in {l}"],
            V.make("hello", lang=lang, word=hello))
        add("lang.thanks", [f"how do you say thank you in {l}", f"thank you in {l}", f"thanks in {l}"],
            V.make("thanks", lang=lang, word=thanks))
        add("lang.bye", [f"how do you say goodbye in {l}", f"goodbye in {l}", f"bye in {l}"],
            V.make("bye", lang=lang, word=bye))


NTH = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh",
       "twelfth"]


def calendar_facts():
    for i, (m, days) in enumerate(G.MONTHS):
        l = m.lower()
        extra = " (29 in a leap year)" if m == "February" else ""
        add("time.month", [f"how many days in {l}", f"how many days does {l} have", f"days in {l}"],
            V.make("month_days", month=m, days=days, extra=extra))
        nxt = G.MONTHS[(i + 1) % 12][0]
        add("time.month", [f"what month comes after {l}", f"what is the month after {l}", f"which month is {l} number"],
            V.make("month_order", month=m, n=i + 1, nth=NTH[i], next=nxt))
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for i, d in enumerate(days):
        l = d.lower()
        add("time.day", [f"what day comes after {l}", f"day after {l}"], V.make("day_after", day=d, next=days[(i + 1) % 7]))
        add("time.day", [f"what day comes before {l}", f"day before {l}"], V.make("day_before", day=d, prev=days[(i - 1) % 7]))


def planets():
    for name, pos, moons, day, year, fact in G.PLANETS:
        l = name.lower()
        ordinal = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"][pos - 1]
        add("space.planet", [f"tell me about {l}", f"facts about {l}", f"what is {l} like"],
            V.make("planet", name=name, ordinal=ordinal, pos=pos, fact=fact))
        add("space.planet", [f"how many moons does {l} have", f"{l} moons"], V.make("planet_moons", name=name, moons=moons))
        add("space.planet", [f"how long is a day on {l}", f"{l} day length"], V.make("planet_day", name=name, day=day))
        add("space.planet", [f"how long is a year on {l}", f"how long does {l} take to orbit the sun"],
            V.make("planet_year", name=name, year=year))
        add("space.planet", [f"what number planet is {l}", f"where is {l} in the solar system"],
            V.make("planet_pos", name=name, ordinal=ordinal, pos=pos))


def main():
    parse_general()
    countries()
    states()
    elements()
    words()
    animals()
    languages()
    calendar_facts()
    planets()
    data = {
        "format": "ace-qa/1",
        "version": 1,
        "source": "builtin",
        "count": len(entries),
        "entries": entries,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    total_q = sum(len(e["q"]) for e in entries)
    print(f"wrote {len(entries)} entries ({total_q} question wordings) to {os.path.normpath(OUT)}")


if __name__ == "__main__":
    main()
