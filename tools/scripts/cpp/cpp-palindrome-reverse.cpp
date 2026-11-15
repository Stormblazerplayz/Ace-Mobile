// @title Reverse Text and Palindrome Checker
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o palindrome && ./palindrome
// @keywords palindrome checker, reverse a string c++, racecar palindrome, std reverse string, two pointer check
// @about Reverses whatever you type and checks if it is a palindrome, ignoring spaces, capitals and punctuation.

#include <algorithm>
#include <cctype>
#include <iostream>
#include <string>

// Keep only letters and digits, all lowercase.
std::string cleanUp(const std::string &text) {
  std::string out;
  for (char ch : text) {
    unsigned char c = static_cast<unsigned char>(ch);
    if (std::isalnum(c)) out += static_cast<char>(std::tolower(c));
  }
  return out;
}

// Two "fingers": one at the start, one at the end, walking toward the middle.
bool isPalindrome(const std::string &s) {
  if (s.empty()) return false;
  std::size_t left = 0, right = s.size() - 1;
  while (left < right) {
    if (s[left] != s[right]) return false;
    left++;
    right--;
  }
  return true;
}

int main() {
  std::cout << "Type words or sentences (empty line or Ctrl+D to quit).\n";
  std::cout << "Try: racecar, Never odd or even, A man a plan a canal Panama\n\n";
  std::string line;
  while (std::cout << "> " && std::getline(std::cin, line) && !line.empty()) {
    std::string reversed(line.rbegin(), line.rend());  // build a string from back to front
    std::cout << "Backwards: " << reversed << "\n";

    std::string clean = cleanUp(line);
    std::cout << (isPalindrome(clean) ? "Yes! It's a palindrome.\n" : "Not a palindrome.\n");

    // Another way to reverse: std::reverse changes a string in place.
    std::string copy = clean;
    std::reverse(copy.begin(), copy.end());
    std::cout << "(cleaned: " << clean << " / " << copy << ")\n\n";
  }
  std::cout << "\nBye!\n";
  return 0;
}
