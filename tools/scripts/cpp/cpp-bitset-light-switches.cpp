// @title std::bitset Light Switch Puzzle
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o lights && ./lights
// @keywords std bitset, bitset flip count, lights out puzzle, 100 lockers problem, bit array c++
// @about Uses std::bitset to solve the famous 100 lockers puzzle and to play with a row of light switches.

#include <bitset>
#include <iostream>

int main() {
  // 100 lockers, all closed. Student 1 flips every locker, student 2 every 2nd, student 3 every 3rd...
  std::bitset<101> lockers;  // bit 0 unused so locker numbers match
  for (int student = 1; student <= 100; student++) {
    for (int locker = student; locker <= 100; locker += student) lockers.flip(locker);
  }
  std::cout << "Open lockers after 100 students:";
  for (int i = 1; i <= 100; i++) if (lockers[i]) std::cout << " " << i;
  std::cout << "\n(They're all square numbers! Can you work out why?)\n";
  std::cout << "Count: " << lockers.count() << " open\n\n";

  // A row of 8 light switches.
  std::bitset<8> lights("10110010");
  std::cout << "Lights:        " << lights << " (" << lights.count() << " on)\n";
  lights.set(0);    // turn on light 0 (the rightmost)
  lights.reset(7);  // turn off light 7 (the leftmost)
  std::cout << "set 0, reset 7:" << " " << lights << "\n";
  lights.flip();    // flip every switch
  std::cout << "flip all:      " << lights << "\n";
  std::cout << "As a number:   " << lights.to_ulong() << "\n";
  std::cout << "Any on? " << std::boolalpha << lights.any() << ", all on? " << lights.all() << "\n";

  // Shift: move every light one place left.
  std::cout << "shifted left:  " << (lights << 1) << "\n";
  return 0;
}
