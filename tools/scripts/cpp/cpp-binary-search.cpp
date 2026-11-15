// @title Binary Search vs Linear Search
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o binarysearch && ./binarysearch
// @keywords binary search, linear search, search sorted list, halve the search, lower_bound c++
// @about Searches a sorted list of a million numbers both ways and counts how many looks each one needs.

#include <algorithm>
#include <iostream>
#include <vector>

int linearSearch(const std::vector<int> &v, int target, int &looks) {
  for (std::size_t i = 0; i < v.size(); i++) {
    looks++;
    if (v[i] == target) return static_cast<int>(i);
  }
  return -1;
}

// Only works on SORTED lists: look in the middle and throw away the half it can't be in.
int binarySearch(const std::vector<int> &v, int target, int &looks) {
  int low = 0, high = static_cast<int>(v.size()) - 1;
  while (low <= high) {
    int mid = low + (high - low) / 2;
    looks++;
    if (v[mid] == target) return mid;
    if (v[mid] < target) low = mid + 1;  // it's in the right half
    else high = mid - 1;                 // it's in the left half
  }
  return -1;
}

int main() {
  std::vector<int> evens;
  for (int i = 0; i < 1000000; i++) evens.push_back(i * 2);  // 0, 2, 4, ... sorted

  std::cout << "A sorted list of " << evens.size() << " even numbers. Type numbers to find (Ctrl+D to stop):\n";
  int target;
  std::vector<int> tries = {1999998, 777776, 13};
  bool typed = false;
  while (true) {
    if (std::cin >> target) typed = true;
    else if (!typed && !tries.empty()) { target = tries.back(); tries.pop_back(); }
    else break;

    int linLooks = 0, binLooks = 0;
    int at = linearSearch(evens, target, linLooks);
    binarySearch(evens, target, binLooks);
    std::cout << target << (at >= 0 ? " found at position " + std::to_string(at) : std::string(" not found"))
              << "\n  linear search looked " << linLooks << " times\n  binary search looked " << binLooks << " times\n";
  }

  // The standard library has binary search built in.
  bool has = std::binary_search(evens.begin(), evens.end(), 4242);
  std::cout << "std::binary_search for 4242: " << (has ? "found" : "not found") << "\n";
  return 0;
}
