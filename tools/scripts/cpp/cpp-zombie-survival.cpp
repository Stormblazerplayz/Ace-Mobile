// @title Zombie Survival Days
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o zombies && ./zombies
// @keywords zombie survival, resource management game, food and health, scavenge or rest, survive ten days
// @about Survive ten days of a (silly) zombie outbreak by choosing each day to scavenge, build barricades or rest.

#include <algorithm>
#include <iostream>
#include <random>

int main() {
  std::mt19937 rng(std::random_device{}());
  auto chance = [&](int percent) { return std::uniform_int_distribution<int>(1, 100)(rng) <= percent; };
  int health = 10, food = 5, walls = 2;

  std::cout << "The zombies are coming! Survive 10 days.\n";
  for (int day = 1; day <= 10; day++) {
    std::cout << "\n--- Day " << day << " ---  Health " << health << "  Food " << food << "  Barricades " << walls << "\n";
    std::cout << "1 Scavenge for food  2 Build barricades  3 Rest\n> ";
    int choice;
    if (!(std::cin >> choice)) { std::cout << "\nYou hide in the basement forever. The end.\n"; return 0; }

    if (choice == 1) {
      int found = std::uniform_int_distribution<int>(1, 4)(rng);
      food += found;
      std::cout << "You find " << found << " cans of beans.\n";
      if (chance(35)) { health -= 2; std::cout << "A zombie chases you! You trip and lose 2 health.\n"; }
    } else if (choice == 2) {
      walls++;
      std::cout << "You nail boards over the windows. Barricades up!\n";
    } else {
      health = std::min(10, health + 3);
      std::cout << "You take a nap and feel better.\n";
    }

    // Everyone needs to eat.
    if (food > 0) food--;
    else { health -= 2; std::cout << "No food! You're starving (-2 health).\n"; }

    // Night attack: barricades break before you get hurt.
    if (chance(20 + day * 5)) {
      std::cout << "Zombies attack in the night! ";
      if (walls > 0) { walls--; std::cout << "Your barricade holds, but breaks.\n"; }
      else { health -= 3; std::cout << "No barricades! You fight them off but lose 3 health.\n"; }
    }
    if (health <= 0) { std::cout << "\nYou didn't make it. You survived " << day - 1 << " days.\n"; return 0; }
  }
  std::cout << "\nThe rescue helicopter arrives! You SURVIVED with " << health << " health!\n";
  return 0;
}
