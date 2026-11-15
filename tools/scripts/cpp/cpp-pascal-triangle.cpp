// @title Pascal's Triangle
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pascal && ./pascal
// @keywords pascal's triangle, binomial coefficients, sierpinski pattern, triangle of numbers, row sums powers of two
// @about Prints Pascal's triangle, where each number is the two above it added, and shows the hidden Sierpinski pattern.

#include <iomanip>
#include <iostream>
#include <vector>

int main() {
  int rows = 12;
  std::cout << "How many rows (1-16)? ";
  if (!(std::cin >> rows) || rows < 1 || rows > 16) rows = 12;

  std::vector<std::vector<long long>> tri;
  for (int r = 0; r < 32; r++) {
    std::vector<long long> row(r + 1, 1);  // every row starts and ends with 1
    for (int c = 1; c < r; c++) row[c] = tri[r - 1][c - 1] + tri[r - 1][c];
    tri.push_back(row);
  }

  for (int r = 0; r < rows; r++) {
    std::cout << std::string((rows - r - 1) * 3, ' ');
    for (long long v : tri[r]) std::cout << std::setw(6) << v;
    long long sum = 0;
    for (long long v : tri[r]) sum += v;
    std::cout << "    (sum " << sum << ")\n";
  }
  std::cout << "Each row adds up to the next power of 2!\n\n";

  // Mark odd numbers with * and even with a space: a famous fractal appears.
  std::cout << "Odd numbers only (the Sierpinski triangle):\n";
  for (int r = 0; r < 32; r++) {
    std::cout << std::string(32 - r, ' ');
    for (long long v : tri[r]) std::cout << (v % 2 ? "* " : "  ");
    std::cout << "\n";
  }
  return 0;
}
