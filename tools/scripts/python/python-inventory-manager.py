# @title Shop Inventory Manager
# @category Files and data
# @kind Console program
# @where Save as inventory.py and run: python3 inventory.py. Stock is saved in inventory.json.
# @keywords python inventory system, python stock manager, python json database, python store app
# @about Keeps track of products, prices and stock for a small shop, warns about low stock and saves everything.

import json
from pathlib import Path

FILE = Path(__file__).with_name("inventory.json")
stock = json.loads(FILE.read_text()) if FILE.exists() else {
    "Dragon keychain": {"price": 4.0, "qty": 12},
    "Phone stand": {"price": 8.5, "qty": 3},
}
LOW = 5


def show():
    print(f"\n{'Product':<20}{'Price':>8}{'Qty':>6}")
    for name, item in sorted(stock.items()):
        warn = "  <- low!" if item["qty"] < LOW else ""
        print(f"{name:<20}{item['price']:>8.2f}{item['qty']:>6}{warn}")
    value = sum(i["price"] * i["qty"] for i in stock.values())
    print(f"Total stock value: ${value:.2f}")


while True:
    show()
    cmd = input("\n(a)dd product, (s)ell, (r)estock or (q)uit? ").strip().lower()
    if cmd == "q":
        break
    name = input("Product name: ").strip()
    if cmd == "a" and name:
        try:
            stock[name] = {"price": float(input("Price: ")), "qty": int(input("Quantity: "))}
        except ValueError:
            print("Price and quantity must be numbers.")
    elif cmd in ("s", "r") and name in stock:
        amount = input("How many? ").strip()
        if amount.isdigit():
            change = int(amount) if cmd == "r" else -int(amount)
            if stock[name]["qty"] + change < 0:
                print("Not enough in stock!")
            else:
                stock[name]["qty"] += change
                if cmd == "s":
                    print(f"Sold for ${int(amount) * stock[name]['price']:.2f}")
    else:
        print("Unknown product or command.")
    FILE.write_text(json.dumps(stock, indent=2))
