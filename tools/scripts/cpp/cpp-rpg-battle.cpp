// @title Turn-Based RPG Battle
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o rpg && ./rpg
// @keywords rpg battle, turn based combat, hit points and mana, attack heal fireball, boss fight c++
// @about Fight a row of monsters in turn-based battles using attacks, fireballs and healing potions, gaining levels as you win.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>

std::mt19937 rng(std::random_device{}());
int roll(int lo, int hi) { return std::uniform_int_distribution<int>(lo, hi)(rng); }

struct Fighter {
  std::string name;
  int hp, maxHp, attack;
};

int main() {
  Fighter hero{"Hero", 40, 40, 8};
  int mana = 10, potions = 3, level = 1;
  Fighter monsters[] = {{"Slime", 20, 20, 4}, {"Goblin", 30, 30, 6}, {"Robot Knight", 45, 45, 8}, {"DRAGON", 70, 70, 11}};

  for (Fighter &m : monsters) {
    std::cout << "\nA wild " << m.name << " appears! (" << m.hp << " HP)\n";
    while (m.hp > 0 && hero.hp > 0) {
      std::cout << "\n" << hero.name << " HP " << hero.hp << "/" << hero.maxHp << "  Mana " << mana << "  Potions " << potions
                << "   |   " << m.name << " HP " << m.hp << "\n";
      std::cout << "1 Attack  2 Fireball (5 mana)  3 Potion  > ";
      int choice;
      if (!(std::cin >> choice)) { std::cout << "\nYou ran away!\n"; return 0; }

      if (choice == 1) {
        int dmg = roll(hero.attack - 2, hero.attack + 3);
        if (roll(1, 10) == 10) { dmg *= 2; std::cout << "CRITICAL HIT! "; }
        m.hp -= dmg;
        std::cout << "You hit the " << m.name << " for " << dmg << ".\n";
      } else if (choice == 2 && mana >= 5) {
        int dmg = roll(12, 18);
        mana -= 5;
        m.hp -= dmg;
        std::cout << "FIREBALL! " << dmg << " damage.\n";
      } else if (choice == 3 && potions > 0) {
        potions--;
        hero.hp = std::min(hero.maxHp, hero.hp + 20);
        std::cout << "You drink a potion and heal.\n";
      } else {
        std::cout << "You can't do that! You lose your turn.\n";
      }

      if (m.hp > 0) {  // the monster strikes back
        int dmg = roll(m.attack - 2, m.attack + 2);
        if (roll(1, 6) == 1) std::cout << "The " << m.name << " misses!\n";
        else { hero.hp -= dmg; std::cout << "The " << m.name << " hits you for " << dmg << ".\n"; }
      }
    }
    if (hero.hp <= 0) { std::cout << "\nYou were defeated by the " << m.name << ". GAME OVER\n"; return 0; }

    level++;
    hero.maxHp += 10;
    hero.attack += 2;
    hero.hp = std::min(hero.maxHp, hero.hp + 15);
    mana += 5;
    std::cout << "You beat the " << m.name << "! LEVEL UP to " << level << ". Max HP " << hero.maxHp << ", attack " << hero.attack << ".\n";
  }
  std::cout << "\nYou defeated the DRAGON and saved the kingdom! YOU WIN!\n";
  return 0;
}
