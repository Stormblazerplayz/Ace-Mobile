# @title Save and Load Game Data with JSON
# @category Files and data
# @kind Console program
# @where Save as save_game.py and run: python3 save_game.py a few times. Progress is kept in savegame.json.
# @keywords python json save, python json load, python save game progress, python json dump
# @about Saves a player's progress to a JSON file and loads it back the next time you run the program.

import json
from pathlib import Path

SAVE = Path(__file__).with_name("savegame.json")
DEFAULT = {"name": "", "level": 1, "coins": 0, "items": [], "times_played": 0}

# Load the save if there is one, otherwise start fresh
if SAVE.exists():
    with open(SAVE, encoding="utf-8") as f:
        player = json.load(f)
    print(f"Welcome back, {player['name']}!")
else:
    player = dict(DEFAULT)
    player["name"] = input("New player! What's your name? ").strip() or "Hero"

player["times_played"] += 1
player["coins"] += 25
if player["times_played"] % 3 == 0:
    player["level"] += 1
    player["items"].append(f"badge {player['level']}")
    print("LEVEL UP!")

print(json.dumps(player, indent=2))  # show it nicely

with open(SAVE, "w", encoding="utf-8") as f:
    json.dump(player, f, indent=2)
print(f"Saved to {SAVE.name}. Run me again to keep playing!")
