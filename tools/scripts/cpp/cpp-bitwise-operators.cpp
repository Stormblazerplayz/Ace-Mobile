// @title Bitwise Operators and Flags
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bits && ./bits
// @keywords c++ bitwise operators, bit flags, bitmask c++, shift left right, and or xor bits
// @about Uses single bits as on and off switches for a player's power-ups, with &, |, ^, ~ and shifts.

#include <bitset>
#include <cstdint>
#include <iostream>

// Each power-up gets its own bit. 1 << n means "a 1 moved n places left".
const std::uint8_t SPEED = 1 << 0;   // 00000001
const std::uint8_t SHIELD = 1 << 1;  // 00000010
const std::uint8_t JUMP = 1 << 2;    // 00000100
const std::uint8_t MAGNET = 1 << 3;  // 00001000

void show(const char *label, std::uint8_t flags) {
  std::cout << label << std::bitset<8>(flags) << "  ";
  if (flags & SPEED) std::cout << "[speed] ";
  if (flags & SHIELD) std::cout << "[shield] ";
  if (flags & JUMP) std::cout << "[jump] ";
  if (flags & MAGNET) std::cout << "[magnet] ";
  std::cout << "\n";
}

int main() {
  std::uint8_t powers = 0;
  show("start:          ", powers);

  powers |= SPEED;   // OR turns a bit ON
  powers |= MAGNET;
  show("got speed+mag:  ", powers);

  powers ^= SHIELD;  // XOR flips a bit
  show("flip shield:    ", powers);

  powers &= static_cast<std::uint8_t>(~SPEED);  // AND with NOT turns a bit OFF
  show("speed ran out:  ", powers);

  bool hasMagnet = (powers & MAGNET) != 0;  // AND checks a bit
  std::cout << "Has magnet? " << (hasMagnet ? "yes" : "no") << "\n\n";

  // Shifting left doubles a number, shifting right halves it.
  int n = 5;
  std::cout << n << " << 1 = " << (n << 1) << ",  " << n << " << 3 = " << (n << 3) << "\n";
  std::cout << "40 >> 2 = " << (40 >> 2) << "\n";

  // Count how many bits are on.
  int onBits = 0;
  for (int bit = 0; bit < 8; bit++) {
    if (powers & (1 << bit)) onBits++;
  }
  std::cout << "Power-ups active: " << onBits << "\n";
  return 0;
}
