// @title std::vector Basics
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o vectors && ./vectors
// @keywords c++ vector, std vector basics, c++ list of items, c++ dynamic array, how to use vector in c++
// @about Shows how to make a std::vector, add and remove items, loop over it and find things in it.

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

// Print every item in a vector of strings.
void printAll(const std::vector<std::string> &items) {
  std::cout << "[";
  for (std::size_t i = 0; i < items.size(); i++) {
    std::cout << items[i];
    if (i + 1 < items.size()) std::cout << ", ";
  }
  std::cout << "]  (size " << items.size() << ")\n";
}

int main() {
  // A vector is a list that can grow and shrink.
  std::vector<std::string> inventory = {"sword", "shield"};
  printAll(inventory);

  // Add to the end.
  inventory.push_back("potion");
  inventory.push_back("map");
  std::cout << "After adding: ";
  printAll(inventory);

  // Read and change an item by its position (starts at 0!).
  std::cout << "First item: " << inventory[0] << "\n";
  inventory[1] = "golden shield";
  std::cout << "After upgrade: ";
  printAll(inventory);

  // Find an item.
  auto spot = std::find(inventory.begin(), inventory.end(), "potion");
  if (spot != inventory.end()) {
    std::cout << "Found potion at position " << (spot - inventory.begin()) << "\n";
    inventory.erase(spot);  // use it up
  }
  std::cout << "After using potion: ";
  printAll(inventory);

  // Remove the last item.
  inventory.pop_back();
  std::cout << "After dropping last item: ";
  printAll(inventory);

  // A vector of numbers, plus a "for each" loop to add them up.
  std::vector<int> scores = {40, 75, 90, 15};
  int total = 0;
  for (int score : scores) total += score;
  std::cout << "Total score: " << total << "\n";

  // Sort the numbers from small to big.
  std::sort(scores.begin(), scores.end());
  std::cout << "Sorted scores:";
  for (int score : scores) std::cout << " " << score;
  std::cout << "\n";

  // Empty it out.
  inventory.clear();
  std::cout << "Inventory empty? " << (inventory.empty() ? "yes" : "no") << "\n";
  return 0;
}
