// @title Giant Number Calculator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bignum && ./bignum
// @keywords big number addition, add huge numbers, long multiplication strings, factorial of 50, digits as strings
// @about Adds and multiplies numbers with hundreds of digits by doing column math on strings, then works out 50 factorial.

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

// Column addition, right to left, with carrying, just like on paper.
std::string add(const std::string &a, const std::string &b) {
  std::string out;
  int carry = 0;
  for (int i = static_cast<int>(a.size()) - 1, j = static_cast<int>(b.size()) - 1; i >= 0 || j >= 0 || carry; i--, j--) {
    int sum = carry + (i >= 0 ? a[i] - '0' : 0) + (j >= 0 ? b[j] - '0' : 0);
    out += static_cast<char>('0' + sum % 10);
    carry = sum / 10;
  }
  std::reverse(out.begin(), out.end());
  return out;
}

// Long multiplication: every digit times every digit, added into the right column.
std::string multiply(const std::string &a, const std::string &b) {
  std::vector<int> cols(a.size() + b.size(), 0);
  for (int i = static_cast<int>(a.size()) - 1; i >= 0; i--)
    for (int j = static_cast<int>(b.size()) - 1; j >= 0; j--) {
      int sum = (a[i] - '0') * (b[j] - '0') + cols[i + j + 1];
      cols[i + j + 1] = sum % 10;
      cols[i + j] += sum / 10;
    }
  std::string out;
  for (int d : cols) if (!(out.empty() && d == 0)) out += static_cast<char>('0' + d);
  return out.empty() ? "0" : out;
}

bool allDigits(const std::string &s) {
  return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) { return c >= '0' && c <= '9'; });
}

int main() {
  std::string f = "1";
  for (int i = 2; i <= 50; i++) f = multiply(f, std::to_string(i));
  std::cout << "50! = " << f << " (" << f.size() << " digits)\n\n";

  std::cout << "Type two huge whole numbers (Ctrl+D to stop):\n";
  std::string a, b;
  while (std::cout << "> " && std::cin >> a >> b) {
    if (!allDigits(a) || !allDigits(b)) { std::cout << "Only digits please.\n"; continue; }
    std::cout << "Sum:     " << add(a, b) << "\nProduct: " << multiply(a, b) << "\n";
  }
  std::cout << "\n";
  return 0;
}
