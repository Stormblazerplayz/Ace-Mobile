"""A Python copy of Ace/Brain/TextKit.swift (normalize, canonical, words, stem, keywords).

The knowledge pack stores each question's words already split and stemmed, so the iPad doesn't have to
run TextKit's regexes over 200,000 wordings at launch. That only works if this file does exactly what
the Swift code does. AceTests/KnowledgePackTests.swift checks a sample on the device and fails if they
ever drift apart, so change both files together.

Needs the `regex` module (pip install regex) for \\p{L} and \\p{N}, like Swift's ICU regexes.
"""
import regex as re

STOPWORDS = set("""a an the is are was were be been am do does did of to in on at for and or but it its this that these
those i me my you your we us our he she they them their his her please can could would should will shall tell say know
about what whats what's how who whos when where why which there here with from by as so if then just hey ace okay ok
um uh like really some any much many have has had get got give show find let lets let's want wanna need into up
out""".split())

CONTRACTIONS = {"what's": "what is", "whats": "what is", "who's": "who is", "where's": "where is",
                "how's": "how is", "it's": "it is", "i'm": "i am", "im": "i am", "you're": "you are",
                "don't": "do not", "can't": "can not", "cannot": "can not", "won't": "will not",
                "isn't": "is not", "didn't": "did not", "doesn't": "does not", "let's": "let us",
                "wanna": "want to", "gonna": "going to", "u": "you", "ur": "your", "pls": "please",
                "plz": "please", "thx": "thanks"}

_TRIM = "?!,;:\"()[]{}"
_DROP = re.compile(r"[^\p{L}\p{N}\s\+\-\*/\.%'°#&]")
_SPACES = re.compile(r"\s+")


def _swift_template(t):
    # NSRegularExpression templates use $1; Python uses \1.
    return re.sub(r"\$(\d)", r"\\\1", t)


SAME_PHRASES = [(re.compile(p), _swift_template(w)) for p, w in [
    (r"\b(came|come|comes|coming) up with\b", "invented"),
    (r"\bthought up\b", "invented"),
    (r"\b(second world war|world war two|world war ii|ww2|wwii)\b", "world war 2"),
    (r"\b(first world war|world war one|world war i|ww1|wwi)\b", "world war 1"),
    (r"\b(united states of america|the usa|usa|the us|the u\.s\.?|u\.s\.a\.?)\b", "united states"),
    (r"\bus president\b", "president of the united states"),
    (r"\b(stand|stands|short) for\b", "mean"),
    (r"\b(are|is|am) (you|i|it|we|they) able to\b", "can $2"),
    (r"\bable to\b", "can"),
    (r"\bis it (ok|okay|alright|fine|safe|smart|a good idea) (to|if i)\b", "should i"),
    (r"\b(?:who is |whos )?the (?:person|guy|man|woman|people|one|company) (?:that|who) (made|created|invented|built|discovered|founded|wrote|painted|designed|started)\b", "who $1"),
    (r"\bhow (?:quick|quickly|speedy|rapid|rapidly)\b", "how fast"),
    (r"\b(?:what|which) number element is\b", "what is the atomic number of"),
    (r"\b(?:element|atomic) number (?:of|for)\b", "atomic number of"),
    (r"\bhow many (?:people|persons|kids|guys) (?:play|are|go) (?:on|in)\b", "how many players are on"),
    (r"\b(?:what is|whats) the distance (?:from|between)\b", "how far is it from"),
    (r"^distance (?:from|between)\b", "how far is it from"),
    (r"\b(?:go|goes|went|gone) down\b(?=\s*$)", "sink"),
    (r"\bin (?:the )?(?:a\.?i\.?|artificial intelligence)\b", "in ai"),
    (r"\bhow old is (?:the )?planet earth\b", "how old is the earth"),
    (r"\bhow long ago (?:was|were|did)\b", "when was"),
    (r"\b(?:what is|whats) the (?:meaning|definition) of\b", "what does mean"),
    (r"\bgive me (?:some |a few |a couple of )?(?:facts|info|information) (?:about|on)\b", "tell me about"),
    (r"\b(?:can you |could you )?(?:teach me|tell me) (?:a bit |a little |something )?about\b", "tell me about"),
]]

SUBJECT_AT_END = {"us", "he", "as", "at", "be", "no", "am"}

SAME_MEANING = {
    "largest": "biggest", "hugest": "biggest", "greatest": "biggest",
    "large": "big", "huge": "big", "giant": "big", "enormous": "big", "massive": "big",
    "tiny": "small", "little": "small", "smallest": "small", "tiniest": "small",
    "fastest": "fast", "quickest": "fast", "speediest": "fast", "quick": "fast", "speedy": "fast", "rapid": "fast",
    "speed": "fast", "distance": "far", "money": "currency", "cash": "currency",
    "founded": "start", "founder": "start", "sank": "sink", "sunk": "sink",
    "upset": "sad", "unhappy": "sad", "afraid": "scared", "frightened": "scared", "mad": "angry", "furious": "angry",
    "sleepy": "tired", "exhausted": "tired", "starving": "hungry",
    "highest": "tallest", "high": "tall",
    "invented": "invent", "inventor": "invent", "invents": "invent", "created": "invent", "creator": "invent",
    "kids": "child", "kid": "child", "children": "child",
    "mom": "mother", "mum": "mother", "mommy": "mother", "dad": "father", "daddy": "father",
    "film": "movie", "films": "movie", "movies": "movie",
    "colour": "color", "colours": "color", "favourite": "favorite", "fav": "favorite",
    "pc": "computer", "laptop": "computer", "tablet": "ipad",
    "begin": "start", "began": "start", "started": "start", "beginning": "start",
    "finish": "end", "ended": "end", "finished": "end",
    "temp": "temperature", "hottest": "hot", "coldest": "cold",
    "years": "year", "yrs": "year", "km": "kilometer", "kilometres": "kilometer", "kilometers": "kilometer",
    "metres": "meter", "meters": "meter", "metre": "meter",
    "kg": "kilogram", "kgs": "kilogram", "kilograms": "kilogram", "lb": "pound", "lbs": "pound", "ft": "foot", "feet": "foot",
    "hr": "hour", "hrs": "hour", "mins": "minute", "secs": "second", "discovered": "discover", "discoverer": "discover",
    "humans": "human", "people": "human", "person": "human",
    "sinking": "sink", "sinks": "sink", "smartest": "smart", "clever": "smart", "intelligent": "smart",
    "closest": "nearest", "close": "near", "nearby": "near", "farthest": "far", "furthest": "far",
    "oldest": "old", "aged": "old", "age": "old", "youngest": "young", "newest": "new",
    "heaviest": "heavy", "weigh": "weight", "weighs": "weight", "lightest": "light",
    "longest": "long", "length": "long", "shortest": "short", "deepest": "deep", "depth": "deep",
    "strongest": "strong", "strength": "strong", "loudest": "loud",
    "built": "build", "builds": "build", "wrote": "write", "written": "write", "writer": "write", "author": "write",
    "painted": "paint", "painter": "paint", "sang": "sing", "singer": "sing", "sung": "sing",
    "died": "die", "dies": "die", "death": "die", "dead": "die",
    "born": "birth", "birthplace": "birth",
    "physician": "doctor",
    "automobile": "car",
    "puppy": "dog", "puppies": "dog", "doggy": "dog", "kitten": "cat", "kittens": "cat", "kitty": "cat",
    "telly": "tv", "television": "tv", "cellphone": "phone", "smartphone": "phone",
    "maths": "math", "mathematics": "math", "aeroplane": "plane", "airplane": "plane", "airplanes": "plane",
    "spaceship": "spacecraft", "rocketship": "rocket",
}


def normalize(text):
    s = text.lower()
    s = s.replace("’", "'").replace("‘", "'").replace("“", "\"").replace("”", "\"")
    words = [w for w in re.split(r"[ \n\t]", s) if w]
    words = [CONTRACTIONS.get(w.strip(_TRIM), w.strip(_TRIM)) for w in words]
    s = " ".join(words)
    s = _DROP.sub(" ", s)
    s = _SPACES.sub(" ", s)
    return s.strip(" \t").strip(".")


def canonical(normalized):
    s = normalized
    for pattern, with_ in SAME_PHRASES:
        s = pattern.sub(with_, s)
    return s


def words(text):
    out = []
    for w in canonical(normalize(text)).split(" "):
        if not w:
            continue
        w = w.strip(".'")
        if w.endswith("'s") and len(w) > 3:
            w = w[:-2]
        if w:
            out.append(w)
    return out


def _is_letters(w):
    return all(c.isalpha() for c in w)


def stem(w):
    if w in SAME_MEANING:
        return SAME_MEANING[w]
    if len(w) <= 3 or not _is_letters(w):
        return w
    if w.endswith("ies") and len(w) > 4:
        return w[:-3] + "y"
    if w.endswith("sses"):
        return w[:-2]
    if w.endswith("ing") and len(w) > 5:
        base = w[:-3]
        if len(base) >= 2 and base[-1] == base[-2] and base[-1] not in "lsz":
            return base[:-1]
        return base
    if w.endswith("ed") and len(w) > 4:
        return w[:-2]
    if w.endswith("es") and len(w) > 4 and any(w[:-2].endswith(x) for x in ("ch", "sh", "x", "ss")):
        return w[:-2]
    if w.endswith("s") and not w.endswith("ss") and not w.endswith("us") and not w.endswith("is"):
        return w[:-1]
    return w


def keywords(text):
    all_ = words(text)
    return [stem(w) for i, w in enumerate(all_)
            if w not in STOPWORDS or (i == len(all_) - 1 and w in SUBJECT_AT_END)]


COMMON_WORDS = set(stem(w) for w in """one very actually located famous exactly really even ever also quite just
real kind sort thing things stuff go goes going went gone come comes came coming with up equal equals add adds added
make makes making use uses used using able do done doing does did put take takes took get gets getting got being become
becomes became seem seems look looks looking like likes liked want wanted way ways much more most less least lot lots
bit little enough well good great nice cool okay sure certain certainly maybe probably possibly perhaps basically
literally totally completely simply generally usually normally typically often sometimes always never still already yet
again ago now currently today back over under off around away through across along whole entire every each all both
either neither other another same different such own type kinds types something anything everything nothing someone
anyone everyone somebody anybody exist exists existing happen happens happened happening mean means meant called call
calls named known part parts piece amount total main specific particular general overall usual special important major
minor current recent next previous whats anyway anyhow though although because since while during before after until
than then too yes no not dont doesnt isnt arent wasnt werent cant couldnt wont wouldnt shouldnt am into onto upon within
without between among toward towards about above below behind beside besides near inside outside throughout per via
indeed course pretty fairly rather somewhat almost nearly approximately roughly please ok alright wondering wonder
curious question questions ask asking asked answer answers tell telling told say saying said know knowing knew think
thinking thought guess guessing feel feeling explain explaining""".split())
