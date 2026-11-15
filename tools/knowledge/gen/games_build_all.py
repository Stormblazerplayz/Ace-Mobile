"""Runs every games_*.py generator for Ace's knowledge pack, in order.

Generators drop any wording that clashes with the older bank or another file, so run this again after
editing the hand-written files in data/games. Run from the repo root:
    python3 tools/knowledge/gen/games_build_all.py
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ORDER = ["games_mc_recipes.py", "games_mc_mobs.py", "games_mc_data.py", "games_pokemon.py"]

for name in ORDER:
    print(f"== {name}")
    subprocess.run([sys.executable, os.path.join(HERE, name)], check=True)
