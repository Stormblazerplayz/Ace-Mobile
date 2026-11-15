# @title Shelve: A Dictionary That Saves Itself
# @category Files and data
# @kind Console program
# @where Save as shelve_demo.py and run: python3 shelve_demo.py a few times. Data stays in files starting with "vault".
# @keywords python shelve, python persistent dictionary, python key value store, python simple database
# @about Uses shelve, which works like a normal dictionary but remembers everything between runs.

import shelve
from pathlib import Path

path = str(Path(__file__).with_name("vault"))

with shelve.open(path) as vault:      # opens (or makes) the storage files
    vault["runs"] = vault.get("runs", 0) + 1
    print(f"This program has run {vault['runs']} times.")

    if "friends" not in vault:
        vault["friends"] = []
    name = input("Add a friend's name (or press Enter): ").strip()
    if name:
        friends = vault["friends"]     # get the list, change it, then put it back
        friends.append(name)
        vault["friends"] = friends
    print("Friends saved so far:", ", ".join(vault["friends"]) or "none yet")

    print("All keys in the vault:", list(vault.keys()))
# Leaving the "with" block saves and closes everything
