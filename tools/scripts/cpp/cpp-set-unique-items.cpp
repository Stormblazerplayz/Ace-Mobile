// @title Sets: Unique Items Only
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o sets && ./sets
// @keywords std set, remove duplicates c++, set union intersection, unique values, set_intersection
// @about Uses std::set to remove duplicates and to compare two friends' game collections with union, intersection and difference.

#include <algorithm>
#include <iostream>
#include <iterator>
#include <set>
#include <string>
#include <vector>

void print(const std::string &label, const std::set<std::string> &s) {
  std::cout << label << " (" << s.size() << "):";
  for (const auto &item : s) std::cout << " " << item;
  std::cout << "\n";
}

int main() {
  // A set throws away duplicates and keeps everything sorted.
  std::vector<int> rolls = {4, 2, 6, 2, 4, 4, 1, 6, 3};
  std::set<int> different(rolls.begin(), rolls.end());
  std::cout << "Dice rolls had " << rolls.size() << " numbers but only " << different.size() << " different ones:";
  for (int r : different) std::cout << " " << r;
  std::cout << "\n\n";

  std::set<std::string> mine = {"Minecraft", "Roblox", "Terraria", "Rocket League", "Fortnite"};
  std::set<std::string> yours = {"Fortnite", "Minecraft", "Among Us", "Fall Guys"};
  print("My games", mine);
  print("Your games", yours);

  std::set<std::string> both, either, onlyMine;
  // Games we both have.
  std::set_intersection(mine.begin(), mine.end(), yours.begin(), yours.end(), std::inserter(both, both.begin()));
  // Every game either of us has.
  std::set_union(mine.begin(), mine.end(), yours.begin(), yours.end(), std::inserter(either, either.begin()));
  // Games only I have.
  std::set_difference(mine.begin(), mine.end(), yours.begin(), yours.end(), std::inserter(onlyMine, onlyMine.begin()));

  print("We both have", both);
  print("Between us we have", either);
  print("Only I have", onlyMine);

  // insert tells you whether the item was new.
  auto result = mine.insert("Roblox");
  std::cout << "\nAdding Roblox again: " << (result.second ? "added" : "already there") << "\n";
  std::cout << "Do I have Terraria? " << (mine.count("Terraria") ? "yes" : "no") << "\n";
  return 0;
}
