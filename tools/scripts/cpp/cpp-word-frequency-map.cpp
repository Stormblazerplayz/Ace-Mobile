// @title Word Frequency Counter with std::map
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o wordfreq && ./wordfreq (type or paste text, then Ctrl+D)
// @keywords std map, word frequency, count words map, most common words, map sort by value
// @about Counts how many times each word appears using std::map, then lists the top 10 most common words.

#include <algorithm>
#include <cctype>
#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
  std::cout << "Type or paste some text, then press Ctrl+D:\n";
  std::map<std::string, int> counts;  // word -> how many times
  std::string word;
  while (std::cin >> word) {
    std::string clean;
    for (char ch : word) {
      unsigned char c = static_cast<unsigned char>(ch);
      if (std::isalpha(c) || ch == '\'') clean += static_cast<char>(std::tolower(c));
    }
    if (!clean.empty()) counts[clean]++;  // [] creates the word with 0 if it's new
  }

  if (counts.empty()) {
    std::string sample = "the cat and the dog and the bird sat on the mat";
    std::cout << "(No text given, using a sample: \"" << sample << "\")\n";
    std::size_t start = 0;
    while (start < sample.size()) {
      std::size_t end = sample.find(' ', start);
      if (end == std::string::npos) end = sample.size();
      counts[sample.substr(start, end - start)]++;
      start = end + 1;
    }
  }

  std::cout << "\nAll words in alphabetical order (maps sort their keys):\n";
  for (const auto &[w, n] : counts) std::cout << "  " << w << ": " << n << "\n";

  // To sort by count, copy into a vector of pairs and sort that.
  std::vector<std::pair<std::string, int>> sorted(counts.begin(), counts.end());
  std::sort(sorted.begin(), sorted.end(), [](const auto &a, const auto &b) {
    return a.second != b.second ? a.second > b.second : a.first < b.first;
  });
  std::cout << "\nTop words:\n";
  for (std::size_t i = 0; i < sorted.size() && i < 10; i++) {
    std::cout << "  " << i + 1 << ". " << sorted[i].first << " (" << sorted[i].second << ")\n";
  }
  std::cout << counts.size() << " different words.\n";
  return 0;
}
