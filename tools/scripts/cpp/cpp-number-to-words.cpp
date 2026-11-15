// @title Number to Words
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o words && ./words
// @keywords number to words, spell out numbers, write a check amount, numbers in english, one thousand two hundred
// @about Spells out any number up to the billions in English words, like a check writer does.

#include <iostream>
#include <string>

const char *ones[] = {"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
                      "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                      "seventeen", "eighteen", "nineteen"};
const char *tens[] = {"", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"};

// Spells 0 to 999.
std::string under1000(int n) {
  std::string out;
  if (n >= 100) {
    out = std::string(ones[n / 100]) + " hundred";
    n %= 100;
    if (n == 0) return out;
    out += " ";
  }
  if (n < 20) return out + ones[n];
  out += tens[n / 10];
  if (n % 10) out += std::string("-") + ones[n % 10];
  return out;
}

std::string toWords(long long n) {
  if (n == 0) return "zero";
  if (n < 0) return "minus " + toWords(-n);
  const char *groups[] = {"", " thousand", " million", " billion", " trillion"};
  std::string out;
  // Split into groups of three digits from the right: 1,234,567 -> 1 | 234 | 567
  for (int g = 0; n > 0 && g < 5; g++) {
    int chunk = static_cast<int>(n % 1000);
    if (chunk) {
      std::string part = under1000(chunk) + groups[g];
      out = out.empty() ? part : part + " " + out;
    }
    n /= 1000;
  }
  return out;
}

int main() {
  std::cout << "Type numbers to spell (up to 999 trillion, Ctrl+D to stop):\n";
  long long n;
  while (std::cout << "> " && std::cin >> n) {
    if (n > 999999999999999LL || n < -999999999999999LL) std::cout << "That's too big for me!\n";
    else std::cout << toWords(n) << "\n";
  }
  std::cout << "\n";
  return 0;
}
