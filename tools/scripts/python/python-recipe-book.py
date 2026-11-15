# @title Recipe Book
# @category Files and data
# @kind Console program
# @where Save as recipes.py and run: python3 recipes.py. Recipes are saved in recipes.json.
# @keywords python recipe book, python nested json, python scale recipe, python search by ingredient
# @about Saves recipes with ingredients and steps, finds recipes by ingredient and scales amounts for more people.

import json
from pathlib import Path

FILE = Path(__file__).with_name("recipes.json")
book = json.loads(FILE.read_text()) if FILE.exists() else {
    "Pancakes": {"serves": 2, "ingredients": {"flour (cups)": 1, "milk (cups)": 1, "egg": 1},
                 "steps": ["Mix everything", "Cook on a hot pan", "Flip when bubbly"]},
}


def show(name, people=None):
    recipe = book[name]
    scale = (people or recipe["serves"]) / recipe["serves"]
    print(f"\n== {name} (serves {people or recipe['serves']}) ==")
    for item, amount in recipe["ingredients"].items():
        print(f"  {amount * scale:g} {item}")
    for number, step in enumerate(recipe["steps"], start=1):
        print(f"  {number}. {step}")


while True:
    print("\nRecipes:", ", ".join(sorted(book)) or "none")
    cmd = input("(v)iew, (f)ind by ingredient, (a)dd or (q)uit? ").strip().lower()
    if cmd == "q":
        break
    if cmd == "v":
        name = input("Recipe name: ").strip()
        if name in book:
            people = input("For how many people? (Enter for normal) ").strip()
            show(name, int(people) if people.isdigit() and int(people) > 0 else None)
    elif cmd == "f":
        word = input("Ingredient: ").strip().lower()
        hits = [n for n, r in book.items() if any(word in i.lower() for i in r["ingredients"])]
        print("Found:", ", ".join(hits) or "nothing")
    elif cmd == "a":
        name = input("Recipe name: ").strip()
        serves = input("Serves how many? ").strip()
        ingredients = {}
        while (item := input("Ingredient (Enter to stop): ").strip()):
            amount = input(f"  Amount of {item}: ").strip()
            ingredients[item] = float(amount) if amount.replace(".", "", 1).isdigit() else 1
        steps = [s for s in iter(lambda: input("Step (Enter to stop): ").strip(), "")]
        if name:
            book[name] = {"serves": int(serves) if serves.isdigit() else 1, "ingredients": ingredients, "steps": steps}
            FILE.write_text(json.dumps(book, indent=2))
            print("Saved!")
