// @title std::list: Insert Anywhere Fast
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o stdlist && ./stdlist
// @keywords std list, list iterator insert, erase while looping, list vs vector, list splice
// @about Uses std::list and iterators to insert and remove race cars in the middle of the order without moving the others.

#include <algorithm>
#include <iostream>
#include <iterator>
#include <list>
#include <string>

void show(const std::list<std::string> &race) {
  int place = 1;
  for (const auto &car : race) std::cout << "  " << place++ << ". " << car << "\n";
}

int main() {
  std::list<std::string> race = {"Red", "Blue", "Green", "Yellow", "Purple"};
  std::cout << "Starting order:\n";
  show(race);

  // Green overtakes Blue: find Green, take it out, put it before Blue.
  auto blue = std::find(race.begin(), race.end(), "Blue");
  auto green = std::find(race.begin(), race.end(), "Green");
  race.splice(blue, race, green);  // moves the node, no copying
  std::cout << "\nGreen overtakes Blue:\n";
  show(race);

  // A new car joins in 3rd place.
  auto third = std::next(race.begin(), 2);
  race.insert(third, "Orange");
  std::cout << "\nOrange joins in 3rd:\n";
  show(race);

  // Erase while looping: erase() gives back the next position, so use that.
  for (auto it = race.begin(); it != race.end();) {
    if (*it == "Yellow" || *it == "Red") {
      std::cout << "\n" << *it << " crashed out!";
      it = race.erase(it);
    } else {
      ++it;
    }
  }
  std::cout << "\n\nFinal order:\n";
  show(race);
  return 0;
}
