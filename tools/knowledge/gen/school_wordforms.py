#!/usr/bin/env python3
"""Writes data/school/gen_wordforms.txt: past tense and past participle of irregular English verbs,
and irregular plural nouns.

Source: no outside data. The tables are written by hand from standard school grammar lists (American usage;
British variants are noted where common). Public domain facts, no license needed.

Run from the repo root:  python3 tools/knowledge/gen/school_wordforms.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from school_math import KNOW, Writer, load_taken  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_wordforms.txt")

# base, simple past, past participle, note
VERBS = [
    ("arise", "arose", "arisen", ""), ("awake", "awoke", "awoken", ""), ("be", "was or were", "been", "Use was with I, he, she and it, and were with you, we and they."),
    ("bear", "bore", "borne", "For birth, \"born\" is used: she was born in 2010."), ("beat", "beat", "beaten", ""),
    ("become", "became", "become", ""), ("begin", "began", "begun", ""), ("bend", "bent", "bent", ""),
    ("bet", "bet", "bet", ""), ("bind", "bound", "bound", ""), ("bite", "bit", "bitten", ""),
    ("bleed", "bled", "bled", ""), ("blow", "blew", "blown", ""), ("break", "broke", "broken", ""),
    ("breed", "bred", "bred", ""), ("bring", "brought", "brought", "\"Brang\" and \"brung\" are not standard."),
    ("build", "built", "built", ""), ("burst", "burst", "burst", ""), ("buy", "bought", "bought", ""),
    ("catch", "caught", "caught", ""), ("choose", "chose", "chosen", ""), ("cling", "clung", "clung", ""),
    ("come", "came", "come", ""), ("cost", "cost", "cost", ""), ("creep", "crept", "crept", ""),
    ("cut", "cut", "cut", ""), ("deal", "dealt", "dealt", ""), ("dig", "dug", "dug", ""),
    ("dive", "dove or dived", "dived", "Dove is more common in American English, dived in British English."),
    ("do", "did", "done", ""), ("draw", "drew", "drawn", ""),
    ("dream", "dreamed or dreamt", "dreamed or dreamt", "Dreamed is more common in American English."),
    ("drink", "drank", "drunk", ""), ("drive", "drove", "driven", ""), ("eat", "ate", "eaten", ""),
    ("fall", "fell", "fallen", ""), ("feed", "fed", "fed", ""), ("feel", "felt", "felt", ""),
    ("fight", "fought", "fought", ""), ("find", "found", "found", ""), ("flee", "fled", "fled", ""),
    ("fling", "flung", "flung", ""), ("fly", "flew", "flown", ""), ("forbid", "forbade", "forbidden", ""),
    ("forget", "forgot", "forgotten", ""), ("forgive", "forgave", "forgiven", ""), ("freeze", "froze", "frozen", ""),
    ("get", "got", "gotten or got", "Gotten is common in American English; British English uses got."),
    ("give", "gave", "given", ""), ("go", "went", "gone", ""), ("grind", "ground", "ground", ""),
    ("grow", "grew", "grown", ""), ("hang", "hung", "hung", "For the old punishment, \"hanged\" is used."),
    ("have", "had", "had", ""), ("hear", "heard", "heard", ""), ("hide", "hid", "hidden", ""),
    ("hit", "hit", "hit", ""), ("hold", "held", "held", ""), ("hurt", "hurt", "hurt", ""),
    ("keep", "kept", "kept", ""), ("kneel", "knelt or kneeled", "knelt or kneeled", ""), ("know", "knew", "known", ""),
    ("lay", "laid", "laid", "Don't mix it up with lie (to recline): lie, lay, lain."), ("lead", "led", "led", ""),
    ("leap", "leaped or leapt", "leaped or leapt", ""), ("leave", "left", "left", ""), ("lend", "lent", "lent", ""),
    ("let", "let", "let", ""), ("lie", "lay", "lain", "This is lie meaning to recline. Lie meaning to say something false is regular: lied, lied."),
    ("light", "lit or lighted", "lit or lighted", ""), ("lose", "lost", "lost", ""), ("make", "made", "made", ""),
    ("mean", "meant", "meant", ""), ("meet", "met", "met", ""), ("pay", "paid", "paid", ""),
    ("prove", "proved", "proven or proved", ""), ("put", "put", "put", ""), ("quit", "quit", "quit", ""),
    ("read", "read", "read", "The past forms are spelled the same but pronounced \"red\"."),
    ("ride", "rode", "ridden", ""), ("ring", "rang", "rung", ""), ("rise", "rose", "risen", ""),
    ("run", "ran", "run", ""), ("say", "said", "said", ""), ("see", "saw", "seen", "\"I seen it\" is not standard; say \"I saw it\" or \"I have seen it\"."),
    ("seek", "sought", "sought", ""), ("sell", "sold", "sold", ""), ("send", "sent", "sent", ""),
    ("set", "set", "set", ""), ("sew", "sewed", "sewn or sewed", ""), ("shake", "shook", "shaken", ""),
    ("shine", "shone", "shone", "When it means to polish, it's regular: shined."), ("shoot", "shot", "shot", ""),
    ("show", "showed", "shown", ""), ("shrink", "shrank", "shrunk", ""), ("shut", "shut", "shut", ""),
    ("sing", "sang", "sung", ""), ("sink", "sank", "sunk", ""), ("sit", "sat", "sat", ""),
    ("sleep", "slept", "slept", ""), ("slide", "slid", "slid", ""), ("sling", "slung", "slung", ""),
    ("speak", "spoke", "spoken", ""), ("speed", "sped", "sped", ""), ("spend", "spent", "spent", ""),
    ("spin", "spun", "spun", ""), ("spit", "spit or spat", "spit or spat", ""), ("split", "split", "split", ""),
    ("spread", "spread", "spread", ""), ("spring", "sprang", "sprung", ""), ("stand", "stood", "stood", ""),
    ("steal", "stole", "stolen", ""), ("stick", "stuck", "stuck", ""), ("sting", "stung", "stung", ""),
    ("stink", "stank", "stunk", ""), ("strike", "struck", "struck", ""), ("swear", "swore", "sworn", ""),
    ("sweep", "swept", "swept", ""), ("swim", "swam", "swum", ""), ("swing", "swung", "swung", ""),
    ("take", "took", "taken", ""), ("teach", "taught", "taught", ""), ("tear", "tore", "torn", ""),
    ("tell", "told", "told", ""), ("think", "thought", "thought", ""), ("throw", "threw", "thrown", ""),
    ("understand", "understood", "understood", ""), ("wake", "woke", "woken", ""), ("wear", "wore", "worn", ""),
    ("weave", "wove", "woven", ""), ("weep", "wept", "wept", ""), ("win", "won", "won", ""),
    ("wind", "wound", "wound", "This is wind as in winding a clock (rhymes with find)."),
    ("write", "wrote", "written", ""),
]

# singular, plural, note
PLURALS = [
    ("child", "children", ""), ("man", "men", ""), ("woman", "women", ""), ("person", "people", "\"Persons\" is used in some formal or legal writing."),
    ("foot", "feet", ""), ("tooth", "teeth", ""), ("goose", "geese", ""), ("mouse", "mice", "For computer mice, both mice and mouses are used, but mice is more common."),
    ("louse", "lice", ""), ("ox", "oxen", ""), ("die", "dice", "Many people now use dice for one as well."),
    ("cactus", "cacti or cactuses", ""), ("fungus", "fungi", ""), ("nucleus", "nuclei", ""),
    ("stimulus", "stimuli", ""), ("radius", "radii", ""), ("octopus", "octopuses", "Octopi is also seen, but octopuses is the most accepted."),
    ("hippopotamus", "hippopotamuses or hippopotami", ""), ("analysis", "analyses", ""), ("crisis", "crises", ""),
    ("thesis", "theses", ""), ("oasis", "oases", ""), ("axis", "axes", ""), ("parenthesis", "parentheses", ""),
    ("criterion", "criteria", ""), ("phenomenon", "phenomena", ""), ("datum", "data", "Data is often used as a singular mass noun too: the data is clear."),
    ("medium", "media", "For people who contact spirits, it's mediums."), ("curriculum", "curricula or curriculums", ""),
    ("bacterium", "bacteria", ""), ("appendix", "appendices or appendixes", ""), ("index", "indices or indexes", ""),
    ("vertex", "vertices", ""), ("matrix", "matrices", ""), ("formula", "formulas or formulae", ""),
    ("larva", "larvae", ""), ("antenna", "antennae or antennas", "Insects have antennae; radios have antennas."),
    ("alumnus", "alumni", ""), ("sheep", "sheep", ""), ("deer", "deer", ""), ("moose", "moose", ""),
    ("fish", "fish", "\"Fishes\" is used for different kinds of fish."), ("salmon", "salmon", ""), ("trout", "trout", ""),
    ("bison", "bison", ""), ("aircraft", "aircraft", ""), ("series", "series", ""), ("species", "species", ""),
    ("leaf", "leaves", ""), ("knife", "knives", ""), ("wife", "wives", ""), ("life", "lives", ""), ("wolf", "wolves", ""),
    ("half", "halves", ""), ("calf", "calves", ""), ("shelf", "shelves", ""), ("thief", "thieves", ""), ("loaf", "loaves", ""),
    ("elf", "elves", ""), ("scarf", "scarves or scarfs", ""), ("hoof", "hooves or hoofs", ""), ("roof", "roofs", ""),
    ("chief", "chiefs", ""), ("belief", "beliefs", ""), ("potato", "potatoes", ""), ("tomato", "tomatoes", ""),
    ("hero", "heroes", ""), ("echo", "echoes", ""), ("volcano", "volcanoes or volcanos", ""), ("mosquito", "mosquitoes", ""),
    ("piano", "pianos", ""), ("photo", "photos", ""), ("zero", "zeros or zeroes", ""), ("tornado", "tornadoes or tornados", ""),
    ("domino", "dominoes", ""), ("buffalo", "buffalo or buffaloes", ""), ("quiz", "quizzes", ""), ("bus", "buses", ""),
    ("box", "boxes", ""), ("fox", "foxes", ""), ("church", "churches", ""), ("wish", "wishes", ""),
    ("baby", "babies", ""), ("city", "cities", ""), ("party", "parties", ""), ("key", "keys", ""), ("monkey", "monkeys", ""),
    ("spy", "spies", ""), ("penny", "pennies", "For British money amounts, pence is used."),
    ("passerby", "passersby", ""), ("mother-in-law", "mothers-in-law", ""), ("runner-up", "runners-up", ""),
]


def main():
    taken, keys = load_taken({os.path.abspath(OUT)})
    w = Writer(taken, keys)
    w.tag("school.english.irregular-verbs")
    for base, past, pp, note in VERBS:
        qs = [f"what is the past tense of {base}", f"past tense of {base}", f"what is the past participle of {base}",
              f"{base} in the past tense"]
        if pp != past:
            a = f"The past tense of {base} is {past}, and the past participle is {pp}: \"Yesterday I {past.split(' or ')[0]}\" and \"I have {pp.split(' or ')[0]}\"."
        else:
            a = f"The past tense and past participle of {base} are both {past}."
        if base == "be":
            a = "The past tense of be is was or were, and the past participle is been: \"I was there\" and \"I have been there\"."
        if note:
            a += " " + note
        w.add(qs, a[0].upper() + a[1:])
    w.tag("school.english.irregular-plurals")
    for sing, pl, note in PLURALS:
        qs = [f"what is the plural of {sing}", f"plural of {sing}", f"what is more than one {sing} called",
              f"{sing} plural"]
        if pl == sing:
            a = f"The plural of {sing} is {pl}; it stays the same: one {sing}, two {pl}."
        else:
            a = f"The plural of {sing} is {pl}."
        if note:
            a += " " + note
        w.add(qs, a)
    head = ("# Generated by tools/knowledge/gen/school_wordforms.py (hand-written tables of irregular verbs and plurals).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n = w.write(OUT, head)
    print(f"wrote {n} entries to gen_wordforms.txt")


if __name__ == "__main__":
    main()
