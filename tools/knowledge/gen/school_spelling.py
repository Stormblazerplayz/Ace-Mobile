#!/usr/bin/env python3
"""Writes data/school/gen_spelling.txt: how to spell commonly misspelled English words (American spelling).

Source: no outside data. The word list, the common wrong spellings and the memory tips are written by hand
here; the letter-by-letter spellings are produced from the word itself so they can't contain typos.

Run from the repo root:  python3 tools/knowledge/gen/school_spelling.py
Any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from school_math import KNOW, Writer, load_taken  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_spelling.txt")

# word, a common wrong spelling (never a real word), memory tip or "" for none
WORDS = [
    ("accommodate", "accomodate", "It has two c's and two m's, because it's big enough to accommodate both."),
    ("achieve", "acheive", "It follows \"i before e except after c\"."),
    ("acquire", "aquire", "There's a c before the q."),
    ("across", "accross", "It has only one c: a cross."),
    ("address", "adress", "Two d's and two s's."),
    ("apparent", "apparant", "It has a parent inside: ap-PARENT."),
    ("argument", "arguement", "Argue drops its e: argue becomes argument."),
    ("basically", "basicly", "Add -ally to basic: basic + ally."),
    ("beautiful", "beatiful", "It starts with b-e-a-u, then t-i-f-u-l."),
    ("because", "becuase", "Big Elephants Can Always Understand Small Elephants."),
    ("beginning", "begining", "Double the n before -ing: begin + n + ing."),
    ("believe", "beleive", "Never believe a lie: there's a \"lie\" in believe."),
    ("business", "buisness", "Think \"busy\" + ness, with the y turned into i: bus-i-ness."),
    ("calendar", "calender", "It ends in -ar, like the \"ar\" in January."),
    ("cemetery", "cemetary", "All three vowels after the m are e's: c-e-m-e-t-e-r-y."),
    ("committee", "commitee", "Double m, double t, double e."),
    ("conscious", "concious", "It has \"sci\" in the middle, like science."),
    ("curiosity", "curiousity", "The u from curious drops out: curi-osity."),
    ("definitely", "definately", "It contains the word \"finite\": de-FINITE-ly."),
    ("describe", "discribe", "It starts with de-, like decide."),
    ("different", "diffrent", "Say all three syllables: dif-fer-ent."),
    ("dilemma", "dilemna", "It ends in -mma, with no n."),
    ("disappear", "dissapear", "dis + appear: one s, two p's."),
    ("disappoint", "dissapoint", "dis + appoint: one s, two p's."),
    ("eighth", "eigth", "It's eight + h."),
    ("embarrass", "embarass", "Two r's and two s's, like going red and red, shy and shy."),
    ("environment", "enviroment", "There's \"iron\" in environment: envIRONment."),
    ("especially", "expecially", "It starts with es-, like especial."),
    ("exaggerate", "exagerate", "It has a double g."),
    ("excellent", "excelent", "Double l, then -ent."),
    ("exercise", "excercise", "There's no c after the x."),
    ("existence", "existance", "It ends in -ence."),
    ("experience", "experiance", "It ends in -ence."),
    ("familiar", "familar", "Think family + iar: famil-i-ar."),
    ("February", "Febuary", "Say both r's: Feb-ru-ar-y."),
    ("finally", "finaly", "It's final + ly, so two l's."),
    ("foreign", "foriegn", "It's an exception to \"i before e\": e-i-g-n."),
    ("forty", "fourty", "Four loses its u in forty, though fourteen keeps it."),
    ("friend", "freind", "Your friend is there to the END: fri-END."),
    ("government", "goverment", "It's govern + ment, so keep the n."),
    ("grammar", "grammer", "It ends in -ar. Don't mar your grammar."),
    ("grateful", "greatful", "It's about being grateful, not great: g-r-a-t-e."),
    ("guarantee", "garantee", "There's a u after the g."),
    ("guard", "gaurd", "u comes before a: g-u-a-r-d."),
    ("harass", "harrass", "One r, two s's."),
    ("height", "heighth", "It ends in -ght, with no h at the end."),
    ("hierarchy", "heirarchy", "It starts with h-i-e."),
    ("humorous", "humourous", "Even in British English, humorous has no u after the o."),
    ("hygiene", "hygeine", "y-g-i-e-n-e: i before e."),
    ("immediately", "immediatly", "It's immediate + ly, so keep the e."),
    ("independent", "independant", "It ends in -ent."),
    ("intelligence", "inteligence", "Double l, and it ends in -ence."),
    ("interrupt", "interupt", "Double r: inter + rupt."),
    ("island", "iland", "An island is land surrounded by water: is + land."),
    ("knowledge", "knowlege", "It's know + ledge."),
    ("leisure", "liesure", "e before i in this one: l-e-i."),
    ("library", "libary", "Say both r's: li-brar-y."),
    ("license", "lisence", "c comes first, then s."),
    ("maintenance", "maintainance", "Maintain changes to mainten- before -ance."),
    ("mathematics", "mathmatics", "Say the e: math-e-matics."),
    ("millennium", "millenium", "Double l and double n."),
    ("minuscule", "miniscule", "It starts with minus: minus-cule."),
    ("mischievous", "mischievious", "It has three syllables: mis-chie-vous, with no i before -ous."),
    ("misspell", "mispell", "It's mis + spell, so two s's."),
    ("necessary", "neccessary", "One collar (c) and two sleeves (s's)."),
    ("neighbor", "nieghbor", "e before i, sounding like \"ay\", as in weigh."),
    ("ninety", "ninty", "Nine keeps its e in ninety."),
    ("ninth", "nineth", "Nine loses its e in ninth."),
    ("noticeable", "noticable", "Keep the e of notice so the c stays soft."),
    ("occasion", "ocassion", "Two c's, one s."),
    ("occasionally", "occasionaly", "Two c's, one s, two l's."),
    ("occurred", "occured", "Double c, double r."),
    ("occurrence", "occurence", "Double c, double r, and it ends in -ence."),
    ("opportunity", "oppertunity", "It starts with opport-, like port."),
    ("parallel", "paralel", "The two l's in the middle are parallel lines."),
    ("pastime", "pasttime", "Only one t: pass + time, with one s dropped."),
    ("people", "poeple", "e before o: p-e-o."),
    ("perseverance", "perseverence", "It ends in -ance."),
    ("persistent", "persistant", "It ends in -ent."),
    ("piece", "peice", "A piece of pie: p-i-e."),
    ("playwright", "playwrite", "A wright is a maker, as in shipwright."),
    ("possession", "posession", "Two sets of double s."),
    ("preferred", "prefered", "Double the r before -ed, because the stress is on -fer."),
    ("privilege", "priviledge", "There's no d: p-r-i-v-i-l-e-g-e."),
    ("probably", "probaly", "Say all three syllables: prob-ab-ly."),
    ("pronunciation", "pronounciation", "Pronounce loses its o in pronunciation."),
    ("questionnaire", "questionaire", "Double n."),
    ("receipt", "reciept", "e before i after c, and a silent p."),
    ("receive", "recieve", "i before e, except after c."),
    ("recognize", "reconize", "Don't forget the g: re-cog-nize."),
    ("recommend", "reccomend", "One c, two m's: re + commend."),
    ("referred", "refered", "Double the r before -ed."),
    ("relevant", "relevent", "It ends in -ant."),
    ("repetition", "repitition", "It comes from repeat: rep-e-tition."),
    ("restaurant", "restaraunt", "It has \"rest\" + \"au\" + \"rant\"."),
    ("rhythm", "rythm", "Rhythm Helps Your Two Hips Move."),
    ("ridiculous", "rediculous", "It starts with rid-, like ridicule."),
    ("schedule", "schedual", "It ends in -ule."),
    ("science", "sience", "There's a c after the s."),
    ("scissors", "sissors", "There's a silent c after the first s."),
    ("sentence", "sentance", "Three e's: s-e-n-t-e-n-c-e."),
    ("separate", "seperate", "There's \"a rat\" in separate."),
    ("sergeant", "sargent", "It starts with ser-, and has an e after the g."),
    ("similar", "similiar", "It ends in -lar, with no extra i."),
    ("sincerely", "sincerly", "It's sincere + ly, so keep the e."),
    ("strength", "strenght", "It ends in -gth."),
    ("succeed", "suceed", "Double c, double e."),
    ("supersede", "supercede", "It's the only common English word ending in -sede."),
    ("surprise", "suprise", "There's an r after the u: sur-prise."),
    ("temperature", "temperture", "Say the a: tem-per-a-ture."),
    ("threshold", "threshhold", "Only one h in the middle."),
    ("tomorrow", "tommorow", "One m, two r's."),
    ("tongue", "tounge", "It ends in -gue."),
    ("truly", "truely", "True drops its e: true becomes truly."),
    ("twelfth", "twelth", "Keep the f: twelf-th."),
    ("unnecessary", "unneccessary", "It's un + necessary, so two n's at the start."),
    ("until", "untill", "Only one l at the end."),
    ("usually", "usualy", "It's usual + ly, so two l's."),
    ("vacuum", "vaccum", "One c, two u's."),
    ("vegetable", "vegtable", "Say the e: veg-e-ta-ble."),
    ("villain", "villian", "It ends in -ain, like a villain wants to gain."),
    ("Wednesday", "Wensday", "Say it like Wed-nes-day to remember the d."),
    ("weird", "wierd", "It breaks the rule: weird is weird."),
    ("yacht", "yatch", "y-a-c-h-t, with a silent ch."),
]


def spelled(word):
    return "-".join(word.upper())


def main():
    taken, keys = load_taken({os.path.abspath(OUT)})
    w = Writer(taken, keys)
    w.tag("school.english.spelling-words")
    for word, wrong, tip in WORDS:
        lw = word.lower()
        qs = [f"how do you spell {lw}", f"how to spell {lw}", f"spelling of {lw}",
              f"is it {wrong.lower()} or {lw}", f"is {wrong.lower()} spelled right"]
        a = f"The word \"{word}\" is spelled {spelled(word)}."
        if tip:
            a += " Tip: " + tip
        w.add(qs, a)
    head = ("# Generated by tools/knowledge/gen/school_spelling.py (hand-written word list and tips).\n"
            "# Do not edit by hand; change the generator and run it again.\n")
    n = w.write(OUT, head)
    print(f"wrote {n} entries to gen_spelling.txt")


if __name__ == "__main__":
    main()
