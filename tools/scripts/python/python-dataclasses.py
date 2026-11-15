# @title Dataclasses
# @category Basics
# @kind Console program
# @where Save as dataclass_demo.py and run: python3 dataclass_demo.py
# @keywords python dataclass, python @dataclass, python simple class, python field default
# @about Makes classes for game items with @dataclass, which writes __init__ and printing for you.

from dataclasses import dataclass, field


@dataclass
class Item:
    name: str
    price: int
    rarity: str = "common"   # a default value


@dataclass
class Inventory:
    owner: str
    items: list = field(default_factory=list)  # each inventory gets its own new list

    def add(self, item):
        self.items.append(item)

    def total_value(self):
        return sum(item.price for item in self.items)


sword = Item("Diamond Sword", 250, "rare")
apple = Item("Apple", 2)
print(sword)            # dataclasses print nicely automatically
print(apple)
print("Same item?", Item("Apple", 2) == apple)  # == compares the values

bag = Inventory("Storm")
bag.add(sword)
bag.add(apple)
bag.add(Item("Golden Egg", 1000, "legendary"))

print(f"{bag.owner} has {len(bag.items)} items worth {bag.total_value()} coins:")
for item in bag.items:
    print(f"  {item.name} ({item.rarity})")
