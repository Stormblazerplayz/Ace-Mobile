#!/usr/bin/env python3
"""Builds Ace's big knowledge pack and the bigger game, recipe and phrase files.

Run from the repo root:   python3 tools/knowledge/build_knowledge.py
Check only (for CI):      python3 tools/knowledge/build_knowledge.py --check
Needs: pip install regex

Writes
  Ace/Resources/knowledge.acekb   the Q&A pack (tools/knowledge/data/**/*.txt), compressed
  Ace/Resources/recipes.json      tools/knowledge/base/recipes.json + tools/knowledge/recipes/*.json
  Ace/Resources/trivia.json       tools/knowledge/base/trivia.json + tools/knowledge/trivia/*.json
  Ace/Resources/twenty_questions.json   base + tools/knowledge/twenty/*.json
  Ace/Resources/phrasebook.json   base + tools/knowledge/phrases/*.json

The pack ("ace-kb/1") is UTF-8 text compressed with raw DEFLATE (what Apple's
NSData.decompressed(using: .zlib) reads). Lines:
  ace-kb/1
  counts <entries> <wordings> <tokens> <words>
  <tokens lines>      one stemmed word per line; its line number (from 0) is its token id
  <entries lines>     id \\t tag \\t answer \\x1f answer...
  <wordings lines>    entry index \\t normalized wording \\t keyword token ids \\t all token ids (ids split by spaces)
  <words lines>       plain word \\t how many wordings use it (for typo fixes)
Wordings are split and stemmed here with tools/knowledge/textkit.py (a copy of TextKit.swift), so the
iPad only has to read numbers. AceTests/KnowledgePackTests.swift checks that the two still agree.
"""
import glob
import json
import os
import re
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
RES = os.path.join(ROOT, "Ace", "Resources")
sys.path.insert(0, HERE)

import textkit as T  # noqa: E402
from check_data import parse_txt, check_entry  # noqa: E402

PACK = os.path.join(RES, "knowledge.acekb")


def slug(text):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:60] or "x"


def build_pack():
    core = json.load(open(os.path.join(RES, "qa_bank.json"), encoding="utf-8"))["entries"]
    seen_wording = {}
    seen_keys = {}
    for e in core:
        for q in e["q"]:
            n = T.normalize(q)
            seen_wording[n] = "core"
            ks = frozenset(T.keywords(n))
            if len(ks) >= 2:
                seen_keys.setdefault(ks, "core")

    # The test questions in AceTests must stay never-seen, so none of them goes in word for word.
    for case_file in glob.glob(os.path.join(ROOT, "AceTests", "*_cases.json")):
        for c in json.load(open(case_file, encoding="utf-8"))["cases"]:
            seen_wording.setdefault(T.normalize(c["prompt"]), "a test question")

    files = sorted(glob.glob(os.path.join(HERE, "data", "**", "*.txt"), recursive=True))
    entries, dropped, bad = [], [], []
    ids = {e["id"] for e in core}
    for path in files:
        rel = os.path.relpath(path, HERE)
        parsed, problems = parse_txt(path)
        bad += [f"{rel}:{p}" for p in problems]
        for n, tag, qs, ans in parsed:
            p = check_entry(n, tag, qs, ans)
            if p:
                bad += [f"{rel}:{x}" for x in p]
                continue
            norms = []
            for q in qs:
                k = T.normalize(q)
                if not k or k in seen_wording or k in norms:
                    continue
                norms.append(k)
            # An entry that asks the same thing as one we already have (same important words) is left out.
            clash = None
            for k in norms:
                ks = frozenset(T.keywords(k))
                if len(ks) >= 2 and ks in seen_keys:
                    clash = seen_keys[ks]
                    break
            if not norms or clash:
                dropped.append(f"{rel}:{n} ({'repeat of ' + clash if clash else 'every wording is already used'})")
                continue
            for k in norms:
                seen_wording[k] = f"{rel}:{n}"
                ks = frozenset(T.keywords(k))
                if len(ks) >= 2:
                    seen_keys.setdefault(ks, f"{rel}:{n}")
            base = f"{tag}.{slug(norms[0])}"
            eid, i = base, 2
            while eid in ids:
                eid, i = f"{base}-{i}", i + 1
            ids.add(eid)
            entries.append((eid, tag, norms, ans))

    tokens, token_id = [], {}

    def tid(t):
        if t not in token_id:
            token_id[t] = len(tokens)
            tokens.append(t)
        return token_id[t]

    wordings, word_count = [], {}
    for ei, (eid, tag, norms, ans) in enumerate(entries):
        for k in norms:
            keys = sorted({tid(t) for t in T.keywords(k)})
            all_ = sorted({tid(T.stem(w)) for w in T.words(k)})
            wordings.append((ei, k, keys, all_))
            for w in k.split(" "):
                if w:
                    word_count[w] = word_count.get(w, 0) + 1

    lines = ["ace-kb/1", f"counts {len(entries)} {len(wordings)} {len(tokens)} {len(word_count)}"]
    for t in tokens:
        assert "\t" not in t and "\n" not in t
        lines.append(t)
    for eid, tag, norms, ans in entries:
        for a in ans:
            assert "\t" not in a and "\n" not in a and "\x1f" not in a
        lines.append(f"{eid}\t{tag}\t" + "\x1f".join(ans))
    for ei, k, keys, all_ in wordings:
        lines.append(f"{ei}\t{k}\t{' '.join(map(str, keys))}\t{' '.join(map(str, all_))}")
    for w in sorted(word_count):
        lines.append(f"{w}\t{word_count[w]}")
    text = ("\n".join(lines) + "\n").encode("utf-8")
    c = zlib.compressobj(9, zlib.DEFLATED, -15)
    packed = c.compress(text) + c.flush()
    stats = {"entries": len(entries), "wordings": len(wordings), "tokens": len(tokens), "words": len(word_count),
             "raw_bytes": len(text), "packed_bytes": len(packed)}
    return packed, stats, dropped, bad


def merged(base_name, folder, key, extra_fn=None):
    base = json.load(open(os.path.join(HERE, "base", base_name), encoding="utf-8"))
    for path in sorted(glob.glob(os.path.join(HERE, folder, "*.json"))):
        data = json.load(open(path, encoding="utf-8"))
        items = data.get(key, []) if isinstance(data, dict) else data
        base[key] = base[key] + items
    if extra_fn:
        extra_fn(base)
    if "count" in base:
        base["count"] = len(base[key])
    return base


def twenty_extra(base):
    for path in sorted(glob.glob(os.path.join(HERE, "twenty", "*.json"))):
        name = os.path.basename(path)
        data = json.load(open(path, encoding="utf-8"))
        if name == "existing_answers.json":
            by_name = {t["name"]: t for t in base["things"]}
            for thing, answers in data.items():
                if thing in by_name:
                    by_name[thing]["answers"].update(answers)
            continue
        base["questions"] += data.get("questions", [])
        base["things"] += data.get("things", [])


def outputs():
    packed, stats, dropped, bad = build_pack()
    out = {PACK: packed}

    def dump(obj):
        return (json.dumps(obj, ensure_ascii=False, indent=1) + "\n").encode("utf-8")

    out[os.path.join(RES, "recipes.json")] = dump(merged("recipes.json", "recipes", "recipes"))
    out[os.path.join(RES, "trivia.json")] = dump(merged("trivia.json", "trivia", "questions"))
    tq = json.load(open(os.path.join(HERE, "base", "twenty_questions.json"), encoding="utf-8"))
    twenty_extra(tq)
    out[os.path.join(RES, "twenty_questions.json")] = dump(tq)
    out[os.path.join(RES, "phrasebook.json")] = dump(merged("phrasebook.json", "phrases", "entries"))
    return out, stats, dropped, bad


def main():
    out, stats, dropped, bad = outputs()
    if bad:
        print(f"{len(bad)} entries skipped because check_data.py finds problems in them, for example:")
        for b in bad[:20]:
            print("  " + b)
    if "--verbose" in sys.argv:
        for d in dropped:
            print("dropped " + d)
    print(f"pack: {stats['entries']} entries, {stats['wordings']} wordings, {stats['tokens']} tokens, "
          f"{stats['raw_bytes'] / 1e6:.1f} MB raw, {stats['packed_bytes'] / 1e6:.1f} MB packed "
          f"({len(dropped)} repeats left out)")
    if "--check" in sys.argv:
        stale = [os.path.relpath(p, ROOT) for p, data in out.items()
                 if not os.path.exists(p) or open(p, "rb").read() != data]
        if stale:
            sys.exit("Out of date, run python3 tools/knowledge/build_knowledge.py: " + ", ".join(stale))
        print("OK: the knowledge pack and game files are up to date")
        return
    for p, data in out.items():
        with open(p, "wb") as f:
            f.write(data)
        print(f"wrote {os.path.relpath(p, ROOT)} ({len(data) / 1e6:.2f} MB)")


if __name__ == "__main__":
    main()
