"""The 200 held-out questions for Ace's smartness test.

Run:  python3 tools/smartness_cases.py
It checks every case and writes AceTests/smartness_cases.json, which the
Swift test (AceTests/SmartnessTests.swift) runs against the real brain.

Held out means: no prompt here is a wording in qa_bank.json, and nothing in
the build scripts reads this file. The Swift test checks that again on device.

Expectation kinds:
  bank:    list of answer-bank ids that count as right
  skill:   the name of the skill (intent) Ace should use (with bank too, either counts)
  unknown: Ace should say it doesn't know, or ask what you mean (not guess)
  multi:   list of expectations, one per part, in order
  context: earlier messages in the same chat (for follow-up questions)
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BANK = os.path.join(ROOT, "Ace", "Resources", "qa_bank.json")
OUT = os.path.join(ROOT, "AceTests", "smartness_cases.json")

MARS_MOONS = ["space.how-many-moons-does-mars-have", "space.planet.how-many-moons-does-mars-have"]


def B(*ids):
    return {"bank": list(ids)}


def S(name):
    return {"skill": name}


def BS(name, *ids):
    """Either the skill or one of these answer-bank ids counts as right."""
    return {"bank": list(ids), "skill": name}


U = {"unknown": True}

PARAPHRASE = [
    ("who's the person that made you", B("ace.who-made-you")),
    ("which planet is the largest one", B("space.what-is-the-biggest-planet")),
    ("how many planets does our solar system have", B("space.how-many-planets-are-in-the-solar-system")),
    ("what's the distance from earth to the moon", B("space.how-far-is-the-moon")),
    ("how many bones does a person have", B("body.how-many-bones-are-in-the-human-body")),
    ("at what temperature does water start boiling", B("science.what-temperature-does-water-boil")),
    ("what's the quickest animal in the world", B("animals.what-is-the-fastest-animal")),
    ("which ocean is the biggest on earth", B("earth.what-is-the-biggest-ocean")),
    ("which mountain is the tallest on the planet", B("earth.what-is-the-tallest-mountain")),
    ("who was the very first us president", B("history.who-was-the-first-president-of-the-united-states")),
    ("who came up with the light bulb", B("science.who-invented-the-light-bulb")),
    ("how quick does light travel", B("science.what-is-the-speed-of-light")),
    ("explain what a black hole is", B("space.what-is-a-black-hole")),
    ("can you explain photosynthesis to me", B("science.what-is-photosynthesis")),
    ("how many legs do spiders have", B("animals.how-many-legs-does-a-spider-have")),
    ("what do giant pandas like to eat", B("animals.what-do-pandas-eat")),
    ("which city is japan's capital", B("geo.capital.what-is-the-capital-of-japan")),
    ("which continent is brazil located in", B("geo.continent.what-continent-is-brazil-in")),
    ("what money is used in japan", B("geo.currency.what-is-the-currency-of-japan")),
    ("what's the chemical symbol for gold", B("chem.symbol.what-is-the-symbol-for-gold")),
    ("what number element is oxygen", B("chem.number.what-is-the-atomic-number-of-oxygen")),
    ("give me the opposite word for fast", B("words.opposite.what-is-the-opposite-of-fast")),
    ("what's the name for a baby sheep", B("animals.baby.what-is-a-baby-sheep-called")),
    ("how do spanish people say thank you", BS("translate", "lang.thanks.how-do-you-say-thank-you-in-spanish")),
    ("how many days are there in february", B("time.month.how-many-days-in-february")),
    ("is a tomato actually a fruit or a vegetable", B("food.is-a-tomato-a-fruit")),
    ("how many people play on a soccer team", B("sports.how-many-players-on-a-soccer-team")),
    ("how far is a marathon race", B("sports.how-long-is-a-marathon")),
    ("what's the number to call in an emergency", B("safety.what-is-the-emergency-number")),
    ("is it ok to give my password to my friend", B("safety.should-i-share-my-password")),
    ("how can i get better at studying", B("school.how-do-i-study-better")),
    ("how do i make a crafting table", B("minecraft.how-do-you-make-a-crafting-table-in-minecraft")),
    ("how do i build a portal to the nether", B("minecraft.how-do-you-make-a-nether-portal")),
    ("where can i find diamonds in minecraft", B("minecraft.how-do-you-find-diamonds-in-minecraft", "minecraft.what-level-are-diamonds-in-minecraft")),
    ("what temp should pla be printed at", B("3dprinting.what-temperature-should-i-print-pla-at")),
    ("my 3d print won't stick to the bed", B("3dprinting.why-is-my-print-not-sticking")),
    ("what does a cpu do", B("tech.what-is-a-cpu")),
    ("what does ram stand for", B("tech.what-is-ram")),
    ("how do i screenshot on my ipad", B("tech.how-do-i-take-a-screenshot-on-ipad")),
    ("how can i make my password strong", B("tech.how-do-i-make-a-strong-password")),
    ("what is an llm in ai", B("tech.what-is-an-llm")),
    ("what number is pi equal to", B("math.what-is-pi")),
    ("how many degrees does a triangle add up to", B("math.how-many-degrees-in-a-triangle")),
    ("how many sides are on a hexagon", B("math.how-many-sides-does-a-hexagon-have")),
    ("how do you find the area of a circle", B("math.what-is-the-area-of-a-circle")),
    ("how many feet make up a mile", B("units.how-many-feet-in-a-mile")),
    ("how many grams are in one kilogram", BS("convert", "units.how-many-grams-in-a-kilogram")),
    ("how many seconds are in one hour", BS("convert", "units.how-many-seconds-in-an-hour")),
    ("when did the second world war end", B("history.when-did-world-war-2-end")),
    ("who painted the famous mona lisa", B("history.who-painted-the-mona-lisa")),
    ("when did the titanic go down", B("history.when-did-the-titanic-sink")),
    ("who started apple", B("history.who-founded-apple")),
    ("i'm feeling really sad today", B("feelings.i-m-sad")),
    ("i'm so tired right now", B("feelings.i-m-tired")),
    ("you're really cool", B("feelings.you-re-awesome")),
    ("what are you able to do", B("ace.what-can-you-do")),
    ("do you ever get to sleep", B("ace.do-you-sleep")),
    ("what's your favorite colour ace", B("ace.what-is-your-favorite-color")),
    ("why does the sky look blue", B("space.why-is-the-sky-blue")),
    ("how many moons orbit mars", B(*MARS_MOONS)),
]

TYPOS = [
    ("how many planets are in the solor system", B("space.how-many-planets-are-in-the-solar-system")),
    ("what is the bigest planet", B("space.what-is-the-biggest-planet")),
    ("how far is the moon form earth", B("space.how-far-is-the-moon")),
    ("what is the captial of france", B("geo.capital.what-is-the-capital-of-france")),
    ("what is the capitol of italy", B("geo.capital.what-is-the-capital-of-italy")),
    ("who invented the telephon", B("science.who-invented-the-telephone")),
    ("what is photosynthesys", B("science.what-is-photosynthesis")),
    ("how many bones are in the humen body", B("body.how-many-bones-are-in-the-human-body")),
    ("what is the fastes animal", B("animals.what-is-the-fastest-animal")),
    ("what is a blak hole", B("space.what-is-a-black-hole")),
    ("how do you make a nether portel", B("minecraft.how-do-you-make-a-nether-portal")),
    ("how do you tame a wolfe in minecraft", B("minecraft.how-do-you-tame-a-wolf-in-minecraft")),
    ("what is the speed of lite", B("science.what-is-the-speed-of-light")),
    ("who was albert einstien", B("science.who-was-albert-einstein")),
    ("what is gravaty", B("space.what-is-gravity")),
    ("how many continants are there", B("earth.how-many-continents-are-there")),
    ("what is the longest rivar", B("earth.what-is-the-longest-river")),
    ("what is the tallest animel", B("animals.what-is-the-tallest-animal")),
    ("how many legs does a spidar have", B("animals.how-many-legs-does-a-spider-have")),
    ("what is the symbol for oxygin", B("chem.symbol.what-is-the-symbol-for-oxygen")),
    ("how do you say hello in spanush", BS("translate", "lang.hello.how-do-you-say-hello-in-spanish")),
    ("what is the currancy of japan", B("geo.currency.what-is-the-currency-of-japan")),
    ("who painted the mona lesa", B("history.who-painted-the-mona-lisa")),
    ("what is artifical intelligence", B("tech.what-is-ai")),
    ("what is a leep year", B("units.what-is-a-leap-year")),
    ("whta is a volcano", B("earth.what-is-a-volcano")),
    ("how many teeth do adluts have", B("body.how-many-teeth-do-adults-have")),
    ("what is the hotest planet", B("space.what-is-the-hottest-planet")),
    ("who was the frist person on the moon", B("space.who-was-the-first-person-on-the-moon")),
    ("how do you make a torche in minecraft", B("minecraft.how-do-you-make-a-torch-in-minecraft")),
]

SKILLS = [
    ("good evening to you", S("greeting")),
    ("thanks so much ace", S("thanks")),
    ("ok bye for now", S("goodbye")),
    ("what's the time right now", S("time")),
    ("what's today's date", S("date")),
    ("how many days till christmas", S("daysUntil")),
    ("what's 15 times 4", S("math")),
    ("what is 12 plus 30 divided by 6", S("math")),
    ("convert 5 miles to kilometers", S("convert")),
    ("how many ounces are in 2 pounds", S("convert")),
    ("what's 2024 in roman numerals", S("roman")),
    ("pick a random number between 1 and 50", S("randomNumber")),
    ("how do you spell necessary", S("spell")),
    ("set a timer for 10 minutes", S("timer")),
    ("start a 3 minute pizza timer", S("timer")),
    ("can you time 90 seconds for me", S("timer")),
    ("remind me to feed the dog at 6pm", S("reminder")),
    ("don't let me forget to call grandma tomorrow", S("reminder")),
    ("wake me up at 7", S("alarm")),
    ("add soccer practice to my calendar tomorrow at 4pm", S("calendarAdd")),
    ("what's on my schedule today", S("calendarList")),
    ("am i busy tomorrow", S("calendarList")),
    ("move my dentist appointment to friday", S("calendarEdit")),
    ("delete the meeting on monday", S("calendarDelete")),
    ("open youtube", S("openSite")),
    ("search for lego sets on amazon", S("searchTab")),
    ("give me a recipe for pancakes", S("recipe")),
    ("how do i bake chocolate chip cookies", S("recipe")),
    ("what's the weather like in chicago", S("weather")),
    ("do i need an umbrella today", S("weather")),
    ("how much battery do i have left", S("battery")),
    ("how much storage is left on my ipad", S("storage")),
    ("when should i go to bed tonight", S("bedtime")),
    ("remember that my favorite color is green", S("remember")),
    ("my name is storm", S("setName")),
    ("what's my favorite color", S("recall")),
    ("shut down my pc", S("pcPower")),
    ("turn on hands free mode", S("handsFree")),
    ("run a check on everything", S("check")),
    ("find my screenshot of the wifi password", S("findScreenshots")),
]

FOLLOW_UPS = [
    (["how many moons does jupiter have"], "what about saturn", B("space.planet.how-many-moons-does-saturn-have")),
    (["how long is a day on mars"], "and on venus?", B("space.planet.how-long-is-a-day-on-venus")),
    (["what is the capital of france"], "what about germany", B("geo.capital.what-is-the-capital-of-germany")),
    (["what is the capital of spain"], "and italy?", B("geo.capital.what-is-the-capital-of-italy")),
    (["what is the symbol for gold"], "what about silver", B("chem.symbol.what-is-the-symbol-for-silver")),
    (["how do you say hello in spanish"], "what about in french", BS("translate", "lang.hello.how-do-you-say-hello-in-french")),
    (["what is the currency of japan"], "how about mexico", B("geo.currency.what-is-the-currency-of-mexico")),
    (["what continent is egypt in"], "what about peru", B("geo.continent.what-continent-is-peru-in")),
    (["what is a baby dog called"], "what about a cat", B("animals.baby.what-is-a-baby-cat-called")),
    (["what sound does a cow make"], "and a duck?", B("animals.sound.what-sound-does-a-duck-make")),
    (["what is the atomic number of carbon"], "what about iron", B("chem.number.what-is-the-atomic-number-of-iron")),
    (["how many days in january"], "what about april", B("time.month.how-many-days-in-april")),
    (["what is the opposite of hot"], "and of big?", B("words.opposite.what-is-the-opposite-of-big")),
    (["tell me about mars"], "how many moons does it have", B(*MARS_MOONS)),
    (["tell me about jupiter"], "how long is a year there", B("space.planet.how-long-is-a-year-on-jupiter")),
    (["what is the capital of canada"], "what continent is it in", B("geo.continent.what-continent-is-canada-in")),
    (["tell me about japan"], "what currency do they use there", B("geo.currency.what-is-the-currency-of-japan")),
    (["what is the symbol for sodium"], "what's its atomic number", B("chem.number.what-is-the-atomic-number-of-sodium")),
    (["who invented the telephone"], "say that again", S("repeatLast")),
    (["what is a black hole"], "tell me more", S("tellMore")),
    (["how many players on a soccer team"], "what about basketball", B("sports.how-many-players-on-a-basketball-team")),
    (["how many legs does a spider have"], "what about an insect", B("animals.how-many-legs-does-an-insect-have")),
    (["how long do dogs live"], "and cats?", B("animals.how-long-do-cats-live")),
    (["what is the capital of texas"], "what about ohio", B("geo.us.what-is-the-capital-of-ohio")),
    (["how many sides does a hexagon have"], "what about an octagon", B("math.how-many-sides-does-an-octagon-have")),
]


def M(*parts):
    return {"multi": list(parts)}


MULTI = [
    ("what is the capital of japan and how many moons does mars have",
     M(B("geo.capital.what-is-the-capital-of-japan"), B(*MARS_MOONS))),
    ("what time is it and what's the weather", M(S("time"), S("weather"))),
    ("how far is the moon, and how hot is the sun", M(B("space.how-far-is-the-moon"), B("space.how-hot-is-the-sun"))),
    ("who invented the telephone and who invented the light bulb",
     M(B("science.who-invented-the-telephone"), B("science.who-invented-the-light-bulb"))),
    ("set a timer for 5 minutes and remind me to stretch at 3pm", M(S("timer"), S("reminder"))),
    ("what's 7 times 8 and what's 9 times 6", M(S("math"), S("math"))),
    ("how many legs does a spider have? how many hearts does an octopus have?",
     M(B("animals.how-many-legs-does-a-spider-have"), B("animals.how-many-hearts-does-an-octopus-have"))),
    ("tell me a joke and then tell me a fun fact", M(B("fun.tell-me-a-joke"), B("fun.tell-me-a-fun-fact"))),
    ("what is the biggest ocean and also what is the longest river",
     M(B("earth.what-is-the-biggest-ocean"), B("earth.what-is-the-longest-river"))),
    ("what's the symbol for iron and what's the symbol for copper",
     M(B("chem.symbol.what-is-the-symbol-for-iron"), B("chem.symbol.what-is-the-symbol-for-copper"))),
    ("how do you say thank you in french and how do you say goodbye in spanish",
     M(BS("translate", "lang.thanks.how-do-you-say-thank-you-in-french"), BS("translate", "lang.bye.how-do-you-say-goodbye-in-spanish"))),
    ("what is gravity. what is friction", M(B("space.what-is-gravity"), B("science.what-is-friction"))),
    ("check my battery and my storage", M(S("battery"), S("storage"))),
    ("who was the first president and when did ww2 end",
     M(B("history.who-was-the-first-president-of-the-united-states"), B("history.when-did-world-war-2-end"))),
    ("what's the date today and how many days until halloween", M(S("date"), S("daysUntil"))),
    ("flip a coin and roll a dice", M(B("fun.flip-a-coin"), B("fun.roll-a-dice"))),
    ("what is a cpu and what is a gpu", M(B("tech.what-is-a-cpu"), B("tech.what-is-a-gpu"))),
    ("how many feet in a mile and how many inches in a foot",
     M(BS("convert", "units.how-many-feet-in-a-mile"), BS("convert", "units.how-many-inches-in-a-foot"))),
    ("what's the capital of australia, what continent is chile in, and what currency does india use",
     M(B("geo.capital.what-is-the-capital-of-australia"), B("geo.continent.what-continent-is-chile-in"),
       B("geo.currency.what-is-the-currency-of-india"))),
    ("open youtube and set a timer for 20 minutes", M(S("openSite"), S("timer"))),
]

UNKNOWN = [
    "what did i eat for breakfast last tuesday",
    "how tall is my neighbor's dog",
    "what's the password to my school wifi",
    "who will win the game tonight",
    "what color socks am i wearing",
    "how many grains of sand are on my street",
    "what is the flibbergast of a zorbnak",
    "blorp snazzle wump",
    "what's my teacher's middle name",
    "how many jellybeans are in the jar at school",
    "is my friend jake mad at me",
    "what number am i thinking of",
    "how much does my backpack weigh",
    "what will the stock market do next year",
    "describe the smell of purple",
    "what's the score of the game right now",
    "who lives at the house next door",
    "translate this into klingon",
    "what is the gloopiest planet in the qwerty galaxy",
    "how many minecraft blocks tall is my house",
    "what happened in my dream last night",
    "which of my friends likes pizza the most",
    "what's the wifi password at grandma's house",
    "how fast can my bike go downhill",
    "what are the lyrics to the song i made up yesterday",
]


# Saying Ace's name (alone or with a hello) means "are you there?", never a web search.
NAME_CALLS = ["ace", "you there ace?", "hey ace", "yo ace", "hi ace!", "ok ace", "hello ace", "ace are you there"]

# Room for the name calls: the last two cases of four lists go, so there are still 200.
PARAPHRASE = PARAPHRASE[:-2]
TYPOS = TYPOS[:-2]
SKILLS = SKILLS[:-2]
UNKNOWN = UNKNOWN[:-2]


def build():
    cases = []

    def add(category, prompt, expect, context=None):
        c = {"n": len(cases) + 1, "category": category, "prompt": prompt, "expect": expect}
        if context:
            c["context"] = context
        cases.append(c)

    for p, e in PARAPHRASE:
        add("paraphrase", p, e)
    for p, e in TYPOS:
        add("typo", p, e)
    for p, e in SKILLS:
        add("skill", p, e)
    for ctx, p, e in FOLLOW_UPS:
        add("follow-up", p, e, ctx)
    for p, e in MULTI:
        add("multi-part", p, e)
    for p in UNKNOWN:
        add("unknown", p, U)
    for p in NAME_CALLS:
        add("name-call", p, S("summon"))
    return cases


def norm(s):
    """Close to TextKit.normalize: lowercase, expand a few contractions, drop punctuation."""
    s = s.lower().replace("’", "'")
    words = []
    for w in s.split():
        w = w.strip("?!,;:\"()[]{}")
        words.append({"what's": "what is", "whats": "what is", "who's": "who is", "it's": "it is",
                      "i'm": "i am", "im": "i am", "you're": "you are", "don't": "do not"}.get(w, w))
    s = " ".join(words)
    s = re.sub(r"[^\w\s+\-*/.%'#&]", " ", s)
    return re.sub(r"\s+", " ", s).strip().strip(".")


def check(cases):
    bank = json.load(open(BANK))["entries"]
    ids = {e["id"] for e in bank}
    wordings = {norm(q) for e in bank for q in e["q"]}
    problems = []
    seen = set()

    def ids_in(exp):
        if "bank" in exp:
            return exp["bank"]
        if "multi" in exp:
            return [i for p in exp["multi"] for i in ids_in(p)]
        return []

    for c in cases:
        n = norm(c["prompt"])
        if n in seen:
            problems.append(f"#{c['n']} repeats another prompt")
        seen.add(n)
        if n in wordings:
            problems.append(f"#{c['n']} is in the answer bank, so it isn't held out: {c['prompt']}")
        for i in ids_in(c["expect"]):
            if i not in ids:
                problems.append(f"#{c['n']} expects a missing id: {i}")
    if len(cases) != 200:
        problems.append(f"there are {len(cases)} cases, not 200")
    return problems


if __name__ == "__main__":
    cases = build()
    problems = check(cases)
    for p in problems:
        print("PROBLEM:", p)
    if problems:
        sys.exit(1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"format": "ace-smartness/1", "count": len(cases), "cases": cases}, f, indent=1)
        f.write("\n")
    by = {}
    for c in cases:
        by[c["category"]] = by.get(c["category"], 0) + 1
    print(f"Wrote {len(cases)} held-out cases to {os.path.relpath(OUT, ROOT)}: {by}")
