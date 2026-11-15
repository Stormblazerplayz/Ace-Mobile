// @title Monster Type Battle
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o monsters && ./monsters
// @keywords monster type battle, fire water grass types, type advantage chart, pick your monster, super effective
// @about Pick a monster and battle the computer's team, where fire beats grass, water beats fire and grass beats water.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

enum Type { FIRE, WATER, GRASS };
const char *typeName[] = {"Fire", "Water", "Grass"};

struct Monster {
  std::string name;
  Type type;
  int hp, power;
};

// How strong is an attack of type a against a monster of type d?
double effectiveness(Type a, Type d) {
  if ((a == FIRE && d == GRASS) || (a == WATER && d == FIRE) || (a == GRASS && d == WATER)) return 2.0;
  if ((a == GRASS && d == FIRE) || (a == FIRE && d == WATER) || (a == WATER && d == GRASS)) return 0.5;
  return 1.0;
}

void attack(Monster &from, Monster &to, std::mt19937 &rng) {
  double mult = effectiveness(from.type, to.type);
  int dmg = static_cast<int>(std::uniform_int_distribution<int>(from.power - 2, from.power + 2)(rng) * mult);
  to.hp -= dmg;
  std::cout << "  " << from.name << " attacks " << to.name << " for " << dmg;
  if (mult > 1) std::cout << " - it's super effective!";
  if (mult < 1) std::cout << " - not very effective...";
  std::cout << "\n";
}

int main() {
  std::mt19937 rng(std::random_device{}());
  std::vector<Monster> choices = {{"Blazepup", FIRE, 40, 9}, {"Splashfin", WATER, 44, 8}, {"Leafling", GRASS, 48, 7}};
  std::vector<Monster> enemies = {{"Emberat", FIRE, 30, 7}, {"Drizzle", WATER, 32, 7}, {"Thornix", GRASS, 34, 7}};
  std::shuffle(enemies.begin(), enemies.end(), rng);

  std::cout << "Pick your monster:\n";
  for (size_t i = 0; i < choices.size(); i++)
    std::cout << "  " << i + 1 << " " << choices[i].name << " (" << typeName[choices[i].type] << ", " << choices[i].hp << " HP)\n";
  int pick;
  if (!(std::cin >> pick) || pick < 1 || pick > 3) pick = 1;
  Monster me = choices[pick - 1];
  std::cout << "Go, " << me.name << "!\n";

  int beaten = 0;
  for (Monster &foe : enemies) {
    std::cout << "\nThe computer sends out " << foe.name << " (" << typeName[foe.type] << ")!\n";
    std::cout << "Press f to fight, r to run: ";
    char c;
    if (!(std::cin >> c) || c != 'f') { std::cout << "You got away safely.\n"; break; }
    while (me.hp > 0 && foe.hp > 0) {
      attack(me, foe, rng);
      if (foe.hp > 0) attack(foe, me, rng);
    }
    if (me.hp <= 0) { std::cout << me.name << " fainted! You lose.\n"; break; }
    beaten++;
    me.hp += 10;
    std::cout << foe.name << " fainted! " << me.name << " rests and has " << me.hp << " HP.\n";
  }
  std::cout << "\nYou beat " << beaten << " of 3 monsters." << (beaten == 3 ? " You're the champion!" : "") << "\n";
  return 0;
}
