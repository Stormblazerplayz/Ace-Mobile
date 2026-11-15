// @title Tour of STL Algorithms
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o algorithms && ./algorithms
// @keywords stl algorithms, accumulate transform, remove_if erase, min_element max_element, std count find
// @about Tries the most useful <algorithm> and <numeric> tools on a list of game scores: count, find, sum, transform, remove and more.

#include <algorithm>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

void show(const std::string &label, const std::vector<int> &v) {
  std::cout << label << ":";
  for (int x : v) std::cout << " " << x;
  std::cout << "\n";
}

int main() {
  std::vector<int> scores = {120, 85, 300, 85, 40, 220, 0, 155, 85};
  show("scores", scores);

  std::cout << "sum (accumulate): " << std::accumulate(scores.begin(), scores.end(), 0) << "\n";
  std::cout << "count of 85: " << std::count(scores.begin(), scores.end(), 85) << "\n";
  std::cout << "count over 100: " << std::count_if(scores.begin(), scores.end(), [](int s) { return s > 100; }) << "\n";
  std::cout << "highest: " << *std::max_element(scores.begin(), scores.end())
            << ", lowest: " << *std::min_element(scores.begin(), scores.end()) << "\n";

  auto it = std::find(scores.begin(), scores.end(), 220);
  if (it != scores.end()) std::cout << "220 is at position " << (it - scores.begin()) << "\n";

  bool anyZero = std::any_of(scores.begin(), scores.end(), [](int s) { return s == 0; });
  bool allPositive = std::all_of(scores.begin(), scores.end(), [](int s) { return s >= 0; });
  std::cout << std::boolalpha << "any zero? " << anyZero << ", none negative? " << allPositive << "\n";

  // transform: make a new list by changing each item (double points weekend!).
  std::vector<int> doubled(scores.size());
  std::transform(scores.begin(), scores.end(), doubled.begin(), [](int s) { return s * 2; });
  show("doubled", doubled);

  // remove_if + erase: really delete the zero scores.
  scores.erase(std::remove_if(scores.begin(), scores.end(), [](int s) { return s == 0; }), scores.end());
  show("without 0", scores);

  // sort then unique: remove repeated numbers.
  std::sort(scores.begin(), scores.end());
  scores.erase(std::unique(scores.begin(), scores.end()), scores.end());
  show("sorted unique", scores);

  std::reverse(scores.begin(), scores.end());
  show("reversed", scores);

  // iota fills with counting numbers.
  std::vector<int> levels(5);
  std::iota(levels.begin(), levels.end(), 1);
  show("levels (iota)", levels);
  return 0;
}
