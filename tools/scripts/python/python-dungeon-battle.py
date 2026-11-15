# @title Dungeon Battle RPG
# @category Games
# @kind Console program
# @where Save as dungeon.py and run: python3 dungeon.py
# @keywords python rpg battle, python turn based combat, python dungeon game, python monster fight
# @about Fight your way through three monsters with attacks, healing potions and lucky critical hits.

import random


class Fighter:
    def __init__(self, name, hp, attack):
        self.name = name
        self.hp = hp
        self.max_hp = hp
        self.attack = attack

    def alive(self):
        return self.hp > 0

    def hit(self, other):
        damage = random.randint(self.attack // 2, self.attack)
        if random.random() < 0.15:  # 15% chance of a critical hit
            damage *= 2
            print("  CRITICAL HIT!")
        other.hp = max(0, other.hp - damage)
        print(f"  {self.name} hits {other.name} for {damage}. {other.name} has {other.hp} HP left.")


hero = Fighter("Hero", 60, 14)
potions = 3
monsters = [Fighter("Slime", 20, 6), Fighter("Goblin", 30, 9), Fighter("Dragon", 55, 13)]

for monster in monsters:
    print(f"\nA wild {monster.name} appears! ({monster.hp} HP)")
    while monster.alive() and hero.alive():
        choice = input(f"[HP {hero.hp}/{hero.max_hp}, potions {potions}] (a)ttack or (p)otion? ").strip().lower()
        if choice == "p":
            if potions == 0:
                print("  You're out of potions!")
                continue
            potions -= 1
            hero.hp = min(hero.max_hp, hero.hp + 25)
            print(f"  You drink a potion. HP is now {hero.hp}.")
        else:
            hero.hit(monster)
        if monster.alive():
            monster.hit(hero)
    if not hero.alive():
        print(f"\nThe {monster.name} defeated you. Game over!")
        break
    print(f"You defeated the {monster.name}!")
    hero.attack += 2  # level up!
else:
    print("\nYou cleared the dungeon! You are a legend!")
