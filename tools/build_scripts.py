"""Builds Ace/Resources/scripts.json: Ace's offline library of Lua (Roblox) and C++ scripts.

Run from the repo root:   python3 tools/build_scripts.py
Check only (for CI):      python3 tools/build_scripts.py --check

Every script lives in tools/scripts/lua/*.lua, tools/scripts/cpp/*.cpp|*.ino, tools/scripts/python/*.py or
tools/scripts/swift/*.swift and starts with a header (# for Python, // for C++ and Swift):
    -- @title Kill brick            (or // @title for C++)
    -- @category Obstacles
    -- @kind Script
    -- @where Put this Script inside the Part you want to be deadly.
    -- @keywords kill brick, kill part, death brick
    -- @about Touching the part resets the player.
then a blank line, then the code.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "Ace", "Resources", "scripts.json")
TAGS = ["title", "category", "kind", "where", "keywords", "about"]
CATEGORIES = {
    "Lua": {"Obstacles", "Moving parts", "Players", "Pickups and money", "Doors and buttons", "World and effects",
            "Tools and combat", "GUI", "Game rounds", "Saving data", "NPCs and AI", "Vehicles", "Sound",
            "Chat and admin", "Teams", "Camera", "Leaderboards"},
    "C++": {"Arduino", "Games", "Basics", "Unreal Engine", "Data structures", "Math and school"},
    "Python": {"Basics", "Games", "Tools", "Math and school", "Files and data", "Drawing", "Raspberry Pi"},
    "Swift": {"Swift basics", "SwiftUI basics", "SwiftUI apps", "Games"},
}
KINDS = {"Lua": {"Script", "LocalScript", "ModuleScript"}, "C++": {"Arduino sketch", "Console program", "Unreal C++ class"},
         "Python": {"Console program", "Turtle program", "Module"}, "Swift": {"SwiftUI view", "Swift program"}}
PREFIX = {"Lua": "--", "C++": "//", "Python": "#", "Swift": "//"}


def read(path, language):
    prefix = PREFIX[language]
    lines = open(path, encoding="utf-8").read().replace("\r\n", "\n").split("\n")
    meta, errors = {}, []
    for i, tag in enumerate(TAGS):
        m = re.match(r"^" + re.escape(prefix) + r" @(\w+) (.+)$", lines[i] if i < len(lines) else "")
        if not m or m.group(1) != tag:
            errors.append(f"line {i + 1} should be '{prefix} @{tag} ...'")
            continue
        meta[tag] = m.group(2).strip()
    if len(lines) <= len(TAGS) or lines[len(TAGS)].strip() != "":
        errors.append("needs a blank line after the header")
    code = "\n".join(lines[len(TAGS) + 1:]).strip("\n") + "\n"
    if errors:
        return None, errors
    if meta["category"] not in CATEGORIES[language]:
        errors.append(f"unknown category {meta['category']!r}")
    if meta["kind"] not in KINDS[language]:
        errors.append(f"unknown kind {meta['kind']!r}")
    keywords = [k.strip().lower() for k in meta["keywords"].split(",") if k.strip()]
    if not 3 <= len(keywords) <= 10:
        errors.append(f"needs 3 to 10 keywords, has {len(keywords)}")
    if len(code.strip()) < 40:
        errors.append("the code is missing")
    if "—" in code or "—" in meta["about"] or "—" in meta["where"]:
        errors.append("no em dashes please")
    sid = os.path.splitext(os.path.basename(path))[0]
    return {
        "id": sid,
        "title": meta["title"],
        "language": language,
        "category": meta["category"],
        "kind": meta["kind"],
        "where": meta["where"],
        "keywords": keywords,
        "about": meta["about"],
        "code": code,
    }, errors


def build():
    scripts, problems = [], []
    files = [(p, "Lua") for p in sorted(glob.glob(os.path.join(HERE, "scripts", "lua", "*.lua")))]
    files += [(p, "C++") for p in sorted(glob.glob(os.path.join(HERE, "scripts", "cpp", "*.cpp")) + glob.glob(os.path.join(HERE, "scripts", "cpp", "*.ino")))]
    files += [(p, "Python") for p in sorted(glob.glob(os.path.join(HERE, "scripts", "python", "*.py")))]
    files += [(p, "Swift") for p in sorted(glob.glob(os.path.join(HERE, "scripts", "swift", "*.swift")))]
    for path, language in files:
        s, errors = read(path, language)
        rel = os.path.relpath(path, ROOT)
        problems += [f"{rel}: {e}" for e in errors]
        if s:
            scripts.append(s)
    seen_ids, seen_kw = {}, {}
    for s in scripts:
        if s["id"] in seen_ids:
            problems.append(f"two scripts have the id {s['id']}")
        seen_ids[s["id"]] = True
        for k in s["keywords"]:
            key = (s["language"], k)
            if key in seen_kw:
                problems.append(f"keyword {k!r} is in both {seen_kw[key]} and {s['id']}")
            seen_kw[key] = s["id"]
    lua = sum(1 for s in scripts if s["language"] == "Lua")
    cpp = len(scripts) - lua
    if lua < 25:
        problems.append(f"only {lua} Lua scripts (need at least 25)")
    if cpp < 20:
        problems.append(f"only {cpp} C++ scripts (need at least 20)")
    order = {"Lua": 0, "C++": 1, "Python": 2, "Swift": 3}
    scripts.sort(key=lambda s: (order[s["language"]], s["category"], s["title"].lower()))
    return {"format": "ace-scripts/1", "count": len(scripts), "scripts": scripts}, problems


def main():
    data, problems = build()
    if problems:
        print("\n".join(problems))
        sys.exit("Fix the scripts above first.")
    text = json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    if "--check" in sys.argv:
        old = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if old != text:
            sys.exit("Ace/Resources/scripts.json is out of date. Run: python3 tools/build_scripts.py")
        print(f"OK: {data['count']} scripts, scripts.json is up to date")
        return
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {data['count']} scripts to {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
