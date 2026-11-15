#!/usr/bin/env python3
"""Writes data/school/gen_vocab.txt: "what does X mean" entries for reading and school words, plus
"another word for X" (synonyms) and "what is the opposite of X" (WordNet antonym links, hand-reviewed).

Data sources
  - Princeton WordNet 3.0 (via the NLTK "wordnet" corpus). License: WordNet 3.0 license, a permissive
    BSD-style license ("Permission to use, copy, modify and distribute this software and database and its
    documentation for any purpose and without fee or royalty is hereby granted..."). Copyright 2006 by
    Princeton University. https://wordnet.princeton.edu/license-and-commercial-use
  - wordfreq (Robyn Speer), used only to pick how common a word is. Code is Apache 2.0, word lists are
    CC BY-SA 4.0. https://github.com/rspeer/wordfreq

Setup (downloads go to tools/knowledge/.cache, which is not committed):
    pip install nltk wordfreq
    mkdir -p tools/knowledge/.cache/nltk_data/corpora
    curl -L -o tools/knowledge/.cache/nltk_data/corpora/wordnet.zip \
        https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/wordnet.zip
    (cd tools/knowledge/.cache/nltk_data/corpora && unzip -o wordnet.zip)
    chmod -R go-w tools/knowledge/.cache

Run from the repo root:  python3 tools/knowledge/gen/school_vocab.py

How words are picked
  - wordfreq's English list, keeping words with a Zipf frequency between LOW and HIGH (common enough that a
    12-year-old meets them in books, not so common that nobody asks what they mean)
  - base forms only (WordNet's morphy gives the word back), lowercase lemma, no proper nouns
  - no rude, adult, slur or slang words (blocklist plus WordNet usage domains and gloss checks)
  - the most common sense: the WordNet synset with the highest tagged count for that word
  - any wording already used elsewhere in the knowledge pack (or Ace's core bank) is dropped
"""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, KNOW)
import check_data  # noqa: E402

import nltk  # noqa: E402

nltk.data.path.insert(0, os.path.join(KNOW, ".cache", "nltk_data"))
from nltk.corpus import wordnet as wn  # noqa: E402
import wordfreq  # noqa: E402

OUT = os.path.join(KNOW, "data", "school", "gen_vocab.txt")
LOW, HIGH = 3.1, 4.7
MAX_RANK = 3544
TARGET_SYNONYMS = 900

# Rude, adult, scary-for-kids or slur words, and words whose main sense is adult. Checked as substrings
# of the word for the first group and as whole words for the second.
BAD_PARTS = """fuck shit bitch cunt dick cock pussy whore slut porn sex nigg fag rape anal anus penis vagina
breast nipple orgasm erotic masturb horny boob butt arse bastard damn crap piss tit semen sperm testic scrot
condom viagra lesbian dildo pimp hooker stripper incest pedo molest grope kink fetish nude naked""".split()
BAD_WORDS = set("""ass hell god jesus christ heroin cocaine meth weed marijuana cannabis drunk booze vodka whiskey
beer wine liquor tequila rum gin hangover overdose suicide suicidal kill killer murder murderer homicide
slaughter massacre genocide torture execute execution behead corpse gore abortion bra lingerie thong
gay homosexual transgender queer racist nazi kkk terrorist jihad bomb gun rifle pistol shotgun ammo
bullet grenade cigarette cigar tobacco nicotine vape smoke stoned lsd ecstasy opium narcotic drug drugs
casino gamble gambling bet poker lottery prostitute prostitution mistress affair adultery seduce seductive
lust lusty sensual sultry intimate intimacy aroused arouse arousal steamy kinky womb pregnant pregnancy
period menstrual menstruation urine feces poop fart vomit puke diarrhea constipation enema
idiot moron retard retarded stupid dumb loser jerk freak bimbo hussy tramp wench harlot
pervert perverted perverse flirt flirty date dating hottie babe sexy bang screw blow hump
negro swear vulgar yahoo redeem bible bless blessed drunken victorian sin sinful holy satan demon
murdered slay slain
""".split())
BAD_GLOSS = re.compile(r"\b(sex|sexual|sexually|genital|genitals|intercourse|erotic|obscene|vulgar|"
                       r"offensive|derogatory|disparaging|slang|ethnic|slur|prostitut\w*|copulat\w*|"
                       r"penis|vagina|breasts?|buttocks|anus|rectum|excrement|feces|urine|urinate|semen|"
                       r"drunk\w*|intoxicat\w*|alcohol\w*|liquor|racial|race|narcotic|marijuana|cocaine|heroin|"
                       r"suicide|homosexual|lesbian|homicide|murder\w*|corpse|nude|naked|lust\w*|"
                       r"masturbat\w*|pornograph\w*|god|jesus|christ|bible|biblical|deity|"
                       r"satan|devil|hell)\b", re.I)
BAD_DOMAINS = {"slang", "vulgarism", "obscenity", "ethnic slur", "disparagement", "colloquialism", "argot",
               "dialect", "regionalism", "jargon", "trope"}
# Topic areas whose words are usually rare jargon for a kid (anatomy, chemistry compounds, taxonomy).
SKIP_LEXNAMES = {"noun.body", "noun.substance", "noun.plant", "noun.animal", "noun.food", "noun.location",
                 "noun.Tops", "verb.body"}
# Glosses that start like this are usually cross-references or too technical to rewrite well.
SKIP_GLOSS_START = re.compile(r"^(used |any of|of or relating to the practice|a genus|genus|family|order|a member of|an order|a family|a variety of|"
                              r"(a|an|the) (unit|chemical|compound|drug|disease|condition) (of|that|in)|"
                              r"\(\w+\))", re.I)
# Very common words a kid already knows; not worth a "what does X mean" entry even if in the range.
EASY = set("""about above across after again against almost alone along already also always among another answer
anybody anyone anything anywhere around away back bad because become before behind being below best better
between big book both bring brother build busy call came can car care carry cat catch child city class clean
clear close cold come could country cut dad dance dark day dear do does dog done door down draw dream dress
drink drive dry each early earth eat egg eight else end enough even evening ever every eye face fall family
far fast father feel few find fine fire first fish five floor fly food foot for four friend from front full
fun funny game garden get girl give glad go good got great green grow hair half hand happy hard hat have he
head hear heard help her here high hill him his hold home hope horse hot house how hurt idea if inside into
jump just keep kid kind king know lady land large last late laugh learn left leg let letter life light like
line little live long look lot love low make man many may me mean meet men might milk mind miss mom money more
morning most mother move much music must my name near need never new next nice night nine no nobody none
nose not nothing now number of off often old once one only open or other our out over own page paper park
part party people pick picture place plant play please point pretty pull put queen question quick quiet
rain ran read ready red rest ride right river road rock room round run sad said same saw say school sea
second see seen seven she ship shoe shop short should show sick side sing sister sit six sleep slow small
snow so some someone something sometimes song soon sound speak stand star start stay still stop store story
street strong such sun sure swim table take talk tall teacher tell ten than thank that the their them then
there these they thing think third this those three through time to today together told too took top toy
tree try turn two under until up upon us use very walk wall want warm was wash watch water way we wear week
well went were what when where which while white who why will window wish with without woman women word work
world would write year yellow yes yet you young your""".split())

# Words looked at by hand and left out: WordNet's main sense is not the one a kid means, or the word is jargon.
REVIEW_SKIP = set("""abbot abstract accelerated accord accordance accreditation achievable acquired acquisition activated activism
adjective affidavit afterlife aide aired alien alignment almighty alteration amelia amended amir anna annuity
answering apache apostle apostolic appreciated apprehended appropriation arrival articulate assumed assuming
astral baptism bare barrage barrister battery beam bearer behavioural beheaded benedict bent berth betting
birdie blah blamed bloke blond blooded bolivia bolt bond bonnie booker boost booty bowman breadth breakdown
breathed brightness brush buck buff bulk burgess cable calif caller canon capture cardinal cashed catholic
celebrate challenger chapman charged checked chemotherapy chevy childbirth choked chorus chuck circulation
circumstantial citation clap clash clerical clever clinch clinched collier combo comeback commodore communion
commute comp completing completion composition concentration conception concession confirmed congested
conjunction conn conscious consensual conservation conservatism consist consort consume contained contender
conversion coroner corp corporal corrected couture crash crashing cream cretaceous crimson cripple crippled
crown crush crushed crushing cube cubic cult curve dare deacon dealership dearest decay deduction defect
defending deformed deity delayed delicious dementia determination developing dexter diabetes difficulty dipped
disabled discharge discharged disciple disk dismiss dismissed displacement dissolve distraction diva diverted
divinity divisive divorce divorced dominance donna doom doomed drawn dreamed drenched driven dropping drown
drugged dyed dyer dying earliest earnest ecclesiastical effected eighteenth eighth elevation eleventh elves
embarrassing enabling engage engagement envious epilepsy episcopal escalation evacuation evolve excellency
exception executed expedition exploded exploitation exquisite extinguished eyed fabian faculty faint fancied
fare fella feminine fetal fiance fiat fifteenth figured fill filled fitness flavor flick flock flux fooling
footed foreclosure forgotten fortune fowler freeman frustrated funeral fusion gabby galaxy gangster gear
generalized genome genus ghost glorified gossip gourmet gran granny grave gross guise gypsy handicapped harm
hated headache healer hector heroic hippie hipster hitch hobby holocaust homer honeymoon hoover hostilities
housewife hover hubby humor husky hustle hydrated idiotic impacted implement implemented implicated impression
incidence incompetent indifference induction influenza info inhibit inmate inquisition insane insanity insider
inspirational inspire insure integrity intense intensity inter interference internship intravenous investigator
involve ionic irony isolated isolating issuance jailed jealous jonah josh jumbo junta justified karma kidnap
kingdom kiss knot laid lambert langley lash lazy lend lethal leukemia levant liabilities liberate liberty lieu
lighted linear literal litre lockdown madness maid maiden majesty malaria malignant malik mamma manage maneuver
mania manifest manned marital marquis marshal martyr masculine matching mater mechanism medium mercer messiah
minded minority missionary modeled modify mojo mold molded momma mommy morrow motherhood motion motto mounted
murderous mute mutilated mystic native nausea navigate nemesis nineteenth ninth noble nodding nordic nudity
observing obstacle offender offense oncology opener oppressed orderly organic organised ornate outfit owing
oxidation painless paradigm parameter paranoia parish parked parted pathology pattern payable peaked pedigree
penetrating penny pentagon personnel philosophy placement plantation platonic playboy pneumonia polar populist
portion portrait pose posed posterior precious precision premiership prenatal pressed pressing prima primed
principal proceed proceeds progression projected projecting proto prototype proven provision proximal pseudo
psyche psychiatry pursuant pursue quirky racial racking raiding rand ranging realised realized realm realty rear
recognize reconnaissance reconstruct reconstructed rector reddish reflect reflected regiment reinforcement
rejected relative releasing reluctant renal render renewal represent representation repressed reproductive
requirement resist resolution resonance restrained resurrection retain revelation riddle ridiculous risen rite
romance rooted royalty ruled ruth rutherford sacked salary salty satire saviour scandal scented scoreless
scratch scripture secure seizure seminary sensory sept septic sermon seventeenth seventh shanghai sharia sharp
sheikh sherlock shining shortage shove showtime shrink sinner sixteenth sixth slate slayer slice slight slip
slogan slot slug sniper soil somerset sonny sounding spare spark spec specialised spectacle spectator sphere
spike split spooky spree spur stalk statesman stiff stoke storm stout strangled streaming stretch stricken
strict studied stupidity subdued subscribe subscribed suite sultan sunk supremacy sweetie swept swollen sympathy
synthesis tally tapped teased tech techno telecom temporal tenth testament thatcher theological theology
threatened thug tingling token topical topped torn torque totaled trademark trader trail trance transmitted
trapped travelled traveller treatise trespassing triple trojan trooper troy tuberculosis tumor tumour twain
twelfth twentieth twisted unanswered uncovered underwood undocumented undue unfold unloaded unqualified upgrade
urge usher utilised utility vacant vain vest vested veteran violated vitality viva voiced vowel waiter wally
wandering warden warp watered waterloo whatsoever widowed wield willingness witchcraft wont worn wrestle
wrestler wrought yang yield""".split())
# Words whose WordNet "synonym" is technically right but would mislead a kid.
SYN_SKIP = set("""aforementioned aired arguing assumed attest backing behavioural biting bizarre buffet caliber cater command
comprehend concerted conducive conquer cooperative coordinate criticise criticize debut decree defy delicious
delightful dependence dependency derive deserving detection determination diagnosis dictate disabled discount
disperse distortion diverted doctrine domain engage engagement exceeding faded ferocious frightening fulfil
fulfill fused gram gray grumpy hallmark handicapped hazard immediate implanted implemented infected infinity
inhibit initiation intake integration integrity interpreted jeopardy keen manifest manpower maximum measurement
meditate militia minimal minimum mold mundane muse mute newcomer nomadic occasion optimal optimum organisational
papers patriotism patronage peaked penetrating personalised pound prescribe preserve projected proven prowess
racking reddish redevelopment relentless remarkable rendition replacing rescued resign respective retention
sarcasm sentinel singular smuggled sounding specialised spiritual sprinkle sticking strangled struck sunny
superstar suppress swollen talent talks transmitted traveler tribunal ultra unity unwell usage utilization
vacate valuation withstand workforce wrought""".split())

VOWEL_SOUND = re.compile(r"^(?:[aeio]|u(?![nr]i|s[eu]|t[ei])|hon|hour|heir)", re.I)


def zipf(w):
    return wordfreq.zipf_frequency(w, "en")


def is_bad_word(w):
    if w in BAD_WORDS:
        return True
    return any(p in w for p in BAD_PARTS)


def synset_ok(s):
    domains = {d.name().split(".")[0].replace("_", " ") for d in s.usage_domains()}
    if domains & BAD_DOMAINS:
        return False
    if BAD_GLOSS.search(s.definition()):
        return False
    if s.lexname() in SKIP_LEXNAMES:
        return False
    if s.instance_hypernyms():
        return False
    return True


def word_flagged(w):
    """True when any sense of the word is rude or adult, so the whole word is skipped."""
    for s in wn.synsets(w):
        names = {l.name().lower() for l in s.lemmas()}
        if w not in names:
            continue
        domains = {d.name().split(".")[0].replace("_", " ") for d in s.usage_domains()}
        if domains & {"vulgarism", "obscenity", "ethnic slur", "disparagement"}:
            return True
        g = s.definition()
        if re.search(r"\b(sex|sexual|sexually|genitals?|intercourse|erotic|obscene|vulgar|offensive term|"
                     r"slur|prostitut\w*|pornograph\w*|masturbat\w*|copulat\w*)\b", g, re.I):
            return True
    return False


def ranked_senses(w):
    """(synset, tagged count) for this exact lowercase lemma, most used first (WordNet order breaks ties)."""
    out, seen = [], set()
    for s in wn.synsets(w):
        lem = [l for l in s.lemmas() if l.name() == w]
        if not lem or s in seen:
            continue
        seen.add(s)
        out.append((s, lem[0].count()))
    out.sort(key=lambda x: -x[1])
    return out


def best_sense(w):
    r = ranked_senses(w)
    return r[0] if r else (None, -1)


def clean(text):
    t = text.replace("``", '"').replace("''", '"').replace("`", "'")
    t = t.replace("--", ", ").replace("—", ", ").replace("–", ", ")
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(r"\s+([,;.])", r"\1", t)
    return t


PLAIN = [(r"\bexhibiting\b", "showing"), (r"\bpossessing\b", "having"), (r"\bcharacterized by\b", "marked by"),
         (r"\bsimultaneously\b", "at the same time"), (r"\bsubsequently\b", "later"), (r"\bprior to\b", "before"),
         (r"\bin order to\b", "to"), (r"\bapproximately\b", "about"), (r"\bsufficient\b", "enough"),
         (r"\bnumerous\b", "many"), (r"\bindividuals\b", "people"), (r"\ban individual\b", "a person"),
         (r"\bmagnitude\b", "size"), (r"\bpertaining to\b", "having to do with"), (r"\butilize\b", "use"),
         (r"\bdeficient in\b", "lacking"), (r"\bcommence\b", "begin"), (r"\butterance\b", "statement"),
         (r"\bendeavor\b", "effort"), (r"\bthe state of being\b", "being"), (r"\bthe quality of being\b", "being")]


def plain(g):
    g = re.sub(r"\bsuch as e\.g\.", "such as", g)
    g = re.sub(r"\s*\be\.g\.\s*", " ", g)
    for a, b in PLAIN:
        g = re.sub(a, b, g)
    return g


def short_gloss(s):
    g = clean(s.definition())
    g = re.sub(r"^\((?:often|usually|sometimes|followed|used|of|especially)[^)]*\)\s*", "", g)
    parts = [p.strip() for p in g.split(";") if p.strip()]
    if not parts:
        return None
    out = plain(parts[0])
    out = re.sub(r"\s*\([^)]*\)", "", out).strip(" ,")
    out = re.sub(r",? etc\.?$", "", out).rstrip(".:;, ")
    if re.match(r"^being (one|ten|two|three|four|five|six|seven|eight|nine) more than", out):
        return None
    if len(out) < 8 or re.search(r"(^|\s)- ?[A-Z]", out):
        return None
    return out


def lead(w, s, gloss):
    p = s.pos()
    if p == "v":
        if not re.match(r"^(to |be |make |cause |have |become |give |take |put |get |go |come |keep |set )", gloss):
            pass
        g = gloss if gloss.startswith("to ") else "to " + gloss
        return f"To {w} means {g}."
    if p in ("a", "s"):
        return f"{w.capitalize()} means {gloss}."
    if p == "r":
        return f"{w.capitalize()} means {gloss}."
    # noun
    if re.match(r"^(a|an) (person|man or woman|someone|individual|worker|member) ", gloss) or gloss.startswith("someone "):
        g = re.sub(r"^someone ", "someone who ", gloss) if gloss.startswith("someone ") and not gloss.startswith("someone who") else gloss
        if gloss.startswith("someone "):
            return f"{article(w).capitalize()} {w} is {gloss}."
        return f"{article(w).capitalize()} {w} is {gloss}."
    return f"{w.capitalize()} means {gloss}."


def article(w):
    return "an" if VOWEL_SOUND.match(w) else "a"


def example_for(w, s):
    forms = {w, w + "s", w + "es", w + "ed", w + "d", w + "ing", w + "ly", w + "er", w[:-1] + "ing" if w.endswith("e") else w,
             w[:-1] + "ied" if w.endswith("y") else w, w[:-1] + "ies" if w.endswith("y") else w,
             w + w[-1] + "ed", w + w[-1] + "ing"}
    for ex in s.examples():
        e = re.sub(r"\s*\([^)]*\)", "", clean(ex)).strip('"').strip()
        toks = set(re.findall(r"[a-z]+", e.lower()))
        if not (toks & forms):
            continue
        if not 12 <= len(e) <= 100 or "..." in e or ";" in e or ":" in e:
            continue
        if is_bad_text(e) or check_data.DATED_RE.search(e):
            continue
        if re.search(r"\b(he|she|his|her|him|hers|himself|herself)\b", e, re.I):
            # keep examples free of gendered pronouns about unnamed people
            continue
        return e[0].upper() + e[1:]
    return None


def is_bad_text(t):
    if BAD_GLOSS.search(t):
        return True
    toks = re.findall(r"[a-z]+", t.lower())
    return any(is_bad_word(x) for x in toks)


def synonym_for(w, s):
    """A clearly good synonym: single common word in the same sense, whose own main sense is this one too."""
    best = None
    for l in s.lemmas():
        n = l.name()
        if n == w or "_" in n or "-" in n or not n.isalpha() or n.lower() != n:
            continue
        if n.startswith(w) or w.startswith(n) or l.count() < 1:
            continue
        z = zipf(n)
        if z < 3.0 or is_bad_word(n) or word_flagged(n):
            continue
        ns, _ = best_sense(n)
        if ns != s:
            continue
        if best is None or z > best[1]:
            best = (n, z)
    return best[0] if best else None


def load_taken():
    """Wordings and key sets already used outside this generator's own file."""
    taken = set(check_data.core_wordings())
    keys = set()
    for k in list(taken):
        ks = check_data.keyset(k)
        if len(ks) >= 2:
            keys.add(ks)
    for path in glob.glob(os.path.join(KNOW, "data", "**", "*.txt"), recursive=True):
        if os.path.abspath(path) == os.path.abspath(OUT):
            continue
        entries, _ = check_data.parse_txt(path)
        for _, _, qs, _ in entries:
            for q in qs:
                taken.add(check_data.norm(q))
                ks = check_data.keyset(q)
                if len(ks) >= 2:
                    keys.add(ks)
    return taken, keys


def free(wordings, taken, keys):
    for q in wordings:
        if check_data.norm(q) in taken:
            return False
        ks = check_data.keyset(q)
        if len(ks) >= 2 and ks in keys:
            return False
    return True


def claim(wordings, taken, keys):
    for q in wordings:
        taken.add(check_data.norm(q))
        ks = check_data.keyset(q)
        if len(ks) >= 2:
            keys.add(ks)


def candidates():
    seen = set()
    for w in wordfreq.top_n_list("en", 60000):
        if w in seen or not w.isalpha() or not w.isascii() or len(w) < 4:
            continue
        seen.add(w)
        z = zipf(w)
        if not LOW <= z <= HIGH:
            continue
        if w in EASY or is_bad_word(w):
            continue
        yield w, z


ABSTRACT = {"noun.attribute", "noun.act", "noun.feeling", "noun.cognition", "noun.communication", "noun.state",
            "noun.event", "noun.process", "noun.relation", "noun.motive", "noun.phenomenon", "noun.group",
            "noun.person", "noun.possession", "noun.time", "noun.shape", "noun.quantity"}


def priority(s):
    """Lower comes first: describing words and actions, then idea words, then adverbs, then things."""
    if s.pos() in ("a", "s", "v"):
        return 0
    if s.lexname() in ABSTRACT:
        return 1
    if s.pos() == "r":
        return 2
    return 3


def pick():
    out = []
    for w, z in candidates():
        if w in REVIEW_SKIP or re.fullmatch(r"[ivxlcdm]+", w):
            continue
        # base forms only: skip plurals, past tenses and -ing forms
        base = {wn.morphy(w, p) for p in (wn.NOUN, wn.VERB, wn.ADJ, wn.ADV)} - {None}
        if base and w not in base:
            continue
        ranked = ranked_senses(w)
        if not ranked or word_flagged(w):
            continue
        s, cnt = ranked[0]
        # with no tagged uses we can't tell which sense is the common one, so only keep one-sense words
        if cnt <= 0 and len(ranked) > 1:
            continue
        # with only one tagged use among several senses, the pick is a coin toss, so skip the word
        if cnt <= 1 and len(ranked) > 1:
            continue
        # plural nouns ("losses", "shoes") are left to their singular
        if w.endswith("s") and not w.endswith(("ss", "us", "is", "ous")) and \
                (wn.synsets(w[:-1], wn.NOUN) or (w.endswith("es") and wn.synsets(w[:-2], wn.NOUN))):
            continue
        # "-ing" words used as nouns ("laying", "trading") usually get an odd sense
        if w.endswith("ing") and s.pos() == "n":
            continue
        if s.pos() == "n" and w.endswith("s") and any(l.name() in (w[:-1], w[:-2]) for l in s.lemmas()):
            continue
        if not synset_ok(s):
            continue
        # everyday objects that are fairly common are things a kid already knows
        if s.lexname() in ("noun.artifact", "noun.object", "noun.person") and z > 3.9:
            continue
        if SKIP_GLOSS_START.match(s.definition()):
            continue
        gloss = short_gloss(s)
        if not gloss or is_bad_text(gloss) or check_data.DATED_RE.search(gloss) or re.search(r"\d", gloss):
            continue
        # a gloss that just repeats the word (or its stem) does not explain anything
        if re.search(r"\b" + re.escape(w[:max(4, len(w) - 3)]), gloss, re.I):
            continue
        # a close second sense is added as "It can also mean", so the answer isn't stuck on a rarer sense
        second = None
        for s2, c2 in ranked[1:3]:
            if c2 >= max(2, cnt / 2) and s2.pos() == s.pos() and synset_ok(s2):
                g2 = short_gloss(s2)
                if g2 and not is_bad_text(g2) and not check_data.DATED_RE.search(g2) and \
                        not re.search(r"\b" + re.escape(w[:max(4, len(w) - 3)]), g2, re.I):
                    second = g2
                break
        dominant = second is None and (len(ranked) == 1 or cnt >= 2 * max(1, ranked[1][1]))
        out.append((priority(s), -z, w, s, gloss, second, dominant))
    out.sort(key=lambda x: (x[0], x[1]))
    return out


# ---------- antonyms ("what is the opposite of X") ----------
# Pairs come from WordNet's own antonym links on the word's most used sense. These were read through by hand;
# words whose WordNet opposite is technical, odd or unkind are skipped, and a few get a clearer answer.
ANT_SKIP = set("""all some no other used whole due serious frivolous basic incidental emotional cerebral anti pro
evolution devolution parallel oblique distributed concentrated expanded contracted instrumental vocal induced
spontaneous align skew misconception conception publicized suppressed distal proximal sober intoxicated
intelligence stupidity sane insane sanity insanity pointed pointless net gross tough tender delicate rugged gather
spread born unborn veil unveil veiled unveiled lesser greater incredible""".split())
ANT_OVERRIDE = {
    "big": "The opposite of big is small or little.",
    "little": "The opposite of little is big or large.",
    "old": "The opposite of old is young (for age) or new (for things).",
    "young": "The opposite of young is old.",
    "short": "The opposite of short is long (for length) or tall (for height).",
    "same": "The opposite of same is different.",
    "real": "The opposite of real is fake, unreal or imaginary.",
    "happy": "The opposite of happy is sad or unhappy.",
    "trust": "The opposite of trust is distrust.",
    "close": "The opposite of close (near) is far or distant. The opposite of close (shut) is open.",
    "nice": "The opposite of nice is mean or unkind (or nasty).",
    "cool": "The opposite of cool is warm.",
    "light": "The opposite of light is dark (for color) or heavy (for weight).",
    "cheerful": "The opposite of cheerful is sad or gloomy.",
    "acute": "For an illness, the opposite of acute (sudden and short) is chronic (long-lasting). For angles, an acute angle is under 90° and an obtuse angle is over 90°.",
    "outgoing": "The opposite of outgoing (friendly and social) is shy. For things leaving, like mail, the opposite is incoming.",
    "dull": "The opposite of dull is lively or exciting (for something boring), or sharp (for a blade).",
}


def antonym_pairs():
    seen = set()
    for w in wordfreq.top_n_list("en", 40000):
        if w in seen or not w.isalpha() or not w.isascii() or len(w) < 3:
            continue
        seen.add(w)
        if zipf(w) < 3.2 or is_bad_word(w) or w in REVIEW_SKIP or w in ANT_SKIP:
            continue
        base = {wn.morphy(w, p) for p in (wn.NOUN, wn.VERB, wn.ADJ, wn.ADV)} - {None}
        if base and w not in base:
            continue
        ranked = ranked_senses(w)
        if not ranked:
            continue
        s, cnt = ranked[0]
        if cnt < 2 and len(ranked) > 1:
            continue
        if word_flagged(w):
            continue
        found = None
        for l in s.lemmas():
            if l.name() != w:
                continue
            for a in l.antonyms():
                n = a.name()
                if not n.isalpha() or n.lower() != n or n in ANT_SKIP or is_bad_word(n) or word_flagged(n):
                    continue
                if zipf(n) < 3.0 or best_sense(n)[0] != a.synset():
                    continue
                found = n
                break
            if found:
                break
        if found:
            yield w, found


def main():
    taken, keys = load_taken()
    meanings, synonyms = [], []
    # Only the first MAX_RANK candidates were read through by hand (see REVIEW_SKIP), so stop there even when
    # some of them are dropped because another file already covers the word.
    for _, _, w, s, gloss, second, dominant in pick()[:MAX_RANK]:
        ans = lead(w, s, gloss)
        if second:
            g2 = second if s.pos() != "v" or second.startswith("to ") else "to " + second
            ans += f" It can also mean {g2}."
        ex = example_for(w, s)
        syn = synonym_for(w, s) if dominant and w not in SYN_SKIP else None
        extra = ""
        if ex:
            extra += f' Example: "{ex}."' if not ex.endswith((".", "!", "?")) else f' Example: "{ex}"'
        if syn:
            extra += f" A word that means about the same is {syn}."
        if len(ans) + len(extra) > 340:
            extra = f" A word that means about the same is {syn}." if syn else ""
        ans = (ans + extra).strip()
        if len(ans) > 350:
            continue
        qs = [f"what does {w} mean", f"define {w}", f"meaning of {w}"]
        qs.append(f"what is the definition of {w}" if len(meanings) % 2 else f"what does the word {w} mean")
        # if any other file already explains this word (in any wording), leave the word to that file
        if not free(qs + [f"what is {article(w)} {w}", f"what is {w}", f"{w} meaning", f"what are {w}"], taken, keys):
            continue
        claim(qs, taken, keys)
        meanings.append((w, qs, ans))
        if syn and len(synonyms) < TARGET_SYNONYMS:
            sq = [f"whats a synonym for {w}", f"another word for {w}", f"synonym of {w}"]
            if free(sq, taken, keys):
                claim(sq, taken, keys)
                g = gloss if s.pos() != "v" else ("to " + gloss if not gloss.startswith("to ") else gloss)
                sa = f"A synonym for {w} is {syn}. Both can mean {g}."
                if len(sa) > 350:
                    sa = f"A synonym for {w} is {syn}."
                synonyms.append((w, sq, sa))
    antonyms = []
    for w, n in antonym_pairs():
        aq = [f"what is the opposite of {w}", f"opposite of {w}", f"antonym for {w}"]
        if not free(aq, taken, keys):
            continue
        claim(aq, taken, keys)
        antonyms.append((w, aq, ANT_OVERRIDE.get(w, f"The opposite of {w} is {n}.")))
    meanings.sort()
    synonyms.sort()
    antonyms.sort()
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# Generated by tools/knowledge/gen/school_vocab.py from Princeton WordNet 3.0 and wordfreq.\n")
        f.write("# Do not edit by hand; change the generator and run it again.\n")
        f.write("# tag: school.vocab\n")
        for w, qs, a in meanings:
            f.write(" | ".join(qs) + " => " + a + "\n")
        f.write("\n# tag: school.vocab.synonym\n")
        for w, qs, a in synonyms:
            f.write(" | ".join(qs) + " => " + a + "\n")
        f.write("\n# tag: school.vocab.antonym\n")
        for w, qs, a in antonyms:
            f.write(" | ".join(qs) + " => " + a + "\n")
    print(f"wrote {len(meanings)} meanings, {len(synonyms)} synonyms and {len(antonyms)} antonyms to {os.path.relpath(OUT, os.getcwd())}")


if __name__ == "__main__":
    main()
