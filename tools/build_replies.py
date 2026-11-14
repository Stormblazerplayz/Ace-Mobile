"""Builds Ace/Resources/replies.json: 20 ways to say every canned reply Ace has.

Run from the repo root:  python3 tools/build_replies.py
The wordings live in tools/replies/part_*.json and are checked against
tools/replies/spec.json (20 different wordings per reply, same facts and slots).
"""
import glob
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
parts = sorted(glob.glob(os.path.join(HERE, "replies", "part_*.json")))
check = subprocess.run([sys.executable, os.path.join(HERE, "replies", "check_replies.py"), "--all", *parts])
if check.returncode != 0:
    sys.exit("Fix the replies above first.")
spec = json.load(open(os.path.join(HERE, "replies", "spec.json")))
merged = {}
for p in parts:
    merged.update(json.load(open(p)))
out = {"format": "ace-replies/1", "count": len(merged),
       "replies": {k: {"required": spec[k]["req"], "say": merged[k]} for k in sorted(merged)}}
path = os.path.join(HERE, "..", "Ace", "Resources", "replies.json")
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
    f.write("\n")
print(f"wrote {len(merged)} replies x 20 to {os.path.normpath(path)}")
