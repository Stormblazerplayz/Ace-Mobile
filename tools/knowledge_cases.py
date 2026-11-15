"""100 never-seen questions in Storm's style for Ace's big knowledge pack.

Written Nov 15, 2026, BEFORE any of the new knowledge was added, so the before and
after scores are honest. Don't change these after seeing a score. Write a new set instead.

Run:  python3 tools/knowledge_cases.py
Writes AceTests/knowledge_cases.json, which AceTests/KnowledgeTests.swift runs against
the real brain and prints as "KNOWLEDGE SCORE".

Each case passes when Ace picks an answer (sure or a guess) whose text has the right facts:
  has:    a list of groups. Every group needs at least one of its strings in the answer
          (not case sensitive). [["Lima"]] means the answer must say Lima.
  skill:  this skill also counts as right (like "script" for "make a part spin in roblox").
  unknown: Ace should say it doesn't know or ask what you mean, not guess.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "AceTests", "knowledge_cases.json")


def H(*groups, skill=None):
    e = {"has": [list(g) if isinstance(g, (list, tuple)) else [g] for g in groups]}
    if skill:
        e["skill"] = skill
    return e


U = {"unknown": True}

CASES = [
    # Math
    ("math", "how do you find the area of a triangle", H("base", "height", ("half", "divide", "/ 2", "÷ 2", "/2", "÷2", "1/2", "½"))),
    ("math", "whats the formula for the circumference of a circle", H("circumference", ("pi", "π"))),
    ("math", "what is a prime number", H(("itself", "two factors", "only two"))),
    ("math", "what is the pythagorean theorem", H(("hypotenuse", "a² + b²", "a^2 + b^2", "a squared"))),
    ("math", "how many sides does a heptagon have", H(("7", "seven"))),
    ("math", "what is pemdas", H("parenthes", "exponent")),
    ("math", "whats the difference between mean median and mode", H("median", "middle")),
    ("math", "how do you divide fractions", H(("flip", "reciprocal", "invert", "upside down"))),
    ("math", "what is a right angle", H("90")),
    ("math", "what is a variable in algebra", H(("letter", "symbol", "unknown"))),
    # Science
    ("science", "what does the mitochondria do", H(("energy", "powerhouse", "atp"))),
    ("science", "what are the three states of matter", H("solid", "liquid", "gas")),
    ("science", "what is newtons second law", H(("f = ma", "f=ma", "mass times acceleration", "mass × acceleration", "mass x acceleration"))),
    ("science", "what is the chemical formula for table salt", H("nacl")),
    ("science", "what is an atom made of", H("proton", "neutron", "electron")),
    ("science", "what is the difference between weather and climate", H("climate", ("years", "long-term", "long term", "over a long"))),
    ("science", "how many chromosomes do humans have", H(("46", "23 pairs"))),
    ("science", "what planet has the most moons", H("saturn")),
    ("science", "what is the atomic number of carbon", H("carbon", "6")),
    ("science", "what causes earthquakes", H(("plate", "fault"))),
    ("science", "what is a food chain", H(("energy", "eats", "eaten", "producer"))),
    ("science", "what is the boiling point of water in fahrenheit", H("212")),
    # History
    ("history", "who was the 16th president", H("lincoln")),
    ("history", "when did world war 2 end", H("1945")),
    ("history", "who discovered penicillin", H("fleming")),
    ("history", "what was the renaissance", H(("rebirth", "art", "italy"))),
    ("history", "when did the titanic sink", H("1912")),
    ("history", "who was cleopatra", H("egypt")),
    ("history", "what was the cold war", H(("soviet", "ussr"))),
    ("history", "who wrote the declaration of independence", H("jefferson")),
    # World facts
    ("world", "whats the capital of peru", H("lima")),
    ("world", "what currency does japan use", H("yen")),
    ("world", "what language do they speak in brazil", H("portuguese")),
    ("world", "what is the leader of germany called", H("chancellor")),
    ("world", "what currency does switzerland use", H("franc")),
    ("world", "whats the capital of australia", H("canberra")),
    ("world", "what continent is egypt in", H("africa")),
    ("world", "what is the longest river in the world", H("nile")),
    ("world", "how many states are in the us", H("50")),
    ("world", "what is the capital of texas", H("austin")),
    ("world", "what language is spoken in iran", H(("persian", "farsi"))),
    ("world", "what is the smallest country in the world", H("vatican")),
    ("world", "what country has the most people", H("india")),
    ("world", "what is the leader of japan called", H("prime minister")),
    # English
    ("english", "what is a noun", H("person", "place", "thing")),
    ("english", "what is an adverb", H("verb", ("how", "describes", "modifies"))),
    ("english", "whats the difference between their there and they're", H("they are")),
    ("english", "what is a simile", H("simile", "like")),
    ("english", "what does protagonist mean", H("main character")),
    ("english", "what is a haiku", H(("syllable", "5-7-5", "5, 7"))),
    ("english", "who wrote romeo and juliet", H("shakespeare")),
    ("english", "what does ubiquitous mean", H("everywhere")),
    # Coding
    ("coding", "how do i make a part spin in roblox", H(("rotat", "cframe", "angularvelocity", "spin"), skill="script")),
    ("coding", "what is a remote event in roblox", H("server", "client")),
    ("coding", "what does task.wait do in roblox", H(("second", "pause", "yield"))),
    ("coding", "how do i make a leaderboard in roblox", H("leaderstats", skill="script")),
    ("coding", "whats the difference between a script and a local script in roblox", H("client", "server")),
    ("coding", "what does print do in python", H("print", ("screen", "console", "output", "shows", "displays"))),
    ("coding", "how do you make a list in python", H(("[", "square bracket"))),
    ("coding", "what is a for loop", H(("repeat", "each item", "every item", "over and over"))),
    ("coding", "what does len do in python", H(("length", "how many"))),
    ("coding", "what is swiftui", H("apple", ("interface", "ui", "view"))),
    ("coding", "what does var mean in swift", H("variable", "change")),
    ("coding", "what is a pointer in c++", H(("address", "memory"))),
    ("coding", "what does #include do in c++", H(("header", "library", "file"))),
    ("coding", "what does void setup do in arduino", H("once")),
    ("coding", "what is pinmode in arduino", H(("input", "output"))),
    ("coding", "what is an api", H("application programming interface")),
    # How-to and everyday life
    ("how-to", "how do you tie a tie", H("knot")),
    ("how-to", "how do i get gum out of hair", H(("peanut butter", "oil", "ice"))),
    ("how-to", "how long should you boil an egg", H("minute", skill="recipe")),
    ("how-to", "how do i stop a nosebleed", H(("lean forward", "pinch"))),
    ("how-to", "how do you do cpr", H(("chest", "compress", "911"))),
    ("how-to", "how much should i tip at a restaurant", H(("15", "20"))),
    ("how-to", "how do you get rid of hiccups", H(("breath", "water", "sugar"))),
    ("how-to", "how do i save money", H(("budget", "goal", "jar", "savings account"))),
    # PC and tech help
    ("tech", "how do i take a screenshot on windows", H(("prtscn", "print screen", "shift + s", "snipping"))),
    ("tech", "whats the shortcut to undo", H(("ctrl + z", "ctrl+z", "command + z", "cmd + z"))),
    ("tech", "how do i check my gpu temperature", H(("task manager", "hwmonitor", "afterburner", "hwinfo", "gpu-z"))),
    ("tech", "what is ram", H("memory")),
    ("tech", "why is my pc so slow", H(("startup", "task manager", "background", "restart"))),
    ("tech", "how do i update my graphics drivers", H("driver", ("nvidia", "amd", "intel", "device manager", "geforce", "adrenalin"))),
    ("tech", "how do i force quit an app on windows", H(("task manager", "alt + f4", "ctrl + shift + esc"))),
    ("tech", "what does a cpu do", H(("instruction", "brain", "calculation"))),
    # Games
    ("games", "how much health does a creeper have", H(("20", "10 hearts"))),
    ("games", "how do you make a nether portal", H("obsidian")),
    ("games", "what do you need to make a beacon in minecraft", H("nether star")),
    ("games", "how do you tame a wolf in minecraft", H("bone")),
    ("games", "what does the mending enchantment do", H(("experience", "xp", "durability", "repair"))),
    ("games", "what type is gengar", H("ghost", "poison")),
    ("games", "what does pikachu evolve into", H("raichu")),
    ("games", "what is robux", H(("currency", "money"))),
    # Cooking
    ("cooking", "how many tablespoons are in a cup", H("16", skill="convert")),
    ("cooking", "what can i use instead of eggs in baking", H(("banana", "applesauce", "flax"))),
    ("cooking", "what temperature should chicken be cooked to", H(("165", "74"))),
    # Things Ace can't know (it should say so, not guess)
    ("unknown", "what's my teacher's name", U),
    ("unknown", "how many pencils are in my backpack", U),
    ("unknown", "what did my dog eat today", U),
    ("unknown", "what game am i going to play tonight", U),
    ("unknown", "where did i leave my headphones", U),
]


def main():
    assert len(CASES) == 100, len(CASES)
    prompts = [c[1] for c in CASES]
    assert len(set(prompts)) == 100, "two cases are the same"
    out = {"format": "ace-knowledge-cases/1", "count": 100, "cases": []}
    for i, (category, prompt, expect) in enumerate(CASES, 1):
        out["cases"].append({"n": i, "category": category, "prompt": prompt, "expect": expect})
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"wrote {len(CASES)} cases to {os.path.relpath(OUT, os.path.join(HERE, '..'))}")


if __name__ == "__main__":
    main()
