# @title Random Team Maker
# @category Tools
# @kind Console program
# @where Save as teams.py and run: python3 teams.py
# @keywords python team maker, python split into groups, python random teams, python fair groups
# @about Splits a list of names into fair random teams of nearly equal size.

import random

names = [n.strip() for n in input("Names, separated by commas: ").split(",") if n.strip()]
if len(names) < 2:
    names = ["Storm", "Doodle", "Nova", "Ace", "Blaze", "Rex", "Kai", "Luna", "Max"]
    print("Using example names.")

text = input("How many teams? ").strip()
team_count = int(text) if text.isdigit() and 1 <= int(text) <= len(names) else 2

random.shuffle(names)
teams = [[] for _ in range(team_count)]
for i, name in enumerate(names):
    teams[i % team_count].append(name)  # deal names out like cards

TEAM_NAMES = ["Lightning", "Thunder", "Blizzard", "Tornado", "Volcano", "Tsunami", "Meteor", "Comet"]
for i, team in enumerate(teams):
    label = TEAM_NAMES[i] if i < len(TEAM_NAMES) else f"Team {i + 1}"
    print(f"\n{label} ({len(team)} players):")
    for name in team:
        print("  -", name)
