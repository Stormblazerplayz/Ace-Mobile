#!/usr/bin/env python3
"""Writes data/school/gen_affixes.txt: meanings of common English prefixes, suffixes and Greek/Latin roots,
each with example words.

Source: no outside data. The table below is written by hand from standard school word-study lists
(meanings checked against ordinary dictionary etymologies). Public domain facts, no license needed.

Run from the repo root:  python3 tools/knowledge/gen/school_affixes.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from school_math import KNOW, Writer, load_taken  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_affixes.txt")

# prefix, meaning, examples (word = gloss), extra note
PREFIXES = [
    ("un", "not, or the opposite of", "unhappy (not happy), untie (the opposite of tie)", ""),
    ("re", "again or back", "redo (do again), return (turn back)", ""),
    ("dis", "not, or the opposite of", "disagree, dishonest, disappear", ""),
    ("pre", "before", "preview (see before), preheat, prehistoric", ""),
    ("post", "after", "postpone, postwar, postscript (P.S., written after)", ""),
    ("mis", "wrongly or badly", "misspell, misunderstand, mislead", ""),
    ("non", "not", "nonfiction, nonstop, nonsense", ""),
    ("in", "not, or into", "invisible (not visible), inactive, include (shut into)", "It changes to im- before b, m and p (impossible), il- before l (illegal) and ir- before r (irregular)."),
    ("im", "not, or into", "impossible, impatient, import (carry into)", "It's a form of in- used before b, m and p."),
    ("il", "not", "illegal, illogical, illiterate", "It's a form of in- used before l."),
    ("ir", "not", "irregular, irresponsible, irrelevant", "It's a form of in- used before r."),
    ("sub", "under or below", "submarine (under the sea), subway, subtract", ""),
    ("super", "above, over or extra", "superhero, superstar, supervise", ""),
    ("inter", "between or among", "international, internet, interrupt", ""),
    ("intra", "within", "intramural (within one school), intravenous (within a vein)", ""),
    ("trans", "across or beyond", "transport (carry across), transatlantic, translate", ""),
    ("anti", "against", "antibiotic, antifreeze, antisocial", ""),
    ("auto", "self", "autobiography, autograph, automatic", ""),
    ("bi", "two", "bicycle, bilingual, biweekly", ""),
    ("tri", "three", "triangle, tricycle, trilogy", ""),
    ("uni", "one", "unicycle, uniform, unicorn", ""),
    ("mono", "one or single", "monorail, monologue, monotone", ""),
    ("multi", "many", "multiply, multicolored, multimedia", ""),
    ("poly", "many", "polygon, polyester, polytheism", ""),
    ("semi", "half or partly", "semicircle, semifinal, semicolon", ""),
    ("hemi", "half", "hemisphere", ""),
    ("micro", "very small", "microscope, microphone, microwave", ""),
    ("mega", "very large, or one million", "megaphone, megabyte", ""),
    ("over", "too much or above", "overeat, overflow, overhead", ""),
    ("under", "too little or below", "underpaid, underground, underline", ""),
    ("ex", "out of, or former", "exit, export, ex-president", ""),
    ("de", "down, away or the opposite of", "descend, defrost, deactivate", ""),
    ("co", "together or with", "cooperate, coworker, coexist", ""),
    ("com", "together or with", "combine, compare, compose", "It's also written con-, as in connect, and col- or cor-, as in collect and correspond."),
    ("counter", "against or opposite", "counterclockwise, counterattack", ""),
    ("fore", "before or in front", "forecast, foresee, forehead", ""),
    ("mid", "middle", "midnight, midway, midsummer", ""),
    ("out", "better than, or outside", "outrun, outdo, outdoor", ""),
    ("tele", "far or distant", "telephone, television, telescope", ""),
    ("bio", "life", "biology, biography, biome", ""),
    ("geo", "earth", "geography, geology, geometry (earth measuring)", ""),
    ("hydro", "water", "hydrant, hydroelectric, dehydrate", ""),
    ("photo", "light", "photograph, photosynthesis", ""),
    ("therm", "heat", "thermometer, thermos, thermal", ""),
    ("circum", "around", "circumference, circumnavigate", ""),
    ("ultra", "beyond or extremely", "ultraviolet, ultrasound", ""),
    ("hyper", "over or too much", "hyperactive, hyperlink", ""),
    ("hypo", "under or too little", "hypothermia, hypodermic (under the skin)", ""),
    ("pro", "forward or in favor of", "proceed (go forward), propel, pro-environment", ""),
    ("en", "to make or put into", "enlarge (make large), encourage, endanger", "Before b and p it's often em-, as in empower."),
    ("mal", "bad or badly", "malfunction, malnutrition", ""),
    ("bene", "good or well", "benefit, benevolent", ""),
    ("omni", "all", "omnivore (eats all), omnipresent", ""),
    ("pan", "all", "pandemic, panorama", ""),
    ("quad", "four", "quadrilateral, quadruple", ""),
    ("pent", "five", "pentagon, pentathlon", ""),
    ("hex", "six", "hexagon", ""),
    ("oct", "eight", "octagon, octopus, octave", ""),
    ("dec", "ten", "decade, decagon, decimal", ""),
    ("cent", "hundred", "century, centipede, centimeter (a hundredth of a meter)", ""),
    ("milli", "thousand or thousandth", "millimeter, millennium", ""),
    ("kilo", "thousand", "kilogram, kilometer", ""),
    ("ab", "away from", "absent, abnormal", ""),
    ("ad", "to or toward", "adhere, advance", ""),
    ("a", "not or without", "atypical, asymmetrical", "It can also mean on or in, as in asleep and aboard."),
    ("neo", "new", "neon, neonatal", ""),
    ("pseudo", "false", "pseudonym (a false name)", ""),
    ("retro", "backward", "retro, retrospect, retroactive", ""),
    ("self", "yourself, by yourself", "self-control, self-portrait", ""),
]

SUFFIXES = [
    ("able", "can be done, or worth", "readable, washable, comfortable", "-ible means the same: visible, flexible."),
    ("ible", "can be done", "visible, flexible, edible", "-able means the same and is more common."),
    ("ful", "full of", "joyful, careful, helpful", "As a suffix it always has one l."),
    ("less", "without", "fearless, careless, hopeless", ""),
    ("ness", "a state or quality", "happiness, kindness, darkness", "It turns adjectives into nouns."),
    ("ment", "an action or result", "movement, enjoyment, agreement", "It turns verbs into nouns."),
    ("tion", "an act or state", "action, celebration, education", "-sion works the same way: decision, explosion."),
    ("sion", "an act or state", "decision, explosion, confusion", ""),
    ("er", "a person who, or more", "teacher, player (people); taller, faster (more)", ""),
    ("or", "a person who", "actor, inventor, sailor", ""),
    ("ist", "a person who does or believes", "artist, scientist, cyclist", ""),
    ("ian", "a person who is skilled in or from", "musician, librarian, Canadian", ""),
    ("est", "the most", "biggest, fastest, smartest", ""),
    ("ly", "in a certain way", "quickly, sadly, quietly", "It usually turns adjectives into adverbs."),
    ("y", "full of or like", "rainy, sandy, cloudy", ""),
    ("ous", "full of or having", "dangerous, famous, joyous", ""),
    ("ive", "tending to", "active, creative, expensive", ""),
    ("al", "relating to", "musical, natural, personal", "It can also make nouns from verbs: arrival, refusal."),
    ("ic", "relating to", "athletic, poetic, scientific", ""),
    ("ish", "somewhat or like", "childish, reddish, foolish", "It can also mean from a place: English, Spanish."),
    ("ize", "to make or become", "realize, organize, modernize", "British English often spells it -ise."),
    ("ify", "to make", "simplify, beautify, classify", ""),
    ("en", "to make", "brighten, darken, widen", ""),
    ("ed", "past tense", "jumped, played, walked", "It also makes past participles used as adjectives: a broken toy, a tired dog."),
    ("ing", "an action happening now", "running, singing, reading", "It also makes gerunds and present participles."),
    ("s", "more than one", "cats, books, chairs", "Use -es after s, x, z, ch and sh: boxes, wishes."),
    ("hood", "a state or group", "childhood, neighborhood, brotherhood", ""),
    ("ship", "a state or skill", "friendship, leadership, championship", ""),
    ("dom", "a state or realm", "freedom, kingdom, boredom", ""),
    ("ology", "the study of", "biology, geology, zoology", ""),
    ("phobia", "fear of", "arachnophobia (fear of spiders), claustrophobia", ""),
    ("ward", "in the direction of", "forward, backward, toward", ""),
    ("wise", "in the way of", "clockwise, otherwise, likewise", ""),
    ("ity", "a state or quality", "ability, reality, curiosity", ""),
    ("ance", "an action or state", "performance, appearance, assistance", "-ence works the same way: difference, patience."),
    ("ence", "an action or state", "difference, patience, existence", ""),
    ("ant", "a person or thing that does, or being", "assistant, servant, pleasant", ""),
    ("ent", "a person or thing that does, or being", "student, resident, different", ""),
    ("ary", "relating to, or a place for", "dictionary, library, imaginary", ""),
    ("ology", "the study of", "biology", ""),
    ("cide", "killing", "insecticide, pesticide", ""),
    ("ee", "a person who receives", "employee, trainee, refugee", ""),
    ("let", "small", "booklet, piglet, droplet", ""),
    ("ling", "small or young", "duckling, seedling", ""),
    ("meter", "a measuring tool", "thermometer, speedometer", ""),
    ("scope", "a viewing tool", "telescope, microscope, periscope", ""),
    ("graph", "something written or drawn", "autograph, paragraph, photograph", ""),
    ("phone", "sound", "telephone, microphone, saxophone", ""),
]

# root, origin, meaning, examples
ROOTS = [
    ("aud", "Latin", "hear", "audio, audience, audible"),
    ("vis", "Latin", "see", "visible, vision, visit"),
    ("vid", "Latin", "see", "video, evidence, provide"),
    ("spect", "Latin", "look", "inspect, spectator, respect"),
    ("dict", "Latin", "say or speak", "dictionary, predict, contradict"),
    ("scrib", "Latin", "write", "scribble, describe, prescribe"),
    ("script", "Latin", "write", "script, manuscript, transcript"),
    ("port", "Latin", "carry", "transport, portable, export"),
    ("rupt", "Latin", "break", "erupt, interrupt, bankrupt"),
    ("struct", "Latin", "build", "construct, structure, instruct"),
    ("tract", "Latin", "pull or drag", "tractor, attract, subtract"),
    ("ject", "Latin", "throw", "eject, project, reject"),
    ("form", "Latin", "shape", "transform, uniform, formation"),
    ("mit", "Latin", "send", "transmit, submit, emit"),
    ("miss", "Latin", "send", "mission, missile, dismiss"),
    ("duc", "Latin", "lead", "conduct, produce, educate"),
    ("duct", "Latin", "lead", "conduct, product, aqueduct"),
    ("fer", "Latin", "carry or bear", "transfer, ferry, refer"),
    ("pel", "Latin", "push or drive", "propel, repel, expel"),
    ("pend", "Latin", "hang or weigh", "pendant, pendulum, depend"),
    ("cred", "Latin", "believe", "credible, incredible, credit"),
    ("fid", "Latin", "faith or trust", "confident, fidelity"),
    ("ver", "Latin", "true", "verify, verdict, very"),
    ("ped", "Latin", "foot", "pedal, pedestrian, centipede"),
    ("pod", "Greek", "foot", "tripod, podium, arthropod"),
    ("man", "Latin", "hand", "manual, manufacture, manicure"),
    ("cap", "Latin", "head", "captain, capital, cap"),
    ("corp", "Latin", "body", "corpse, corporation"),
    ("mort", "Latin", "death", "mortal, immortal, mortality"),
    ("viv", "Latin", "live", "survive, vivid, revive"),
    ("vit", "Latin", "life", "vital, vitamin, vitality"),
    ("aqua", "Latin", "water", "aquarium, aquatic, aqueduct"),
    ("terr", "Latin", "earth or land", "territory, terrain, terrestrial"),
    ("sol", "Latin", "sun", "solar, solstice, parasol"),
    ("luna", "Latin", "moon", "lunar"),
    ("stell", "Latin", "star", "stellar, constellation"),
    ("astr", "Greek", "star", "astronaut, astronomy, asterisk"),
    ("cycl", "Greek", "circle or wheel", "bicycle, cycle, cyclone"),
    ("chron", "Greek", "time", "chronological, chronicle, synchronize"),
    ("graph", "Greek", "write or draw", "graphic, autograph, biography"),
    ("gram", "Greek", "something written", "diagram, telegram, grammar"),
    ("log", "Greek", "word or study", "dialogue, logic, biology"),
    ("phon", "Greek", "sound", "phonics, symphony, telephone"),
    ("phot", "Greek", "light", "photo, photon, photosynthesis"),
    ("scop", "Greek", "look at", "microscope, telescope, horoscope"),
    ("meter", "Greek", "measure", "thermometer, perimeter, diameter"),
    ("path", "Greek", "feeling or suffering", "sympathy, empathy, pathetic"),
    ("phil", "Greek", "love", "philosophy (love of wisdom), philanthropist"),
    ("psych", "Greek", "mind", "psychology, psychic"),
    ("dem", "Greek", "people", "democracy, epidemic"),
    ("crat", "Greek", "rule", "democrat, aristocrat, bureaucrat"),
    ("morph", "Greek", "shape", "metamorphosis, morph"),
    ("derm", "Greek", "skin", "dermatologist, epidermis"),
    ("dent", "Latin", "tooth", "dentist, dental, indent"),
    ("bibl", "Greek", "book", "bibliography"),
    ("zoo", "Greek", "animal", "zoology, zoo"),
    ("anthrop", "Greek", "human", "anthropology, philanthropy"),
    ("techn", "Greek", "skill or art", "technology, technique"),
    ("mech", "Greek", "machine", "mechanic, mechanism"),
    ("kine", "Greek", "movement", "kinetic, cinema"),
    ("mob", "Latin", "move", "mobile, automobile"),
    ("mot", "Latin", "move", "motor, motion, promote"),
    ("voc", "Latin", "voice or call", "vocal, vocabulary, advocate"),
    ("loc", "Latin", "place", "location, local, locate"),
    ("sect", "Latin", "cut", "dissect, section, insect"),
    ("junct", "Latin", "join", "junction, conjunction"),
    ("ten", "Latin", "hold", "tenant, contain, retain"),
    ("cept", "Latin", "take", "accept, intercept, concept"),
    ("fract", "Latin", "break", "fraction, fracture"),
    ("grad", "Latin", "step", "gradual, graduate, grade"),
    ("gress", "Latin", "step or go", "progress, aggressive"),
    ("sist", "Latin", "stand", "assist, consist, resist"),
    ("spir", "Latin", "breathe", "inspire, respiration, expire"),
    ("sens", "Latin", "feel", "sense, sensitive, sensor"),
    ("son", "Latin", "sound", "sonic, unison, sonar"),
    ("tempor", "Latin", "time", "temporary, contemporary"),
    ("urb", "Latin", "city", "urban, suburb"),
    ("liber", "Latin", "free", "liberty, liberate"),
    ("leg", "Latin", "law, or read", "legal, legislate, legible"),
    ("jud", "Latin", "judge", "judge, judicial, prejudice"),
    ("frag", "Latin", "break", "fragile, fragment"),
    ("nov", "Latin", "new", "novel, novice, innovate"),
    ("magn", "Latin", "great or large", "magnify, magnificent"),
    ("ami", "Latin", "friend or love", "amiable, amicable"),
    ("bell", "Latin", "war", "rebel, belligerent"),
    ("pac", "Latin", "peace", "pacify, Pacific"),
    ("migr", "Latin", "move or travel", "migrate, immigrant"),
    ("clam", "Latin", "shout", "exclaim, proclaim"),
    ("flect", "Latin", "bend", "reflect, deflect"),
    ("flex", "Latin", "bend", "flexible, reflex"),
    ("rad", "Latin", "ray", "radius, radiate, radio"),
    ("fort", "Latin", "strong", "fort, fortify, comfort"),
    ("solv", "Latin", "loosen", "solve, dissolve, solvent"),
    ("vert", "Latin", "turn", "convert, reverse, vertical"),
    ("vers", "Latin", "turn", "reverse, version, universe"),
]


def plain(meaning):
    return meaning


def main():
    taken, keys = load_taken({os.path.abspath(OUT)})
    w = Writer(taken, keys)
    w.tag("school.english.prefixes")
    for p, meaning, ex, note in PREFIXES:
        qs = [f"what does the prefix {p} mean", f"prefix {p} meaning", f"what does {p} mean as a prefix",
              f"words with the prefix {p}"]
        a = f"The prefix {p}- means {meaning}. Examples: {ex}."
        if note:
            a += " " + note
        w.add(qs, a)
    w.tag("school.english.suffixes")
    seen = set()
    for s, meaning, ex, note in SUFFIXES:
        if s in seen:
            continue
        seen.add(s)
        qs = [f"what does the suffix {s} mean", f"suffix {s} meaning", f"what does {s} mean as a suffix",
              f"words with the suffix {s}"]
        a = f"The suffix -{s} means {meaning}. Examples: {ex}."
        if note:
            a += " " + note
        w.add(qs, a)
    w.tag("school.english.roots")
    for r, origin, meaning, ex in ROOTS:
        qs = [f"what does the root {r} mean", f"root word {r} meaning", f"what does {r} mean as a root",
              f"words with the root {r}"]
        a = f"The {origin} root {r} means \"{meaning}\". You see it in {ex}."
        w.add(qs, a)
    head = ("# Generated by tools/knowledge/gen/school_affixes.py (hand-written table of prefixes, suffixes and roots).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n = w.write(OUT, head)
    print(f"wrote {n} entries to gen_affixes.txt")


if __name__ == "__main__":
    main()
