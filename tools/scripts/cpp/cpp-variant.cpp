// @title std::variant: One Box, Several Possible Types
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o variant && ./variant
// @keywords std variant, std visit, holds_alternative, type safe union, c++17 variant
// @about Stores loot that can be gold (an int), a weapon name (a string) or a potion strength (a double) in one std::variant.

#include <iostream>
#include <string>
#include <type_traits>
#include <variant>
#include <vector>

// Loot can be ONE of these three types at a time.
using Loot = std::variant<int, std::string, double>;

int main() {
  std::vector<Loot> chest = {50, std::string("Flame Sword"), 0.75, 120, std::string("Ice Bow")};

  int gold = 0;
  for (const Loot &item : chest) {
    // holds_alternative checks which type is inside.
    if (std::holds_alternative<int>(item)) {
      gold += std::get<int>(item);
      std::cout << "Gold coins: " << std::get<int>(item) << "\n";
    } else if (std::holds_alternative<std::string>(item)) {
      std::cout << "Weapon: " << std::get<std::string>(item) << "\n";
    } else {
      std::cout << "Potion that heals " << std::get<double>(item) * 100 << "%\n";
    }
  }
  std::cout << "Total gold: " << gold << "\n\n";

  // std::visit runs code for whatever type is inside. "auto" lets one lambda handle all three.
  for (const Loot &item : chest) {
    std::visit([](const auto &value) {
      using T = std::decay_t<decltype(value)>;
      if constexpr (std::is_same_v<T, int>) std::cout << "[int] ";
      else if constexpr (std::is_same_v<T, std::string>) std::cout << "[string] ";
      else std::cout << "[double] ";
      std::cout << value << "\n";
    }, item);
  }

  // Changing the type inside is fine. It just becomes the new type.
  Loot surprise = 10;
  surprise = std::string("Mystery Box");
  std::cout << "\nThe surprise is now a string? " << std::boolalpha
            << std::holds_alternative<std::string>(surprise) << "\n";
  return 0;
}
