// @title Bubble Sort Step by Step
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bubble && ./bubble
// @keywords bubble sort, sorting algorithm c++, swap neighbours sort, sort step by step, early exit bubble sort
// @about Sorts numbers with bubble sort and prints every pass so you can watch the big numbers bubble to the end.

#include <iostream>
#include <utility>
#include <vector>

void print(const std::vector<int> &v) {
  for (int x : v) std::cout << x << " ";
  std::cout << "\n";
}

int main() {
  std::vector<int> nums = {29, 10, 14, 37, 13, 5, 42, 1};
  std::cout << "Start:   ";
  print(nums);

  int swaps = 0, compares = 0;
  for (std::size_t pass = 0; pass + 1 < nums.size(); pass++) {
    bool swapped = false;
    // After each pass, the biggest unsorted number has "bubbled" to the end, so check one less.
    for (std::size_t i = 0; i + 1 < nums.size() - pass; i++) {
      compares++;
      if (nums[i] > nums[i + 1]) {
        std::swap(nums[i], nums[i + 1]);
        swaps++;
        swapped = true;
      }
    }
    std::cout << "Pass " << pass + 1 << ":  ";
    print(nums);
    if (!swapped) {  // no swaps means it's already sorted: stop early
      std::cout << "No swaps, so we're done early!\n";
      break;
    }
  }
  std::cout << "Sorted with " << compares << " comparisons and " << swaps << " swaps.\n";
  std::cout << "Bubble sort is easy but slow for big lists (it does about n x n steps).\n";
  return 0;
}
