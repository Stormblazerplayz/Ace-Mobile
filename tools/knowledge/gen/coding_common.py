"""Shared helpers for the coding_*.py generators: the wordings already used elsewhere in the knowledge pack,
so a generator can skip any wording the checker would reject as a duplicate."""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(KNOW))
sys.path.insert(0, KNOW)
from check_data import keyset, norm, parse_txt  # noqa: E402


def existing(own_output):
    """Returns (normalized wordings, keysets) used in qa_bank.json and every data file except own_output."""
    words, keys = set(), set()
    bank = os.path.join(ROOT, "Ace", "Resources", "qa_bank.json")
    if os.path.exists(bank):
        for e in json.load(open(bank, encoding="utf-8"))["entries"]:
            for q in e["q"]:
                words.add(norm(q))
                if len(keyset(q)) >= 2:
                    keys.add(keyset(q))
    for path in glob.glob(os.path.join(KNOW, "data", "**", "*.txt"), recursive=True):
        if os.path.abspath(path) == os.path.abspath(own_output):
            continue
        entries, _ = parse_txt(path)
        for _n, _tag, qs, _ans in entries:
            for q in qs:
                words.add(norm(q))
                if len(keyset(q)) >= 2:
                    keys.add(keyset(q))
    return words, keys
