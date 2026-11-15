// @title Counting Sort for Test Scores
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o countingsort && ./countingsort
// @keywords counting sort, sort without comparing, histogram sort, sort small range numbers, tally sort
// @about Sorts test scores from 0 to 10 by counting how many of each there are, and draws a tally chart.

#include <iostream>
#include <random>
#include <vector>

int main() {
  std::mt19937 rng(2026);
  std::normal_distribution<double> bell(7.0, 1.8);  // most scores near 7
  std::vector<int> scores;
  for (int i = 0; i < 30; i++) {
    int s = static_cast<int>(bell(rng) + 0.5);
    if (s < 0) s = 0;
    if (s > 10) s = 10;
    scores.push_back(s);
  }

  std::cout << "Scores:";
  for (int s : scores) std::cout << " " << s;
  std::cout << "\n\n";

  // Step 1: count how many times each score appears. No comparing at all!
  int counts[11] = {0};
  for (int s : scores) counts[s]++;

  std::cout << "Tally chart:\n";
  for (int s = 0; s <= 10; s++) {
    std::cout << (s < 10 ? " " : "") << s << " | ";
    for (int k = 0; k < counts[s]; k++) std::cout << "#";
    std::cout << " " << counts[s] << "\n";
  }

  // Step 2: write each score out as many times as it was counted.
  std::vector<int> sorted;
  for (int s = 0; s <= 10; s++)
    for (int k = 0; k < counts[s]; k++) sorted.push_back(s);

  std::cout << "\nSorted:";
  for (int s : sorted) std::cout << " " << s;
  std::cout << "\nMedian (middle) score: " << sorted[sorted.size() / 2] << "\n";
  return 0;
}
