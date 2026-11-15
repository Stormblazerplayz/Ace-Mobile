#!/usr/bin/env python3
"""Tidies data/science/*.txt so it doesn't clash with other areas.

Drops any wording in a science file that is already used (or asks the same thing with the
same important words) in Ace's older bank or in another area's files. An entry left with
fewer than 2 wordings is dropped and listed, so it can be reworded by hand.
Clashes between two science files are only reported, not fixed.

Run from the repo root:  python3 tools/knowledge/gen/science_clean.py
"""
import glob
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
KN = os.path.normpath(os.path.join(HERE, ".."))
SCI = os.path.join(KN, "data", "science")

spec = importlib.util.spec_from_file_location("check_data", os.path.join(KN, "check_data.py"))
cd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cd)


def others():
    words, keys = set(cd.core_wordings()), set()
    for w in list(words):
        ks = cd.keyset(w)
        if len(ks) >= 2:
            keys.add(ks)
    for path in glob.glob(os.path.join(KN, "data", "**", "*.txt"), recursive=True):
        if os.path.normpath(os.path.dirname(path)).startswith(SCI):
            continue
        entries, _ = cd.parse_txt(path)
        for _, _, qs, _ in entries:
            for q in qs:
                words.add(cd.norm(q))
                ks = cd.keyset(q)
                if len(ks) >= 2:
                    keys.add(ks)
    return words, keys


def main():
    words, keys = others()
    for path in sorted(glob.glob(os.path.join(SCI, "*.txt"))):
        out, dropped, removed = [], [], 0
        for raw in open(path, encoding="utf-8").read().splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=>" not in line:
                out.append(raw)
                continue
            left, right = line.split("=>", 1)
            qs = [q.strip() for q in left.split("|") if q.strip()]
            keep = [q for q in qs if cd.norm(q) not in words and cd.keyset(q) not in keys]
            removed += len(qs) - len(keep)
            if len(keep) < 2:
                dropped.append(line[:110])
                continue
            out.append(" | ".join(keep) + " =>" + right)
        open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
        if removed or dropped:
            print(f"{os.path.basename(path)}: removed {removed} wordings, dropped {len(dropped)} entries")
            for d in dropped:
                print("   dropped:", d)


if __name__ == "__main__":
    main()
