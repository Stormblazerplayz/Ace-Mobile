"""20 different ways to say each answer in Ace's bank.

build_qa_bank.py calls these. Every answer family has 20 hand-written templates
that keep the same facts, so Ace can say the same thing 20 ways without ever
changing what it means. Hand-written answers get 20 versions by wrapping the
original wording in friendly openers and closers (the facts stay word for word).
"""

COUNT = 20


def cap(s):
    return s[0].upper() + s[1:] if s else s


def poss(name):
    """'Japan' -> "Japan's", 'the United States' -> "the United States'"."""
    return name + ("'" if name.endswith("s") else "'s")


def _fill(templates, facts):
    if len(templates) != COUNT:
        raise ValueError(f"need {COUNT} templates, got {len(templates)}: {templates[0]}")
    out = []
    for t in templates:
        s = t.format(**facts)
        s = cap(s)
        if s in out:
            raise ValueError(f"duplicate answer: {s}")
        out.append(s)
    return out


# ---------- countries ----------
CAPITAL = [
    "The capital of {nice} is {capital}.",
    "{capital} is the capital of {nice}.",
    "{Poss} capital is {capital}.",
    "It's {capital}.",
    "{capital}! That's the capital of {nice}.",
    "The capital city of {nice} is {capital}.",
    "{Nice} has {capital} as its capital.",
    "That would be {capital}, the capital of {nice}.",
    "{capital} is {poss} capital city.",
    "If you visit the capital of {nice}, you'll be in {capital}.",
    "The answer is {capital}.",
    "{capital}, in {continent}, is the capital of {nice}.",
    "Easy one: {capital} is the capital of {nice}.",
    "{Nice}? Its capital is {capital}.",
    "Capital of {nice}: {capital}.",
    "It's {capital}, the capital of {nice}.",
    "You're looking for {capital}. It's the capital of {nice}.",
    "Ask anyone from {nice} and they'll tell you the capital is {capital}.",
    "The capital of {nice}? That's {capital}.",
    "{Poss} capital city is {capital}, over in {continent}.",
]

CAPITAL_OF = [
    "{capital} is the capital of {nice}, in {continent}.",
    "{capital} is in {nice}. It's the capital there.",
    "That's {nice}. {capital} is its capital, and it's in {continent}.",
    "{capital} is the capital city of {nice}, a country in {continent}.",
    "{Nice}! {capital} is its capital.",
    "You'll find {capital} in {nice}, in {continent}. It's the capital.",
    "{capital} belongs to {nice}. It's the capital, over in {continent}.",
    "It's {nice}. {capital} is the capital city.",
    "{capital} is {poss} capital, in {continent}.",
    "The country is {nice}, and {capital} is its capital.",
    "{capital}? That's the capital of {nice}.",
    "{Nice}, in {continent}. {capital} is the capital.",
    "{capital} is the capital of {nice}.",
    "Capital {capital} is in {nice}, a country in {continent}.",
    "That one's {nice}. Its capital is {capital}.",
    "{capital} sits in {nice}, and it's the capital city there.",
    "{Nice} is the country. Its capital is {capital}, and it's in {continent}.",
    "{capital} is in {continent}. It's the capital of {nice}.",
    "Easy: {capital} is the capital of {nice}.",
    "If you're in {capital}, you're in the capital of {nice}.",
]

CONTINENT = [
    "{Nice} is in {continent}.",
    "You'll find {nice} in {continent}.",
    "{Nice} is a country in {continent}.",
    "It's in {continent}.",
    "{continent}! That's where {nice} is.",
    "{Nice} is part of {continent}.",
    "{Nice} is on the continent of {continent}.",
    "The continent is {continent}.",
    "{Nice} sits in {continent}.",
    "Look in {continent}. That's where {nice} is.",
    "{Nice}? That's in {continent}.",
    "It's a {continent} country.",
    "{Nice} is located in {continent}.",
    "{continent} is the continent {nice} is in.",
    "On a map, {nice} is in {continent}.",
    "{Nice} is one of the countries in {continent}.",
    "That would be {continent}.",
    "{Nice} belongs to {continent}.",
    "{Nice} is in {continent}, and its capital is {capital}.",
    "If you flew to {nice}, you'd land in {continent}.",
]

COUNTRY = [
    "{Nice} is a country in {continent}. Its capital is {capital}.{money}",
    "{Nice} is in {continent}, and its capital is {capital}.{money}",
    "Here's {nice}: it's in {continent}, with {capital} as its capital.{money}",
    "{Nice} is a {continent} country. The capital is {capital}.{money}",
    "Quick facts: {nice} is in {continent}. Capital: {capital}.{money}",
    "{Nice}'s capital is {capital}, and the country is in {continent}.{money}",
    "{Nice} sits in {continent}, and {capital} is the capital city.{money}",
    "Let's see. {Nice} is in {continent}, and {capital} is the capital.{money}",
    "{capital} is the capital of {nice}, a country in {continent}.{money}",
    "You'll find {nice} in {continent}. Its capital city is {capital}.{money}",
    "{Nice} is part of {continent}. The capital is {capital}.{money}",
    "{Nice}: a country in {continent} with its capital in {capital}.{money}",
    "About {nice}: it's in {continent}, and the capital is {capital}.{money}",
    "{Nice} is one of the countries in {continent}. Its capital is {capital}.{money}",
    "Here's what I know about {nice}. It's in {continent}, and its capital is {capital}.{money}",
    "{Nice} is located in {continent}, with {capital} as the capital city.{money}",
    "Sure! {Nice} is in {continent}. Its capital is {capital}.{money}",
    "{Nice} is a country in {continent}, and {capital} is its capital city.{money}",
    "The country of {nice} is in {continent}. Capital city: {capital}.{money}",
    "{Nice} is in {continent}. If you visit its capital, you'll be in {capital}.{money}",
]

CURRENCY = [
    "{Nice} uses {cur}.",
    "In {nice}, people pay with {cur}.",
    "The money in {nice} is {cur}.",
    "It's {cur}.",
    "{Nice}'s currency is {cur}.",
    "People in {nice} spend {cur}.",
    "The currency of {nice} is {cur}.",
    "{Cur} is the currency in {nice}.",
    "If you go shopping in {nice}, you'll pay with {cur}.",
    "{Nice} runs on {cur}.",
    "That would be {cur}.",
    "{Cur} is what they use in {nice}.",
    "In {nice} the money is {cur}.",
    "{Nice}? They use {cur}.",
    "The official money of {nice} is {cur}.",
    "Prices in {nice} are in {cur}.",
    "{Cur} is {poss} currency.",
    "{Nice} pays with {cur}.",
    "You'd need {cur} in {nice}.",
    "Money in {nice}: {cur}.",
]

# ---------- US states ----------
STATE_CAPITAL = [
    "The capital of {state} is {capital}.",
    "{capital} is the capital of {state}.",
    "{state}'s capital is {capital}.",
    "It's {capital}.",
    "{capital}! That's the capital of {state}.",
    "The state capital of {state} is {capital}.",
    "{state} has {capital} as its capital.",
    "That would be {capital}, the capital of {state}.",
    "{capital} is {state}'s capital city.",
    "The answer is {capital}.",
    "{state}? Its capital is {capital}.",
    "Capital of {state}: {capital}.",
    "It's {capital}, the capital of {state}.",
    "Easy one: {capital} is the capital of {state}.",
    "{state}'s state capital is {capital}.",
    "If you visit {state}'s capital, you'll be in {capital}.",
    "You're looking for {capital}. It's the capital of {state}.",
    "The capital of {state}? That's {capital}.",
    "{capital} is the capital city of {state}.",
    "{state} keeps its capital in {capital}.",
]

STATE_ABBR = [
    "{state}'s abbreviation is {abbr}.",
    "{abbr} stands for {state}.",
    "The abbreviation for {state} is {abbr}.",
    "It's {abbr}.",
    "{state} is shortened to {abbr}.",
    "The postal code for {state} is {abbr}.",
    "{abbr} is {state}.",
    "You write {state} as {abbr} on mail.",
    "{state} = {abbr}.",
    "That would be {abbr}, for {state}.",
    "{abbr} is the two-letter code for {state}.",
    "{state}'s two-letter code is {abbr}.",
    "Short for {state}: {abbr}.",
    "{abbr} means {state}.",
    "The state code {abbr} is {state}.",
    "{state}? That's {abbr}.",
    "{abbr}, which is {state}.",
    "On an address, {state} is {abbr}.",
    "Use {abbr} for {state}.",
    "The answer is {abbr}, for {state}.",
]

STATE_OF = [
    "{capital} is the capital of {state}.",
    "That's {state}. {capital} is its capital.",
    "{capital} is the state capital of {state}.",
    "It's {state}.",
    "{state}! {capital} is its capital.",
    "{capital} is {state}'s capital.",
    "The state is {state}, and {capital} is the capital.",
    "{capital}? That's the capital of {state}.",
    "{capital} is in {state}. It's the capital there.",
    "That would be {state}.",
    "{state} has {capital} as its capital.",
    "{capital} is the capital city of {state}.",
    "If you're in {capital}, you're in {state}'s capital.",
    "The answer is {state}.",
    "{capital} belongs to {state}, where it's the capital.",
    "{state}'s capital city is {capital}.",
    "That one's {state}. Its capital is {capital}.",
    "{capital} is the capital, and the state is {state}.",
    "Easy: {capital} is the capital of {state}.",
    "{state} is the state with {capital} as its capital.",
]

# ---------- elements ----------
SYMBOL = [
    "The symbol for {name} is {symbol}.",
    "{name}'s chemical symbol is {symbol}.",
    "{name} is written {symbol}.",
    "It's {symbol}.",
    "On the periodic table, {name} is {symbol}.",
    "{symbol} is the symbol for {name}.",
    "{name} uses the symbol {symbol}.",
    "The chemical symbol of {name} is {symbol}.",
    "{name} = {symbol}.",
    "That would be {symbol}.",
    "{name}? Its symbol is {symbol}.",
    "Look for {symbol} on the periodic table. That's {name}.",
    "{name} has the symbol {symbol}, and it's element number {number}.",
    "The answer is {symbol}.",
    "{name} is shown as {symbol} in chemistry.",
    "Chemists write {name} as {symbol}.",
    "Symbol for {name}: {symbol}.",
    "{symbol} stands for {name}.",
    "{name} goes by {symbol} on the periodic table.",
    "It's {symbol}, for {name}.",
]

SYMBOL_OF = [
    "{symbol} is {name}, element number {number}.",
    "That's {name}. Its symbol is {symbol}.",
    "{symbol} stands for {name}.",
    "It's {name}.",
    "{symbol} on the periodic table is {name}, number {number}.",
    "{name} has the symbol {symbol}.",
    "{symbol} means {name}, element {number}.",
    "The element with the symbol {symbol} is {name}.",
    "{symbol}? That's {name}.",
    "{name}! It's element number {number}, written {symbol}.",
    "That would be {name}.",
    "{symbol} is the symbol for {name}.",
    "Element {number}, {name}, uses the symbol {symbol}.",
    "{name} is the one with {symbol}.",
    "The answer is {name}, element number {number}.",
    "{symbol} is short for {name}.",
    "You're looking at {name}. It's number {number} on the periodic table.",
    "{name} ({symbol}) is element number {number}.",
    "In chemistry, {symbol} means {name}.",
    "{symbol} is {name}.",
]

ATOMIC_NUMBER = [
    "{name} has atomic number {number}.",
    "The atomic number of {name} is {number}.",
    "{name} is element number {number}.",
    "It's {number}.",
    "{name} is number {number} on the periodic table.",
    "{number} is the atomic number of {name}.",
    "{name} has {number} protons, so its atomic number is {number}.",
    "That would be {number}.",
    "{name} ({symbol}) is element {number}.",
    "{name}? Atomic number {number}.",
    "Atomic number of {name}: {number}.",
    "You'll find {name} at number {number} on the periodic table.",
    "{name} sits at spot {number} on the periodic table.",
    "The answer is {number}.",
    "{name}'s place on the periodic table is number {number}.",
    "Count to {number} on the periodic table and you'll hit {name}.",
    "Every {name} atom has {number} protons. That's its atomic number.",
    "{name}'s atomic number is {number}.",
    "It's number {number}, {name}.",
    "{name} comes in at number {number}.",
]

ELEMENT_NUMBER = [
    "Element number {number} is {name} ({symbol}).",
    "That's {name}, symbol {symbol}.",
    "Number {number} is {name}.",
    "It's {name} ({symbol}).",
    "{name} is element {number}.",
    "Element {number}? That's {name}.",
    "{name} ({symbol}) has atomic number {number}.",
    "That would be {name}.",
    "The element with atomic number {number} is {name}.",
    "{name}! Its symbol is {symbol}.",
    "Spot {number} on the periodic table is {name}.",
    "The answer is {name}, written {symbol}.",
    "{name} is number {number}, and its symbol is {symbol}.",
    "Atomic number {number} belongs to {name}.",
    "It's {name}. Every atom of it has {number} protons.",
    "{number} is {name} ({symbol}).",
    "You're thinking of {name}, symbol {symbol}.",
    "Element {number} is {name}.",
    "{name}, symbol {symbol}, is element {number}.",
    "Number {number} on the periodic table is {name} ({symbol}).",
]

ELEMENT_STATE = [
    "{name} ({symbol}) is element {number}. {state_text}",
    "{name} is element number {number}, symbol {symbol}. {state_text}",
    "{name} has the symbol {symbol} and atomic number {number}. {state_text}",
    "Here's {name}: element {number}, written {symbol}. {state_text}",
    "{name} ({symbol}) is number {number} on the periodic table. {state_text}",
    "{name} is element {number} ({symbol}). {state_text}",
    "Quick facts on {name}: symbol {symbol}, number {number}. {state_text}",
    "{name}, symbol {symbol}, is element number {number}. {state_text}",
    "{name} sits at number {number} on the periodic table as {symbol}. {state_text}",
    "Element {number} is {name} ({symbol}). {state_text}",
    "{name} is written {symbol}, and it's element {number}. {state_text}",
    "About {name}: it's element {number}, symbol {symbol}. {state_text}",
    "{name}! Element number {number}, symbol {symbol}. {state_text}",
    "{name} ({symbol}) has {number} protons. {state_text}",
    "Sure. {name} is element {number}, and its symbol is {symbol}. {state_text}",
    "{name}'s symbol is {symbol} and its atomic number is {number}. {state_text}",
    "{name} is number {number}, written {symbol}. {state_text}",
    "On the periodic table, {name} is {symbol}, number {number}. {state_text}",
    "{name} is the element with atomic number {number} ({symbol}). {state_text}",
    "Here's what I know about {name} ({symbol}, number {number}). {state_text}",
]

# ---------- words ----------
OPPOSITE = [
    "The opposite of {a} is {b}.",
    "{B} is the opposite of {a}.",
    "{a} and {b} are opposites.",
    "It's {b}.",
    "The antonym of {a} is {b}.",
    "The opposite of {a}? {B}.",
    "{B}! That's the opposite of {a}.",
    "If it's not {a}, it's {b}.",
    "{a} is the opposite of {b}, and {b} is the opposite of {a}.",
    "That would be {b}.",
    "An antonym for {a} is {b}.",
    "Flip {a} around and you get {b}.",
    "The word you want is {b}.",
    "Opposite of {a}: {b}.",
    "{B} is the word that means the opposite of {a}.",
    "The answer is {b}.",
    "{a} versus {b}. They're opposites.",
    "Try {b}. It's the opposite of {a}.",
    "Opposites: {a} and {b}.",
    "The other side of {a} is {b}.",
]

SYNONYM = [
    "Some other words for {w}: {syns}.",
    "Instead of {w}, you could say {syns}.",
    "Words that mean {w}: {syns}.",
    "Synonyms for {w}: {syns}.",
    "You can swap {w} for {syns}.",
    "Try {syns} instead of {w}.",
    "Other ways to say {w}: {syns}.",
    "{w} can also be {syns}.",
    "A few synonyms for {w} are {syns}.",
    "Here are some words like {w}: {syns}.",
    "If you're tired of {w}, use {syns}.",
    "Words close to {w}: {syns}.",
    "Some synonyms: {syns}. They all mean about the same as {w}.",
    "{syns} all mean about the same as {w}.",
    "Another word for {w}? Try {syns}.",
    "For {w}, you could use {syns}.",
    "{w} has some synonyms: {syns}.",
    "Here you go, other words for {w}: {syns}.",
    "Mix it up! Instead of {w}, say {syns}.",
    "Same idea as {w}: {syns}.",
]

# ---------- animals ----------
BABY = [
    "A baby {animal} is called {baby}.",
    "A baby {animal} has a special name: {baby_plain}.",
    "It's {baby}.",
    "A young {animal} is {baby}.",
    "{Baby}! That's a baby {animal}.",
    "When a {animal} is a baby, it's called {baby}.",
    "We call a baby {animal} {baby}.",
    "That would be {baby}.",
    "A baby {animal} goes by {baby}.",
    "The name for a baby {animal} is {baby_plain}.",
    "Baby {animal}? That's {baby}.",
    "A newborn {animal} is called {baby}.",
    "{Baby} is what you call a baby {animal}.",
    "The answer is {baby}.",
    "A little {animal} is called {baby}.",
    "A {animal}'s baby is {baby}.",
    "Baby {animal}: {baby_plain}.",
    "If you see a tiny {animal}, that's {baby}.",
    "A {animal} starts out as {baby}.",
    "A young {animal} is known as {baby}.",
]

SOUND = [
    "A {animal} {sound}.",
    "{Animals} {sound_plural}.",
    "The {animal} {sound}.",
    "It {sound}.",
    "A {animal}? It {sound}.",
    "Here's the {animal} answer: it {sound}.",
    "When a {animal} talks, it {sound}.",
    "Most of the time, a {animal} {sound}.",
    "A {animal} usually {sound}.",
    "{Animal} sound: it {sound}.",
    "Listen to a {animal} and it {sound}.",
    "The sound? A {animal} {sound}.",
    "Ask a {animal} to say hi and it {sound}.",
    "A {animal} {sound}. That's its sound.",
    "If you're near a {animal}, you'll notice it {sound}.",
    "Here's the {animal} sound: it {sound}.",
    "Every {animal} I've heard of {sound}.",
    "Fun fact: a {animal} {sound}.",
    "Picture a {animal}. It {sound}.",
    "Good one. A {animal} {sound}.",
]

GROUP = [
    "A group of {animals} is called {group}.",
    "It's {group} of {animals}.",
    "{Group}! That's a group of {animals}.",
    "Lots of {animals} together make {group}.",
    "We call a bunch of {animals} {group}.",
    "A gang of {animals} is {group}.",
    "That would be {group}.",
    "The word for a group of {animals} is {group_plain}.",
    "{Group} of {animals}.",
    "A group of {animals}? That's {group}.",
    "When {animals} hang out together, it's {group}.",
    "Several {animals} make {group}.",
    "The answer is {group}.",
    "You'd say {group} of {animals}.",
    "{Group} is what you call a group of {animals}.",
    "Group of {animals}: {group_plain}.",
    "Fun word: a group of {animals} is {group}.",
    "{Animals} in a group are called {group}.",
    "If you see many {animals} together, that's {group}.",
    "A crowd of {animals} is {group}.",
]

# ---------- languages ----------
HELLO = [
    "Hello in {lang} is \"{word}\".",
    "In {lang}, you say \"{word}\".",
    "\"{Word}\" means hello in {lang}.",
    "Try \"{word}\". That's hello in {lang}.",
    "To say hi in {lang}, say \"{word}\".",
    "It's \"{word}\".",
    "{lang} speakers say \"{word}\" for hello.",
    "\"{Word}\"! That's hello in {lang}.",
    "Say \"{word}\" to greet someone in {lang}.",
    "The {lang} word for hello is \"{word}\".",
    "Hello in {lang}? \"{Word}\".",
    "In {lang}, hello is \"{word}\".",
    "You'd say \"{word}\" in {lang}.",
    "A {lang} hello is \"{word}\".",
    "Greet someone in {lang} with \"{word}\".",
    "\"{Word}\" is how you say hello in {lang}.",
    "{lang} for hello: \"{word}\".",
    "Here's a {lang} hello: \"{word}\".",
    "The answer is \"{word}\".",
    "If you meet someone who speaks {lang}, say \"{word}\".",
]

THANKS = [
    "Thank you in {lang} is \"{word}\".",
    "In {lang}, you say \"{word}\".",
    "\"{Word}\" means thank you in {lang}.",
    "Try \"{word}\". That's thanks in {lang}.",
    "To say thanks in {lang}, say \"{word}\".",
    "It's \"{word}\".",
    "{lang} speakers say \"{word}\" to say thanks.",
    "\"{Word}\"! That's thank you in {lang}.",
    "Say \"{word}\" to thank someone in {lang}.",
    "The {lang} word for thank you is \"{word}\".",
    "Thank you in {lang}? \"{Word}\".",
    "In {lang}, thanks is \"{word}\".",
    "You'd say \"{word}\" in {lang}.",
    "A {lang} thank you is \"{word}\".",
    "Thank someone in {lang} with \"{word}\".",
    "\"{Word}\" is how you say thank you in {lang}.",
    "{lang} for thank you: \"{word}\".",
    "Here's a {lang} thank you: \"{word}\".",
    "The answer is \"{word}\".",
    "If someone helps you in {lang}, say \"{word}\".",
]

BYE = [
    "Goodbye in {lang} is \"{word}\".",
    "In {lang}, you say \"{word}\".",
    "\"{Word}\" means goodbye in {lang}.",
    "Try \"{word}\". That's goodbye in {lang}.",
    "To say bye in {lang}, say \"{word}\".",
    "It's \"{word}\".",
    "{lang} speakers say \"{word}\" when they leave.",
    "\"{Word}\"! That's goodbye in {lang}.",
    "Say \"{word}\" to say bye in {lang}.",
    "The {lang} word for goodbye is \"{word}\".",
    "Goodbye in {lang}? \"{Word}\".",
    "In {lang}, bye is \"{word}\".",
    "You'd say \"{word}\" in {lang}.",
    "A {lang} goodbye is \"{word}\".",
    "Leave a {lang} speaker with \"{word}\".",
    "\"{Word}\" is how you say goodbye in {lang}.",
    "{lang} for goodbye: \"{word}\".",
    "Here's a {lang} goodbye: \"{word}\".",
    "The answer is \"{word}\".",
    "When you leave someone who speaks {lang}, say \"{word}\".",
]

# ---------- calendar ----------
MONTH_DAYS = [
    "{month} has {days} days{extra}.",
    "There are {days} days in {month}{extra}.",
    "{month} is {days} days long{extra}.",
    "It's {days} days{extra}.",
    "{days} days{extra}.",
    "{month} lasts {days} days{extra}.",
    "You get {days} days in {month}{extra}.",
    "{month}? {days} days{extra}.",
    "That would be {days} days{extra}.",
    "{month} has {days} days in it{extra}.",
    "Count them up and {month} has {days} days{extra}.",
    "The answer is {days} days{extra}.",
    "{month} runs for {days} days{extra}.",
    "Days in {month}: {days}{extra}.",
    "A full {month} is {days} days{extra}.",
    "{month} comes with {days} days{extra}.",
    "From the 1st to the end, {month} is {days} days{extra}.",
    "{days} days make up {month}{extra}.",
    "{month} has a total of {days} days{extra}.",
    "It has {days} days{extra}.",
]

MONTH_ORDER = [
    "{month} is month number {n}, and {next} comes after it.",
    "{next} comes after {month}. {month} is month {n}.",
    "{month} is the {nth} month. Next up is {next}.",
    "After {month} comes {next}. {month} is month number {n}.",
    "{month} is month {n} of the year, followed by {next}.",
    "Month {n} is {month}, and then it's {next}.",
    "{month} is number {n}. The month after it is {next}.",
    "{next} follows {month}, which is month {n}.",
    "{month}: month number {n}. Next: {next}.",
    "{month} is the {nth} month, and {next} comes next.",
    "Right after {month} is {next}. {month} is month {n}.",
    "{month} sits at number {n}, just before {next}.",
    "{month} is month number {n}, right before {next}.",
    "Once {month} ends, it's {next}. {month} is month {n}.",
    "{next} is the month after {month}, and {month} is number {n}.",
    "{month} is the {nth} month of the year. Then comes {next}.",
    "Month number {n} is {month}. {next} is next.",
    "{month} comes {nth} in the year, and {next} follows it.",
    "{month} is month {n}. After that, {next}.",
    "In the calendar, {month} is number {n}, then {next}.",
]

DAY_AFTER = [
    "{next} comes after {day}.",
    "After {day} comes {next}.",
    "It's {next}.",
    "{next}! That's the day after {day}.",
    "The day after {day} is {next}.",
    "{day} is followed by {next}.",
    "Once {day} is over, it's {next}.",
    "That would be {next}.",
    "{next} is the day after {day}.",
    "Right after {day} is {next}.",
    "{day}, then {next}.",
    "The next day after {day} is {next}.",
    "{day}? The next day is {next}.",
    "The answer is {next}.",
    "Tomorrow, if today is {day}, is {next}.",
    "{next} follows {day}.",
    "Day after {day}: {next}.",
    "Wake up after {day} and it's {next}.",
    "{next} comes right after {day}.",
    "When {day} ends, {next} starts.",
]

DAY_BEFORE = [
    "{prev} comes before {day}.",
    "Before {day} comes {prev}.",
    "It's {prev}.",
    "{prev}! That's the day before {day}.",
    "The day before {day} is {prev}.",
    "{day} comes right after {prev}.",
    "Just before {day} is {prev}.",
    "That would be {prev}.",
    "{prev} is the day before {day}.",
    "Right before {day} is {prev}.",
    "{prev}, then {day}.",
    "The day ahead of {day} is {prev}.",
    "{day}? The day before is {prev}.",
    "The answer is {prev}.",
    "Yesterday, if today is {day}, was {prev}.",
    "{prev} comes just before {day}.",
    "Day before {day}: {prev}.",
    "{day} follows {prev}.",
    "{prev} leads into {day}.",
    "When {prev} ends, {day} starts.",
]

# ---------- planets ----------
PLANET = [
    "{name} is the {ordinal} planet from the Sun. Fun fact: {fact}.",
    "{name} is planet number {pos} from the Sun. Cool fact: {fact}.",
    "Here's {name}: it's the {ordinal} planet from the Sun, and {fact}.",
    "{name} is {ordinal} from the Sun. Did you know {fact}?",
    "{name}! It's the {ordinal} planet from the Sun. Also, {fact}.",
    "The {ordinal} planet from the Sun is {name}, and {fact}.",
    "{name} sits {ordinal} from the Sun. One fun thing: {fact}.",
    "About {name}: it's the {ordinal} planet out from the Sun, and {fact}.",
    "{name} is the {ordinal} planet. Here's something wild: {fact}.",
    "Quick facts on {name}: {ordinal} from the Sun, and {fact}.",
    "{name} orbits {ordinal} from the Sun. Fun fact: {fact}.",
    "{name} is the {ordinal} planet in our solar system. Also, {fact}.",
    "Count out from the Sun and {name} is {ordinal}. Neat fact: {fact}.",
    "{name} is planet {pos}. Something cool about it: {fact}.",
    "Sure! {name} is the {ordinal} planet from the Sun, and {fact}.",
    "{name}, the {ordinal} planet from the Sun: {fact}.",
    "{name} is number {pos} from the Sun. Bonus fact: {fact}.",
    "Here's what I know about {name}. It's the {ordinal} planet, and {fact}.",
    "{name} is the {ordinal} world out from the Sun. Fun fact: {fact}.",
    "Let's talk {name}. It's {ordinal} from the Sun, and {fact}.",
]

PLANET_MOONS = [
    "{name} has {moons}.",
    "It has {moons}.",
    "{name}? It has {moons}.",
    "Moons of {name}: {moons}.",
    "{name} comes with {moons}.",
    "That would be {moons} for {name}.",
    "The answer is {moons}.",
    "{name} has {moons} going around it.",
    "So far, {name} has {moons}.",
    "{name}'s moon count: {moons}.",
    "As far as we know, {name} has {moons}.",
    "It's {moons} for {name}.",
    "Count the moons of {name} and you get {moons}.",
    "{name} has {moons}, last I checked.",
    "Moon count for {name}: {moons}.",
    "Good one. {name} has {moons}.",
    "Here's the answer: {name} has {moons}.",
    "If you're counting moons, {name} has {moons}.",
    "{name} gets {moons}.",
    "The moon total for {name} is {moons}.",
]

PLANET_DAY = [
    "A day on {name} lasts {day}.",
    "One day on {name} is {day}.",
    "{name} spins around once in {day}.",
    "It takes {name} {day} to spin once.",
    "A {name} day is {day}.",
    "Days on {name} are {day} long.",
    "{name}'s day lasts {day}.",
    "That's {day}.",
    "On {name}, one day takes {day}.",
    "Each day on {name} takes {day}.",
    "{name}? A day there is {day}.",
    "Day length on {name}: {day}.",
    "The answer is {day}.",
    "If you lived on {name}, a day would be {day}.",
    "{name} turns once every {day}.",
    "A single spin of {name} takes {day}.",
    "{name} takes {day} for one day.",
    "One full day on {name}: {day}.",
    "Spend a day on {name} and it lasts {day}.",
    "It lasts {day} on {name}.",
]

PLANET_YEAR = [
    "A year on {name} lasts {year}.",
    "{name} takes {year} to go around the Sun.",
    "One trip around the Sun takes {name} {year}.",
    "A {name} year is {year}.",
    "{name}'s year is {year} long.",
    "It takes {year}.",
    "{name} orbits the Sun once every {year}.",
    "One year on {name}: {year}.",
    "That's {year}.",
    "If you lived on {name}, a year would be {year}.",
    "{name}? Its year lasts {year}.",
    "Year length on {name}: {year}.",
    "The answer is {year}.",
    "{name} finishes one orbit in {year}.",
    "Birthdays on {name} come every {year}.",
    "One lap around the Sun takes {name} {year}.",
    "{name} needs {year} to circle the Sun.",
    "A full orbit of {name} takes {year}.",
    "Going around the Sun takes {name} {year}.",
    "It lasts {year} on {name}.",
]

PLANET_POS = [
    "{name} is the {ordinal} planet from the Sun.",
    "{name} is planet number {pos}.",
    "It's the {ordinal} planet from the Sun.",
    "{name} is number {pos} from the Sun.",
    "Count out from the Sun and {name} is {ordinal}.",
    "{name} sits {ordinal} from the Sun.",
    "{name} is the {ordinal} planet in our solar system.",
    "{name}? It's planet {pos}.",
    "That's the {ordinal} planet, {name}.",
    "{name} is {ordinal} in line from the Sun.",
    "The answer is {ordinal}.",
    "{name} comes {ordinal} from the Sun.",
    "Planet number {pos} is {name}.",
    "{name} is in spot {pos} from the Sun.",
    "Start at the Sun and count: {name} is number {pos}.",
    "{name} orbits {ordinal} from the Sun.",
    "{name} takes the {ordinal} spot from the Sun.",
    "Position {pos}: {name}.",
    "{name} is the {ordinal} one out.",
    "It's planet {pos} from the Sun.",
]

CAPITAL_SAME = [
    "{capital} is the capital of {nice}, in {continent}.",
    "{capital} is the capital of {nice}. The city and the country share a name!",
    "It's {nice}. The capital has the same name: {capital}.",
    "{capital} is both a city and a country. The city is the capital of {nice}.",
    "{Nice}, in {continent}. Its capital is also called {capital}.",
    "That's {nice}! Its capital city has the same name.",
    "{capital} is the capital city of {nice}, a country in {continent}.",
    "The country is {nice}, and its capital is {capital} too.",
    "Fun one: {capital} is the capital of {nice}, which has the same name.",
    "{capital} is in {nice}, in {continent}. Same name for both!",
    "{Nice}. The capital and the country are both called {capital}.",
    "{capital}? It's the capital of {nice}.",
    "{capital} is {poss} capital, in {continent}.",
    "The city of {capital} is the capital of {nice}.",
    "Easy: {capital} is the capital of {nice}.",
    "{Nice} named its capital {capital}, just like the country.",
    "It's {nice}, over in {continent}. The capital shares the name.",
    "{capital} is the capital of the country with the same name, {nice}.",
    "If you're in the city of {capital}, you're in the capital of {nice}.",
    "{capital} is the capital, and the country is {nice}.",
]

TEMPLATES = {
    "capital_same": CAPITAL_SAME,
    "capital": CAPITAL, "capital_of": CAPITAL_OF, "continent": CONTINENT, "country": COUNTRY,
    "currency": CURRENCY, "state_capital": STATE_CAPITAL, "state_abbr": STATE_ABBR, "state_of": STATE_OF,
    "symbol": SYMBOL, "symbol_of": SYMBOL_OF, "atomic_number": ATOMIC_NUMBER, "element_number": ELEMENT_NUMBER,
    "element_state": ELEMENT_STATE, "opposite": OPPOSITE, "synonym": SYNONYM, "baby": BABY, "sound": SOUND,
    "group": GROUP, "hello": HELLO, "thanks": THANKS, "bye": BYE, "month_days": MONTH_DAYS,
    "month_order": MONTH_ORDER, "day_after": DAY_AFTER, "day_before": DAY_BEFORE, "planet": PLANET,
    "planet_moons": PLANET_MOONS, "planet_day": PLANET_DAY, "planet_year": PLANET_YEAR, "planet_pos": PLANET_POS,
}


IRREGULAR = {"sheep": "sheep", "fish": "fish", "deer": "deer", "goose": "geese", "wolf": "wolves",
             "mouse": "mice", "ox": "oxen", "moose": "moose", "calf": "calves"}


def plural(noun):
    if noun in IRREGULAR:
        return IRREGULAR[noun]
    if noun.endswith(("s", "x", "sh", "ch", "z")):
        return noun + "es"
    if noun.endswith("y") and noun[-2:-1] not in "aeiou":
        return noun[:-1] + "ies"
    return noun + "s"


def _strip_article(s):
    for a in ("a ", "an ", "the "):
        if s.startswith(a):
            return s[len(a):]
    return s


def _third_plural(verb_phrase):
    """'barks or woofs' -> 'bark or woof', "doesn't really make sounds" -> "don't really make sounds"."""
    if verb_phrase.startswith("doesn't"):
        return "don't" + verb_phrase[len("doesn't"):]
    words = verb_phrase.split()
    out = []
    for w in words:
        if w in ("or", "and", "its", "their", "feet", "sounds", "really"):
            out.append("their" if w == "its" else w)
        elif w.endswith("es") and w[:-2].endswith(("ss", "sh", "ch", "x", "z")):
            out.append(w[:-2])
        elif w.endswith("s") and not w.endswith("ss"):
            out.append(w[:-1])
        else:
            out.append(w)
    return " ".join(out)


def make(kind, **facts):
    """20 answers for one family, filled with facts."""
    f = dict(facts)
    if "nice" in f:
        f["Nice"] = cap(f["nice"])
        f["poss"] = poss(f["nice"])
        f["Poss"] = cap(f["poss"])
    if "cur" in f:
        f["Cur"] = cap(f["cur"])
    if "money" not in f:
        f["money"] = ""
    if "b" in f:
        f["B"] = cap(f["b"])
    if "baby" in f:
        f["Baby"] = cap(f["baby"])
        f["baby_plain"] = _strip_article(f["baby"])
    if "group" in f:
        f["Group"] = cap(f["group"])
        f["group_plain"] = _strip_article(f["group"])
    if "animal" in f:
        f["Animal"] = cap(f["animal"])
        f["animals"] = plural(f["animal"])
        f["Animals"] = cap(f["animals"])
    if "sound" in f:
        f["sound_plural"] = _third_plural(f["sound"])
    if "word" in f:
        f["Word"] = cap(f["word"])
    if "moons" in f:
        m = f["moons"]
        f["moons_count"] = m
    return _fill(TEMPLATES[kind], f)


# ---------- hand-written answers ----------
FACT_OPENERS = ["Sure! ", "Here you go: ", "Good question. ", "Okay! ", "Here's what I know: ", "Quick answer: ",
                "Glad you asked. ", "Alright. ", "Got it. ", "Let me think... ", "Easy one. ", "Oh, I know this! "]
FACT_CLOSERS = [" Pretty cool, right?", " Hope that helps!", " Anything else you want to know?", " Neat, huh?",
                " Ask me more if you're curious."]
CHAT_OPENERS = ["Okay! ", "Ha! ", "Good question. ", "Well... ", "Hmm. ", "Oh! ", "Alright. ", "Funny you ask. ",
                "Glad you asked. ", "Let's see. ", "Honestly? ", "Fun question! "]
CHAT_CLOSERS = [" Anything else?", " What made you ask?", " Got any more questions for me?", " That's me!",
                " Ask me anything else."]
CARE_OPENERS = ["I hear you. ", "Okay. ", "Thanks for telling me. ", "Got it. ", "I'm listening. ", "Hey. ",
                "Thank you for sharing that. ", "Alright. ", "I'm here. ", "Okay, thanks for sharing. ", "I get it. ",
                "I'm glad you told me. "]
CARE_CLOSERS = [" I'm here if you need me.", " You can always talk to me.", " I'm around whenever you want.",
                " Tell me if there's more.", " I'm here for you."]
SAFE_OPENERS = ["Good question. ", "Okay. ", "Important one. ", "Here's what to do. ", "Glad you asked. ",
                "Listen up. ", "Alright. ", "Got it. ", "Here's the safe answer. ", "Smart to ask. ", "Okay, so: ",
                "Here you go. "]
SAFE_CLOSERS = [" Stay safe!", " Better safe than sorry.", " Ask a grown-up if you're not sure.",
                " Safety first!", " That keeps you safe."]

CHAT_TAGS = ("ace", "fun", "school")
CARE_TAGS = ("feelings",)
SAFE_TAGS = ("safety",)


def general(tag, answers):
    """20 versions of hand-written answers: the originals first, then wrapped ones (facts unchanged)."""
    top = tag.split(".")[0]
    if top in CARE_TAGS:
        openers, closers = CARE_OPENERS, CARE_CLOSERS
    elif top in SAFE_TAGS:
        openers, closers = SAFE_OPENERS, SAFE_CLOSERS
    elif top in CHAT_TAGS:
        openers, closers = CHAT_OPENERS, CHAT_CLOSERS
    else:
        openers, closers = FACT_OPENERS, FACT_CLOSERS
    out = []

    def push(s):
        if s not in out and len(out) < COUNT:
            out.append(s)

    n = len(answers)
    for a in answers:
        push(a)
    for i, op in enumerate(openers):
        push(op + answers[i % n])
    for i, cl in enumerate(closers):
        push(answers[i % n] + cl)
    for i in range(len(openers) * len(closers)):
        push(openers[(i * 7 + 3) % len(openers)] + answers[i % n] + closers[i % len(closers)])
    if len(out) < COUNT:
        raise ValueError(f"couldn't make {COUNT} versions of {answers}")
    return out
