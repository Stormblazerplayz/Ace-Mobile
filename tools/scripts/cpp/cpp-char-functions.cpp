// @title Checking Characters (Password Strength)
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o strength && ./strength
// @keywords password strength checker, isdigit isupper, cctype functions, check characters c++, character types
// @about Uses isupper, islower, isdigit and ispunct to rate how strong a typed password is.

#include <cctype>
#include <iostream>
#include <string>

int main() {
  std::cout << "Type a made-up password to test (not a real one!): ";
  std::string pw;
  if (!std::getline(std::cin, pw)) pw = "";

  int upper = 0, lower = 0, digits = 0, symbols = 0, spaces = 0;
  for (char ch : pw) {
    // cctype functions want an unsigned char, so we convert first.
    unsigned char c = static_cast<unsigned char>(ch);
    if (std::isupper(c)) upper++;
    else if (std::islower(c)) lower++;
    else if (std::isdigit(c)) digits++;
    else if (std::isspace(c)) spaces++;
    else if (std::ispunct(c)) symbols++;
  }

  std::cout << "Length: " << pw.size() << "\n"
            << "Uppercase: " << upper << ", lowercase: " << lower
            << ", digits: " << digits << ", symbols: " << symbols << "\n";

  int points = 0;
  if (pw.size() >= 8) points++;
  if (pw.size() >= 12) points++;
  if (upper > 0) points++;
  if (lower > 0) points++;
  if (digits > 0) points++;
  if (symbols > 0) points++;

  std::cout << "Strength: ";
  for (int i = 0; i < 6; i++) std::cout << (i < points ? '#' : '-');
  if (points <= 2) std::cout << "  weak\n";
  else if (points <= 4) std::cout << "  ok\n";
  else std::cout << "  strong!\n";

  if (spaces > 0) std::cout << "Tip: some websites don't allow spaces.\n";
  if (digits == 0) std::cout << "Tip: add a number.\n";
  if (symbols == 0) std::cout << "Tip: add a symbol like ! or #.\n";
  return 0;
}
