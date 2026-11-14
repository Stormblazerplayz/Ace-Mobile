"""Checks a replies file against spec.json: 20 different replies per key, right slots.

Usage: python3 check_replies.py FILE.json [FILE2.json ...]   (checks only the keys in the files)
       python3 check_replies.py --all FILE.json ...          (every key in spec.json must be covered)
"""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = json.loads((HERE / "spec.json").read_text())
args = sys.argv[1:]
want_all = "--all" in args
files = [a for a in args if a != "--all"]
merged = {}
for f in files:
    for k, v in json.loads(pathlib.Path(f).read_text()).items():
        if k in merged:
            sys.exit(f"{k} is in more than one file")
        merged[k] = v
errors = []
for key, variants in merged.items():
    if key not in spec:
        errors.append(f"{key}: not in spec.json")
        continue
    s = spec[key]
    allowed = set(s["req"]) | set(s["opt"])
    if not isinstance(variants, list) or len(variants) != 20:
        errors.append(f"{key}: needs exactly 20 replies, has {len(variants) if isinstance(variants, list) else 'not a list'}")
        continue
    norm = [re.sub(r"[^a-z0-9{} ]", "", v.lower()).strip() for v in variants]
    if len(set(norm)) != 20:
        errors.append(f"{key}: some replies are the same")
    for v in variants:
        if not v.strip() or v != v.strip():
            errors.append(f"{key}: blank or padded reply {v!r}")
        slots = re.findall(r"\{(\w+)\}", v)
        for sl in slots:
            if sl not in allowed:
                errors.append(f"{key}: unknown slot {{{sl}}} in {v!r}")
        for r in s["req"]:
            if "{" + r + "}" not in v:
                errors.append(f"{key}: missing {{{r}}} in {v!r}")
        if re.search(r"[{}]", re.sub(r"\{\w+\}", "", v)):
            errors.append(f"{key}: stray brace in {v!r}")
        if "—" in v or " -- " in v:
            errors.append(f"{key}: no em dashes please: {v!r}")
if want_all:
    for key in spec:
        if key not in merged:
            errors.append(f"{key}: missing")
if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"OK: {len(merged)} keys, {sum(len(v) for v in merged.values())} replies")
