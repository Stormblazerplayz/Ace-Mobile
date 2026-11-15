"""Shared helpers for the games_*.py generators (Ace knowledge pack, video games area).

Writes entries in the Q&A text format described in tools/knowledge/README.md and drops any
wording that would clash with the older bank (Ace/Resources/qa_bank.json) or another file,
using the same rules as tools/knowledge/check_data.py. An entry left with fewer than 2
wordings is dropped.
"""
import glob
import os
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KN = os.path.normpath(os.path.join(HERE, ".."))
DATA = os.path.join(KN, "data", "games")
CACHE = os.path.join(KN, ".cache")
sys.path.insert(0, KN)
import check_data  # noqa: E402

DASHES = ("—", "–")


def fetch(url, rel):
    """Downloads url into .cache/rel once and returns the local path."""
    path = os.path.join(CACHE, rel)
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with urllib.request.urlopen(url) as r, open(path + ".part", "wb") as f:
            f.write(r.read())
        os.replace(path + ".part", path)
    return path


def taken(skip_files):
    """Norms and keysets already used outside the given output files."""
    norms, keys = set(), set()
    for k in check_data.core_wordings():
        norms.add(k)
        ks = check_data.keyset(k)
        if len(ks) >= 2:
            keys.add(ks)
    skip = {os.path.abspath(p) for p in skip_files}
    for path in glob.glob(os.path.join(KN, "data", "**", "*.txt"), recursive=True):
        if os.path.abspath(path) in skip:
            continue
        entries, _ = check_data.parse_txt(path)
        for _n, _t, qs, _a in entries:
            for q in qs:
                norms.add(check_data.norm(q))
                ks = check_data.keyset(q)
                if len(ks) >= 2:
                    keys.add(ks)
    return norms, keys


class Writer:
    """Collects entries for several output files and writes them with clashes removed."""

    def __init__(self, names):
        self.paths = {n: os.path.join(DATA, n) for n in names}
        self.norms, self.keys = taken(self.paths.values())
        self.files = {n: [] for n in names}
        self.dropped = 0

    def add(self, name, tag, wordings, answer):
        answer = " ".join(answer.split())
        for d in DASHES:
            answer = answer.replace(d, ", ")
        assert 15 <= len(answer) <= 600, answer
        keep, mine_n, mine_k = [], set(), set()
        for q in wordings:
            q = " ".join(q.lower().replace("?", "").split())
            if not q or len(q.split()) > 16:
                continue
            n = check_data.norm(q)
            ks = check_data.keyset(q)
            if n in self.norms or n in mine_n:
                continue
            if len(ks) >= 2 and ks in self.keys and ks not in mine_k:
                continue
            keep.append(q)
            mine_n.add(n)
            if len(ks) >= 2:
                mine_k.add(ks)
            if len(keep) == 6:
                break
        if len(keep) < 2:
            self.dropped += 1
            return False
        self.norms |= mine_n
        self.keys |= mine_k
        self.files[name].append((tag, keep, answer[0].upper() + answer[1:]))
        return True

    def write(self, header):
        os.makedirs(DATA, exist_ok=True)
        for name, entries in self.files.items():
            out = [f"# {line}" for line in header] + [""]
            last = None
            for tag, qs, a in entries:
                if tag != last:
                    out += ["", f"# tag: {tag}"]
                    last = tag
                out.append(" | ".join(qs) + " => " + a)
            with open(self.paths[name], "w", encoding="utf-8") as f:
                f.write("\n".join(out).strip() + "\n")
            print(f"{name}: {len(entries)} entries")
        print(f"dropped (too few free wordings): {self.dropped}")


def plural(name):
    """Plural of a lowercase item name (good enough for Minecraft item names)."""
    mass = ("wool", "string", "dust", "sugar", "gunpowder", "leather", "paper", "glass", "sand", "cobblestone",
            "obsidian", "powder", "meal", "wheat", "kelp", "bamboo", "deepslate", "netherrack", "clay", "gravel",
            "blackstone", "prismarine", "quartz", "scrap", "planks", "redstone", "glowstone", "stone", "honey",
            "snow", "ice", "moss", "mud", "dirt", "copper", "iron", "gold", "netherite", "lapis lazuli", "fish",
            "salmon", "cod", "beef", "mutton", "chicken", "porkchop", "rabbit", "end stone", "terracotta", "purpur",
            "concrete", "resin", "hay", "seeds", "scaffolding", "vines", "lichen", "wart", "slime", "flint", "basalt", "calcite", "tuff", "granite",
            "diorite", "andesite", "sandstone", "soul soil", "soul sand", "magma cream", "dripstone", "amethyst",
            "cocoa beans", "sweet berries", "glow berries", "nether wart", "sculk", "coal", "charcoal", "raw iron",
            "raw gold", "raw copper", "bone meal", "blaze powder", "leather", "ink", "magma cream")
    if name.startswith("block of "):
        return "blocks of " + name[9:]
    if "(" in name or name.endswith("s") or any(name == m or name.endswith(" " + m) for m in mass):
        return name
    for word in (" of ", " on a "):
        if word in name:
            a, b = name.split(word, 1)
            return plural(a) + word + b
    if name.endswith(("sh", "ch", "x")):
        return name + "es"
    if name.endswith("y") and name[-2:-1] not in "aeiou":
        return name[:-1] + "ies"
    if name.endswith("leaf"):
        return name[:-1] + "ves"
    return name + "s"


def count_of(n, name):
    if n == 1 and name.endswith(" planks"):
        return "1 " + name[:-1]
    return f"{n} {name if n == 1 else plural(name)}"


def article(name):
    if plural(name) == name and not name.endswith("s") or name.endswith(("planks", "seeds", "beans", "berries")):
        return name
    return ("an " if name[0] in "aeiou" else "a ") + name
