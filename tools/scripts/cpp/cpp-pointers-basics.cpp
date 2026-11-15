// @title Pointers Explained
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pointers && ./pointers
// @keywords c++ pointers, memory address c++, dereference pointer, nullptr, new and delete c++
// @about Shows what a pointer is, how to get an address with & and follow it with *, and how to use new and delete safely.

#include <iostream>

int main() {
  int coins = 10;
  // A pointer holds the ADDRESS of another variable (where it lives in memory).
  int *ptr = &coins;  // & means "address of"

  std::cout << "coins = " << coins << "\n";
  std::cout << "address of coins = " << ptr << "\n";
  std::cout << "*ptr (the value at that address) = " << *ptr << "\n";

  *ptr = 25;  // change coins THROUGH the pointer
  std::cout << "after *ptr = 25, coins = " << coins << "\n\n";

  // nullptr means "points at nothing". Always check before using it!
  int *nothing = nullptr;
  if (nothing == nullptr) std::cout << "nothing points nowhere, so we don't touch it.\n\n";

  // Arrays and pointers: the array name works like a pointer to the first item.
  int scores[4] = {90, 75, 60, 88};
  int *p = scores;
  for (int i = 0; i < 4; i++) {
    std::cout << "scores[" << i << "] = " << *(p + i) << "\n";  // p + i moves along the array
  }

  // new makes memory that lasts until you delete it.
  int *bonus = new int(500);
  std::cout << "\nbonus lives at " << bonus << " and holds " << *bonus << "\n";
  delete bonus;      // give the memory back (or it "leaks")
  bonus = nullptr;   // so we never use the old address by mistake

  // Tip: in modern C++ use std::unique_ptr instead of new/delete. It deletes for you!
  return 0;
}
