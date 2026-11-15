#!/usr/bin/env python3
"""Plays Ace's 20 questions against every thing it knows, the same way the app and its test do.

Run from the repo root:
    python3 tools/knowledge/twenty/simulate.py          # win rate and the things it missed
    python3 tools/knowledge/twenty/simulate.py -v       # also how each missed game went

It merges tools/knowledge/base/twenty_questions.json with tools/knowledge/twenty/new.json (new questions and
things, added after the built-in ones) and existing_answers.json (the built-in things' answers to the new
questions), then copies the Swift code in Ace/Brain/Games.swift (TwentyQuestions.weights, nextQuestion,
nextMove) and the way AceTests/GamesTests.swift answers:
  - a value >= 0.75 says "yes" (1), <= 0.25 says "no" (0), anything else says "maybe" (0.5)
  - a guess of the right name wins; a wrong guess is ruled out and still uses one of the 20 moves
It also checks that every thing answers every question with 0, 0.5 or 1.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
MAX_QUESTIONS = 20


def load():
    # The built-in data before the knowledge pack is merged in (build_knowledge.py writes the merged copy to
    # Ace/Resources). Falls back to Ace/Resources when there is no base copy.
    base = os.path.join(HERE, "..", "base", "twenty_questions.json")
    if not os.path.exists(base):
        base = os.path.join(ROOT, "Ace", "Resources", "twenty_questions.json")
    core = json.load(open(base, encoding="utf-8"))
    new = json.load(open(os.path.join(HERE, "new.json"), encoding="utf-8"))
    extra_path = os.path.join(HERE, "existing_answers.json")
    extra = json.load(open(extra_path, encoding="utf-8")) if os.path.exists(extra_path) else {}
    questions = core["questions"] + new.get("questions", [])
    qids = [q["id"] for q in questions]
    problems = []
    if len(set(qids)) != len(qids):
        problems.append("a question id is used twice")
    new_ids = {q["id"] for q in new.get("questions", [])}
    things = []
    core_names = {t["name"] for t in core["things"]}
    for name in extra:
        if name not in core_names:
            problems.append(f"existing_answers.json: {name!r} isn't a built-in thing")
    for t in core["things"]:
        answers = dict(t["answers"])
        more = extra.get(t["name"], {})
        missing = new_ids - set(more)
        if missing:
            problems.append(f"existing_answers.json: {t['name']} has no answer for {sorted(missing)[:6]}")
        for k in more:
            if k not in new_ids:
                problems.append(f"existing_answers.json: {t['name']} answers {k!r}, which isn't a new question")
        answers.update(more)
        things.append({"name": t["name"], "answers": answers})
    things += new.get("things", [])
    names = [t["name"].lower() for t in things]
    if len(set(names)) != len(names):
        problems.append("a thing name is used twice")
    for t in things:
        a = t["answers"]
        if set(a) != set(qids):
            problems.append(f"{t['name']}: answers don't match the questions "
                            f"(missing {sorted(set(qids) - set(a))[:5]}, extra {sorted(set(a) - set(qids))[:5]})")
        for k, v in a.items():
            if v not in (0, 0.5, 1):
                problems.append(f"{t['name']}: {k}={v}")
    return questions, things, problems


def weights(things, answers, wrong):
    out = []
    for t in things:
        if t["name"].lower() in wrong:
            out.append(0.0)
            continue
        penalty = 0.0
        for q, v in answers:
            if v is None:
                continue
            penalty += abs(v - t["answers"].get(q, 0.5))
        out.append(math.exp(-4 * penalty))
    return out


def next_question(questions, things, w, asked):
    total = sum(w)
    if not total > 0:
        return None
    best = None
    for q in questions:
        if q["id"] in asked:
            continue
        qid = q["id"]
        mean = 0.0
        for t, x in zip(things, w):
            mean += x * t["answers"].get(qid, 0.5)
        mean /= total
        spread = 0.0
        for t, x in zip(things, w):
            d = t["answers"].get(qid, 0.5) - mean
            spread += x * d * d
        spread /= total
        if spread > 1e-6 and (best is None or spread > best[0]):
            best = (spread, q)
    return best[1] if best else None


def next_move(questions, things, answers, wrong, used):
    if used >= MAX_QUESTIONS:
        return ("giveUp", None)
    w = weights(things, answers, wrong)
    total = sum(w)
    if not total > 0:
        return ("giveUp", None)
    top = max(range(len(w)), key=lambda i: w[i])  # first of the biggest, like Swift's max(by:)
    sure = w[top] / total
    q = next_question(questions, things, w, {a[0] for a in answers})
    if (sure > 0.6 and len(answers) >= 3) or q is None or used >= MAX_QUESTIONS - 1:
        return ("guess", things[top]["name"])
    return ("ask", q)


def play(questions, things, secret):
    answers, wrong, used, log = [], set(), 0, []
    while True:
        kind, x = next_move(questions, things, answers, wrong, used)
        if kind == "giveUp":
            return False, used, log
        used += 1
        if kind == "ask":
            v = secret["answers"].get(x["id"], 0.5)
            said = 1 if v >= 0.75 else 0 if v <= 0.25 else 0.5
            answers.append((x["id"], said))
            log.append(f"{x['id']}={said}")
        else:
            log.append(f"GUESS {x}")
            if x == secret["name"]:
                return True, used, log
            wrong.add(x.lower())


def main():
    verbose = "-v" in sys.argv
    questions, things, problems = load()
    if problems:
        print(f"{len(problems)} data problems:")
        for p in problems[:50]:
            print("  " + p)
    wins, missed, moves = 0, [], 0
    for secret in things:
        won, used, log = play(questions, things, secret)
        if won:
            wins += 1
            moves += used
        else:
            missed.append((secret["name"], log))
    n = len(things)
    print(f"{len(questions)} questions, {n} things")
    print(f"Won {wins}/{n} ({100.0 * wins / n:.1f}%), {moves / max(wins, 1):.1f} moves per win on average")
    if missed:
        print("Missed: " + ", ".join(m[0] for m in missed))
        if verbose:
            for name, log in missed:
                print(f"  {name}: {' '.join(log)}")
    sys.exit(1 if problems or wins < 0.97 * n else 0)


if __name__ == "__main__":
    main()
