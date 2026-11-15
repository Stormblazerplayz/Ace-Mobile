"""Shared helpers for the geo_* generators in this folder.

Each generator builds entries with Writer.add() and saves them with Writer.save(). The writer drops any
wording that is already used anywhere else in the knowledge pack or in Ace/Resources/qa_bank.json (same
normalized text or same set of important words, the same test check_data.py uses), and drops an entry
when fewer than two wordings are left. That keeps generated files clean when hand-written files change.
"""
import glob
import json
import os
import random
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.normpath(os.path.join(HERE, ".."))
ROOT = os.path.normpath(os.path.join(KNOW, "..", ".."))
DATA = os.path.join(KNOW, "data", "geo")
CACHE = os.path.join(KNOW, ".cache")

sys.path.insert(0, KNOW)
from check_data import norm, keyset, parse_txt, DATED_RE, YEAR_RE  # noqa: E402

DASHES = ("—", "–")


def ascii_fold(s):
    """'São Tomé' -> 'sao tome' (how people type it)."""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return s.replace("ʻ", "").replace("’", "'").lower()


def cap(s):
    return s[0].upper() + s[1:] if s else s


def poss(name):
    return name + ("'" if name.endswith("s") else "'s")


def a_an(word):
    return ("an " if word[0].lower() in "aeiou" else "a ") + word


def fmt_int(n):
    return f"{int(round(n)):,}"


def m_ft(meters):
    feet = meters * 3.28084
    return f"{fmt_int(meters)} meters ({fmt_int(round(feet, -1) if feet >= 1000 else round(feet))} feet)"


def km2_mi2(km2):
    mi2 = km2 / 2.58999
    return f"{sig(km2)} square kilometers ({sig(mi2)} square miles)"


def sig(x, digits=3):
    """Rounds to a few significant figures and formats with commas."""
    if x == 0:
        return "0"
    if x < 10:
        return f"{x:.1f}".rstrip("0").rstrip(".")
    import math
    p = int(math.floor(math.log10(abs(x)))) - digits + 1
    v = round(x, -p) if p > 0 else round(x)
    return fmt_int(v)


class Writer:
    def __init__(self, outputs):
        """outputs: file names (in data/geo) this generator writes; they are ignored when loading."""
        self.outputs = {os.path.join(DATA, o) for o in outputs}
        self.seen = {}
        self.seen_keys = {}
        self.files = {}
        self.dropped = []
        self._load()

    def _load(self):
        core = os.path.join(ROOT, "Ace", "Resources", "qa_bank.json")
        if os.path.exists(core):
            for e in json.load(open(core, encoding="utf-8"))["entries"]:
                for q in e["q"]:
                    self._mark(q, "core")
        for path in sorted(glob.glob(os.path.join(KNOW, "data", "**", "*.txt"), recursive=True)):
            if path in self.outputs:
                continue
            entries, _ = parse_txt(path)
            for n, tag, qs, ans in entries:
                for q in qs:
                    self._mark(q, f"{os.path.relpath(path, KNOW)}:{n}")

    def _mark(self, q, where):
        k = norm(q)
        self.seen.setdefault(k, where)
        ks = keyset(q)
        if len(ks) >= 2:
            self.seen_keys.setdefault(ks, where)

    def free(self, q):
        k = norm(q)
        if k in self.seen:
            return False
        ks = keyset(q)
        return not (len(ks) >= 2 and ks in self.seen_keys)

    def add(self, fname, tag, wordings, answer, min_wordings=2, limit=5):
        if any(d in answer for d in DASHES):
            raise ValueError(f"dash in answer: {answer}")
        answer = re.sub(r"\s+", " ", answer).strip()
        if not 15 <= len(answer) <= 600:
            raise ValueError(f"answer length {len(answer)}: {answer}")
        if DATED_RE.search(answer) and not YEAR_RE.search(answer):
            raise ValueError(f"dated answer needs a year: {answer}")
        answer = cap(answer)
        keep, keys_here = [], set()
        for q in wordings:
            q = re.sub(r"\s+", " ", q.lower().replace("?", "")).strip()
            if not q or len(q.split()) > 16:
                continue
            ks = keyset(q)
            if not self.free(q) or norm(q) in {norm(x) for x in keep} or (len(ks) >= 2 and ks in keys_here):
                continue
            keep.append(q)
            keys_here.add(ks)
            if len(keep) == min(limit, 6):
                break
        if len(keep) < min_wordings:
            self.dropped.append((fname, wordings[:2], answer[:60]))
            return False
        for q in keep:
            self._mark(q, fname)
        self.files.setdefault(fname, []).append((tag, keep, answer))
        return True

    def save(self, header):
        os.makedirs(DATA, exist_ok=True)
        total = 0
        for fname, rows in self.files.items():
            lines = [f"# {line}" for line in header.strip().splitlines()]
            last = None
            for tag, qs, ans in rows:
                if tag != last:
                    lines.append(f"# tag: {tag}")
                    last = tag
                lines.append(" | ".join(qs) + " => " + ans)
            with open(os.path.join(DATA, fname), "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
            print(f"  {fname}: {len(rows)} entries")
            total += len(rows)
        print(f"  total {total}, dropped {len(self.dropped)}")
        return total


def pick(rng, pool, n):
    """Picks n different templates from pool in a stable random order."""
    pool = list(pool)
    rng.shuffle(pool)
    return pool[:n]


def rng_for(*parts):
    return random.Random("|".join(parts))


def add_block(w, fname, text, limit=5):
    """Adds hand-written entries. Lines are '## tag' or 'wording | wording => Answer'."""
    tag = None
    for n, line in enumerate(text.strip().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#!"):
            continue
        if line.startswith("## "):
            tag = line[3:].strip()
            continue
        if " => " not in line:
            raise ValueError(f"{fname}: bad line {n}: {line[:60]}")
        qs, ans = line.split(" => ", 1)
        w.add(fname, tag, [q.strip() for q in qs.split("|")], ans.strip(), limit=limit)
