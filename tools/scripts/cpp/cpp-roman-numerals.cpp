// @title Roman Numeral Converter
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o roman && ./roman
// @keywords roman numerals, number to roman, roman to number, mcmxcix, ancient rome numbers
// @about Turns numbers into Roman numerals and Roman numerals back into numbers, from 1 to 3999.

#include <cctype>
#include <iostream>
#include <string>

const int values[] = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
const char *symbols[] = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"};

// Greedy: take the biggest symbol that still fits, again and again.
std::string toRoman(int n) {
  std::string out;
  for (int i = 0; i < 13; i++) {
    while (n >= values[i]) { out += symbols[i]; n -= values[i]; }
  }
  return out;
}

int letterValue(char c) {
  switch (c) {
    case 'I': return 1;   case 'V': return 5;   case 'X': return 10;  case 'L': return 50;
    case 'C': return 100; case 'D': return 500; case 'M': return 1000; default: return 0;
  }
}

// A smaller letter before a bigger one is subtracted (IV = 4), otherwise added.
int fromRoman(const std::string &s) {
  int total = 0;
  for (size_t i = 0; i < s.size(); i++) {
    int v = letterValue(s[i]);
    if (v == 0) return -1;
    if (i + 1 < s.size() && v < letterValue(s[i + 1])) total -= v;
    else total += v;
  }
  return total;
}

int main() {
  std::cout << "Type a number (1-3999) or a Roman numeral like XIV (Ctrl+D to stop):\n";
  std::string word;
  while (std::cout << "> " && std::cin >> word) {
    if (std::isdigit(static_cast<unsigned char>(word[0]))) {
      long n = std::stol(word.substr(0, 9));
      if (n < 1 || n > 3999) std::cout << "Romans only wrote 1 to 3999 this way.\n";
      else std::cout << n << " = " << toRoman(static_cast<int>(n)) << "\n";
    } else {
      for (char &c : word) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
      int n = fromRoman(word);
      // Check it by converting back: this catches badly written ones like IIII or VX.
      if (n <= 0 || n > 3999 || toRoman(n) != word) std::cout << word << " is not a proper Roman numeral.\n";
      else std::cout << word << " = " << n << "\n";
    }
  }
  std::cout << "\n";
  return 0;
}
