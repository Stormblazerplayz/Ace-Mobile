// @title Class Template: an Inventory Bag
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bag && ./bag
// @keywords c++ class template, template class example, generic container c++, template with size
// @about Builds a Bag class template with a fixed number of slots that can hold any type of item.

#include <array>
#include <iostream>
#include <string>

// T is the item type, CAPACITY is how many slots. Both are chosen when you make a Bag.
template <typename T, int CAPACITY>
class Bag {
public:
  bool add(const T &item) {
    if (count_ >= CAPACITY) {
      std::cout << "  Bag is full! Can't add " << item << "\n";
      return false;
    }
    slots_[count_++] = item;
    return true;
  }

  bool removeLast() {
    if (count_ == 0) return false;
    count_--;
    return true;
  }

  bool contains(const T &item) const {
    for (int i = 0; i < count_; i++) {
      if (slots_[i] == item) return true;
    }
    return false;
  }

  void print() const {
    std::cout << "  Bag (" << count_ << "/" << CAPACITY << "):";
    for (int i = 0; i < count_; i++) std::cout << " [" << slots_[i] << "]";
    std::cout << "\n";
  }

private:
  std::array<T, CAPACITY> slots_{};
  int count_ = 0;
};

int main() {
  std::cout << "Adventurer's bag (holds 3 strings):\n";
  Bag<std::string, 3> backpack;
  backpack.add("sword");
  backpack.add("map");
  backpack.add("apple");
  backpack.add("dragon egg");  // too many!
  backpack.print();
  std::cout << "  Has a map? " << (backpack.contains("map") ? "yes" : "no") << "\n";
  backpack.removeLast();
  backpack.print();

  std::cout << "\nDice bag (holds 5 ints):\n";
  Bag<int, 5> dice;
  for (int i = 1; i <= 6; i++) dice.add(i * 2);
  dice.print();
  return 0;
}
