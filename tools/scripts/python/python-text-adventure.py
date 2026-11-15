# @title Text Adventure: The Lost Temple
# @category Games
# @kind Console program
# @where Save as adventure.py and run: python3 adventure.py
# @keywords python text adventure, python rooms dictionary, python inventory game, python explore game
# @about Explore a temple room by room, collect items and find the treasure using typed commands.

# Each room has a description, exits to other rooms and maybe an item.
ROOMS = {
    "entrance": {"text": "You stand at the temple entrance. Vines cover the walls.",
                 "exits": {"north": "hall"}, "item": "torch"},
    "hall": {"text": "A long dark hall. Statues stare at you.",
             "exits": {"south": "entrance", "east": "library", "north": "vault"}, "item": None},
    "library": {"text": "Dusty books everywhere. Something glints on a shelf.",
                "exits": {"west": "hall"}, "item": "golden key"},
    "vault": {"text": "A huge locked door with a keyhole shaped like a sun.",
              "exits": {"south": "hall"}, "item": None},
}

room = "entrance"
inventory = []
print("THE LOST TEMPLE. Commands: go <direction>, take, inventory, quit")

while True:
    info = ROOMS[room]
    print("\n" + info["text"])
    if info["item"]:
        print(f"You see a {info['item']} here.")
    print("Exits:", ", ".join(info["exits"]))

    if room == "vault" and "golden key" in inventory:
        if "torch" in inventory:
            print("The key fits! You light your torch and find the TREASURE. You win!")
        else:
            print("The key fits, but it's too dark inside to find anything. Bring a light!")
            room = "hall"
            continue
        break

    words = input("> ").strip().lower().split()
    if not words:
        continue
    if words[0] == "quit":
        print("You run away from the temple. Maybe next time!")
        break
    elif words[0] == "go" and len(words) > 1:
        if words[1] in info["exits"]:
            room = info["exits"][words[1]]
        else:
            print("You can't go that way.")
    elif words[0] == "take":
        if info["item"]:
            inventory.append(info["item"])
            print(f"You took the {info['item']}.")
            info["item"] = None
        else:
            print("There's nothing to take.")
    elif words[0] in ("inventory", "i"):
        print("You carry:", ", ".join(inventory) or "nothing")
    else:
        print("I don't understand.")
