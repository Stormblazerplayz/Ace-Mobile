// @title Playing with Strings
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o strings && ./strings
// @keywords c++ string, string find substr, string length, c++ string functions, uppercase string c++
// @about Shows how to join, measure, search, cut, change and compare strings in C++.

#include <cctype>
#include <iostream>
#include <string>

int main() {
  std::string first = "Iron";
  std::string second = "Man";

  // Joining strings with +
  std::string hero = first + " " + second;
  std::cout << "Joined: " << hero << "\n";
  std::cout << "Length: " << hero.length() << " characters\n";

  // Each character has a position number starting at 0.
  std::cout << "First letter: " << hero[0] << ", last letter: " << hero[hero.length() - 1] << "\n";

  // find returns the position, or std::string::npos if it's not there.
  std::size_t where = hero.find("Man");
  if (where != std::string::npos) std::cout << "\"Man\" starts at position " << where << "\n";
  if (hero.find("Bat") == std::string::npos) std::cout << "No \"Bat\" in there!\n";

  // substr(start, howMany) cuts out a piece.
  std::cout << "substr(0, 4): " << hero.substr(0, 4) << "\n";

  // replace(start, howMany, newText)
  std::string other = hero;
  other.replace(where, 3, "Golem");
  std::cout << "Replaced: " << other << "\n";

  // Change every letter to uppercase with a loop.
  std::string shout = hero;
  for (char &c : shout) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
  std::cout << "Shouting: " << shout << "\n";

  // Count the vowels.
  int vowels = 0;
  for (char c : hero) {
    char lower = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    if (std::string("aeiou").find(lower) != std::string::npos) vowels++;
  }
  std::cout << "Vowels: " << vowels << "\n";

  // Strings compare in dictionary order.
  std::string a = "apple", b = "banana";
  std::cout << a << (a < b ? " comes before " : " comes after ") << b << "\n";

  // Adding to the end.
  hero += " 2";
  hero.push_back('!');
  std::cout << "Sequel: " << hero << "\n";
  return 0;
}
