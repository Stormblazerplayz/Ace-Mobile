#!/usr/bin/env python3
"""Checks Ace's knowledge sources before they are built into the app.

Run from the repo root:
    python3 tools/knowledge/check_data.py            # everything
    python3 tools/knowledge/check_data.py data/coding # only files under that folder (others still count for duplicates)

What it checks
  Q&A text files (tools/knowledge/data/**/*.txt), one entry per line:
      # tag: school.math
      how do you find the area of a circle | area of a circle formula | circle area => The area of a circle is pi times the radius squared (A = πr²).
  - a "# tag: a.b" line comes before the entries (lowercase letters, digits, dots, dashes)
  - 2 to 6 wordings, lowercase, 2 to 16 words each, no question marks
  - one answer (or two, split with " || "), 15 to 600 characters each, no em dashes
  - "currently", "right now", "these days", "the current" only with a year ("as of 2025")
  - no wording used twice anywhere (also not in Ace/Resources/qa_bank.json)
  - no two entries that ask the same thing with the same important words
  Lines starting with "#" (other than "# tag:") are comments.

  Recipes (tools/knowledge/recipes/*.json), trivia (tools/knowledge/trivia/*.json),
  20 questions (tools/knowledge/twenty/*.json) and phrases (tools/knowledge/phrases/*.json)
  are checked against the same rules as the app's own files.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
RES = os.path.join(ROOT, "Ace", "Resources")
# The hand-made recipes, trivia, 20 questions and phrases that came before the pack (the app files are built from these + the new ones).
BASE = os.path.join(HERE, "base")

STOP = set("""a an the is are was were be been am do does did of to in on at for and or but it its this that these those
i me my you your we us our he she they them their his her please can could would should will shall tell say know about
what whats how who whos when where why which there here with from by as so if then just hey ace okay ok um uh like really
some any much many have has had get got give show find let lets want wanna need into up out""".split())

CONTRACTIONS = {"what's": "what is", "whats": "what is", "who's": "who is", "where's": "where is", "how's": "how is",
                "it's": "it is", "i'm": "i am", "im": "i am", "you're": "you are", "don't": "do not", "can't": "can not",
                "cannot": "can not", "won't": "will not", "isn't": "is not", "didn't": "did not", "doesn't": "does not",
                "let's": "let us", "wanna": "want to", "gonna": "going to", "u": "you", "ur": "your"}

TAG_RE = re.compile(r"^[a-z0-9][a-z0-9.\-]*$")
DATED_RE = re.compile(r"\b(currently|right now|these days|nowadays|the current|at the moment|today's)\b", re.I)
YEAR_RE = re.compile(r"\b(19|20)\d\d\b")

TRIVIA_CATEGORIES = ["Space", "Animals", "Science", "Earth", "Human Body", "History", "Geography", "Sports",
                     "Technology", "Food"]
RECIPE_CATEGORIES = {"Breakfast", "Lunch", "Dinner", "Dessert", "Snack", "Side", "Drink", "Baking", "Soup", "Salad",
                     "Sauce"}
LANGS = ["es", "fr", "de", "it", "pt", "ja", "zh", "ko", "hi", "ar", "ru", "nl"]
SAY_LANGS = ["ja", "zh", "ko", "hi", "ar", "ru"]


def norm(s):
    s = s.lower().replace("’", "'").replace("‘", "'")
    words = []
    for w in s.split():
        w = w.strip("?!,;:\"()[]{}")
        words.append(CONTRACTIONS.get(w, w))
    s = " ".join(words)
    s = re.sub(r"[^\w\s+\-*/.%'°#&]", " ", s)
    return re.sub(r"\s+", " ", s).strip().strip(".")


def stem(w):
    if len(w) <= 3 or not w.isalpha():
        return w
    if w.endswith("ies") and len(w) > 4:
        return w[:-3] + "y"
    if w.endswith("ing") and len(w) > 5:
        return w[:-3]
    if w.endswith("ed") and len(w) > 4:
        return w[:-2]
    if w.endswith("es") and len(w) > 4 and w[:-2].endswith(("ch", "sh", "x", "ss")):
        return w[:-2]
    if w.endswith("s") and not w.endswith(("ss", "us", "is")):
        return w[:-1]
    return w


def keyset(wording):
    return frozenset(stem(w.strip(".'")) for w in norm(wording).split() if w.strip(".'") not in STOP)


def parse_txt(path):
    """Yields (line_no, tag, [wordings], [answers]) and problems."""
    entries, problems = [], []
    tag = None
    for n, raw in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            m = re.match(r"^#\s*tag:\s*(\S+)\s*$", line)
            if m:
                tag = m.group(1)
                if not TAG_RE.match(tag):
                    problems.append(f"{n}: bad tag {tag!r}")
            continue
        if tag is None:
            problems.append(f"{n}: entry before any '# tag:' line")
            continue
        if line.count("=>") != 1:
            problems.append(f"{n}: needs exactly one '=>'")
            continue
        left, right = line.split("=>")
        qs = [q.strip() for q in left.split("|") if q.strip()]
        ans = [a.strip() for a in right.split("||") if a.strip()]
        entries.append((n, tag, qs, ans))
    return entries, problems


def check_entry(n, tag, qs, ans):
    p = []
    if not 2 <= len(qs) <= 6:
        p.append(f"{n}: needs 2 to 6 wordings, has {len(qs)}")
    for q in qs:
        if q != q.lower():
            p.append(f"{n}: wording isn't lowercase: {q!r}")
        if "?" in q:
            p.append(f"{n}: no question marks in wordings: {q!r}")
        wc = len(q.split())
        if not 1 <= wc <= 16:
            p.append(f"{n}: wording should be 1 to 16 words: {q!r}")
    if len(set(norm(q) for q in qs)) != len(qs):
        p.append(f"{n}: the same wording twice")
    if not 1 <= len(ans) <= 2:
        p.append(f"{n}: needs 1 or 2 answers")
    for a in ans:
        if not 15 <= len(a) <= 600:
            p.append(f"{n}: answer should be 15 to 600 characters ({len(a)})")
        if "—" in a or "–" in a:
            p.append(f"{n}: no em or en dashes in answers")
        if DATED_RE.search(a) and not YEAR_RE.search(a):
            p.append(f"{n}: a fact that changes needs a year, like 'as of 2025': {a[:60]!r}")
        first = a.split(" ")[0]
        if a[0].islower() and not any(c in first for c in "._()`:#[]=<>/") and not tag.startswith(("coding", "tech")):
            p.append(f"{n}: answer should start with a capital letter")
    return p


def core_wordings():
    path = os.path.join(RES, "qa_bank.json")
    if not os.path.exists(path):
        return {}
    out = {}
    for e in json.load(open(path, encoding="utf-8"))["entries"]:
        for q in e["q"]:
            out[norm(q)] = "qa_bank.json:" + e["id"]
    return out


def check_qa(only):
    files = sorted(glob.glob(os.path.join(HERE, "data", "**", "*.txt"), recursive=True))
    seen = core_wordings()
    seen_keys = {}
    for k, where in seen.items():
        ks = keyset(k)
        if len(ks) >= 2:
            seen_keys.setdefault(ks, (("core", where), where))
    problems, total, shown = [], 0, 0
    per_area = {}
    for path in files:
        rel = os.path.relpath(path, HERE)
        mine = only is None or rel.startswith(only)
        entries, ps = parse_txt(path)
        if mine:
            problems += [f"{rel}:{x}" for x in ps]
        for n, tag, qs, ans in entries:
            total += 1
            area = rel.split(os.sep)[1] if rel.count(os.sep) >= 2 else "data"
            per_area[area] = per_area.get(area, 0) + 1
            if mine:
                shown += 1
                problems += [f"{rel}:{x}" for x in check_entry(n, tag, qs, ans)]
            for q in qs:
                k = norm(q)
                if k in seen and mine:
                    problems.append(f"{rel}:{n}: wording {q!r} is already used at {seen[k]}")
                seen.setdefault(k, f"{rel}:{n}")
                ks = keyset(q)
                if len(ks) >= 2:
                    other = seen_keys.get(ks)
                    if other and other[0] != (rel, n) and mine:
                        problems.append(f"{rel}:{n}: asks the same as {other[1]} ({q!r})")
                    seen_keys.setdefault(ks, ((rel, n), f"{rel}:{n}"))
    return problems, total, shown, per_area


def load_json_list(folder, key):
    items = []
    for path in sorted(glob.glob(os.path.join(HERE, folder, "*.json"))):
        rel = os.path.relpath(path, HERE)
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception as ex:  # noqa: BLE001
            yield rel, None, f"not valid JSON: {ex}"
            continue
        lst = data.get(key) if isinstance(data, dict) else data
        if not isinstance(lst, list):
            yield rel, None, f"should be a list (or {{\"{key}\": [...]}})"
            continue
        for i, it in enumerate(lst):
            yield rel, (i, it), None
    return items


def check_recipes():
    problems = []
    core = json.load(open(os.path.join(BASE, "recipes.json"), encoding="utf-8"))["recipes"]
    ids = {r["id"]: "recipes.json" for r in core}
    aliases = {norm(a): "recipes.json:" + r["id"] for r in core for a in r["aliases"]}
    count = 0
    for rel, item, err in load_json_list("recipes", "recipes"):
        if err:
            problems.append(f"{rel}: {err}")
            continue
        i, r = item
        count += 1
        w = f"{rel}[{i}]"
        need = {"id": str, "name": str, "aliases": list, "category": str, "servings": int, "time": str,
                "main": list, "ingredients": list, "steps": list}
        for k, t in need.items():
            if not isinstance(r.get(k), t):
                problems.append(f"{w}: {k} should be {t.__name__}")
        if set(r) - set(need):
            problems.append(f"{w}: extra fields {sorted(set(r) - set(need))}")
        if problems and problems[-1].startswith(w):
            continue
        if not re.match(r"^[a-z0-9][a-z0-9-]*$", r["id"]):
            problems.append(f"{w}: id should be lowercase-with-dashes")
        if r["id"] in ids:
            problems.append(f"{w}: id {r['id']} is already used in {ids[r['id']]}")
        ids[r["id"]] = rel
        if r["category"] not in RECIPE_CATEGORIES:
            problems.append(f"{w}: category {r['category']!r} isn't one of {sorted(RECIPE_CATEGORIES)}")
        if not 2 <= len(r["aliases"]) <= 8:
            problems.append(f"{w}: needs 2 to 8 aliases")
        for a in r["aliases"]:
            k = norm(a)
            if k != a or not k:
                problems.append(f"{w}: alias {a!r} should be lowercase with no punctuation")
            if k in aliases:
                problems.append(f"{w}: alias {a!r} is already used by {aliases[k]}")
            aliases[k] = f"{rel}:{r['id']}"
        if not 1 <= r["servings"] <= 24:
            problems.append(f"{w}: servings looks wrong")
        if not re.match(r"^\d+( hr)?( \d+)? ?(min|hr|hours?)?$", r["time"]) and not re.match(r"^(\d+ hr )?\d+ min$|^\d+ hr$", r["time"]):
            problems.append(f"{w}: time should look like '25 min' or '1 hr 10 min', not {r['time']!r}")
        if not 2 <= len(r["main"]) <= 6:
            problems.append(f"{w}: main should list 2 to 6 key ingredients")
        if not 3 <= len(r["ingredients"]) <= 25 or not 3 <= len(r["steps"]) <= 20:
            problems.append(f"{w}: needs 3 to 25 ingredients and 3 to 20 steps")
        for s in r["ingredients"] + r["steps"] + [r["name"]]:
            if not isinstance(s, str) or "—" in s or "–" in s:
                problems.append(f"{w}: text must be strings with no em or en dashes")
                break
    return problems, count


def check_trivia():
    problems = []
    core = json.load(open(os.path.join(BASE, "trivia.json"), encoding="utf-8"))["questions"]
    ids = {q["id"]: "trivia.json" for q in core}
    qs = {norm(q["q"]): "trivia.json:" + q["id"] for q in core}
    count = 0
    for rel, item, err in load_json_list("trivia", "questions"):
        if err:
            problems.append(f"{rel}: {err}")
            continue
        i, q = item
        count += 1
        w = f"{rel}[{i}]"
        if set(q) != {"id", "category", "q", "choices", "answer", "fact"}:
            problems.append(f"{w}: fields should be id, category, q, choices, answer, fact")
            continue
        if q["id"] in ids:
            problems.append(f"{w}: id {q['id']} is already used in {ids[q['id']]}")
        ids[q["id"]] = rel
        if q["category"] not in TRIVIA_CATEGORIES:
            problems.append(f"{w}: category should be one of {TRIVIA_CATEGORIES}")
        if not isinstance(q["choices"], list) or len(q["choices"]) != 4:
            problems.append(f"{w}: needs exactly 4 choices")
            continue
        if len({norm(c) for c in q["choices"]}) != 4:
            problems.append(f"{w}: the same choice twice")
        if not isinstance(q["answer"], int) or not 0 <= q["answer"] <= 3:
            problems.append(f"{w}: answer should be 0 to 3")
        k = norm(q["q"])
        if k in qs:
            problems.append(f"{w}: same question as {qs[k]}")
        qs[k] = f"{rel}:{q['id']}"
        for s in [q["q"], q["fact"]] + q["choices"]:
            if "—" in s or "–" in s:
                problems.append(f"{w}: no em or en dashes")
                break
        if not q["q"].endswith("?"):
            problems.append(f"{w}: the question should end with '?'")
    return problems, count


def check_twenty():
    problems = []
    core = json.load(open(os.path.join(BASE, "twenty_questions.json"), encoding="utf-8"))
    qids = {q["id"] for q in core["questions"]}
    names = {t["name"].lower(): "twenty_questions.json" for t in core["things"]}
    extra_q, things = [], []
    for path in sorted(glob.glob(os.path.join(HERE, "twenty", "*.json"))):
        data = json.load(open(path, encoding="utf-8"))
        extra_q += data.get("questions", [])
        things += [(os.path.relpath(path, HERE), t) for t in data.get("things", [])]
    for q in extra_q:
        if q["id"] in qids:
            problems.append(f"twenty: question id {q['id']} used twice")
        qids.add(q["id"])
    for rel, t in things:
        n = t.get("name", "").lower()
        if not n or n in names:
            problems.append(f"{rel}: {n!r} is missing or already used in {names.get(n)}")
        names[n] = rel
        missing = qids - set(t.get("answers", {}))
        if missing:
            problems.append(f"{rel}: {n} has no answer for {sorted(missing)[:8]}")
        for k, v in t.get("answers", {}).items():
            if k not in qids or v not in (0, 0.5, 1):
                problems.append(f"{rel}: {n} answer {k}={v} (answers are 0, 0.5 or 1 for known questions)")
    return problems, len(things), len(extra_q)


def check_phrases():
    problems = []
    core = json.load(open(os.path.join(BASE, "phrasebook.json"), encoding="utf-8"))["entries"]
    seen = {}
    for e in core:
        for p in [e["en"]] + e.get("also", []):
            seen[norm(p)] = "phrasebook.json"
    count = 0
    for rel, item, err in load_json_list("phrases", "entries"):
        if err:
            problems.append(f"{rel}: {err}")
            continue
        i, e = item
        count += 1
        w = f"{rel}[{i}] {e.get('en')!r}"
        if not isinstance(e.get("t"), dict) or sorted(e["t"]) != sorted(LANGS):
            problems.append(f"{w}: t needs all 12 languages {LANGS}")
        if not isinstance(e.get("say"), dict) or sorted(e["say"]) != sorted(SAY_LANGS):
            problems.append(f"{w}: say needs {SAY_LANGS}")
        for p in [e.get("en", "")] + e.get("also", []):
            k = norm(p)
            if k in seen:
                problems.append(f"{w}: {p!r} is already in {seen[k]}")
            seen[k] = rel
            if p != p.lower():
                problems.append(f"{w}: English should be lowercase: {p!r}")
    return problems, count


def main():
    only = sys.argv[1].rstrip("/") if len(sys.argv) > 1 else None
    if only and only.startswith("tools/knowledge/"):
        only = only[len("tools/knowledge/"):]
    out = []
    qa_p, total, shown, per_area = check_qa(only)
    out += qa_p
    print(f"Q&A entries: {total} in all ({shown} checked)")
    for area, c in sorted(per_area.items()):
        print(f"  {area}: {c}")
    if only is None or only.startswith("recipes"):
        p, c = check_recipes()
        out += p
        print(f"New recipes: {c}")
    if only is None or only.startswith("trivia"):
        p, c = check_trivia()
        out += p
        print(f"New trivia questions: {c}")
    if only is None or only.startswith("twenty"):
        p, c, qn = check_twenty()
        out += p
        print(f"New 20 questions things: {c}, new questions: {qn}")
    if only is None or only.startswith("phrases"):
        p, c = check_phrases()
        out += p
        print(f"New phrases: {c}")
    if out:
        print(f"\n{len(out)} problems:")
        for x in out[:400]:
            print("  " + x)
        if len(out) > 400:
            print(f"  ... and {len(out) - 400} more")
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
