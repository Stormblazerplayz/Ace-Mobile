// @title Merge Sort (Divide and Conquer)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o mergesort && ./mergesort
// @keywords merge sort, divide and conquer, recursive sort c++, merge two sorted lists, n log n sorting
// @about Splits a list in half again and again, then merges the sorted halves back together, printing each merge.

#include <iostream>
#include <string>
#include <vector>

void print(const std::vector<int> &v, std::size_t from, std::size_t to) {
  std::cout << "[";
  for (std::size_t i = from; i < to; i++) std::cout << (i > from ? " " : "") << v[i];
  std::cout << "]";
}

// Sorts v[from..to) (from is included, to is not).
void mergeSort(std::vector<int> &v, std::size_t from, std::size_t to, int depth) {
  if (to - from <= 1) return;  // one number is already sorted
  std::size_t mid = from + (to - from) / 2;
  mergeSort(v, from, mid, depth + 1);  // sort the left half
  mergeSort(v, mid, to, depth + 1);    // sort the right half

  // Merge: keep taking the smaller front item of the two halves.
  std::vector<int> merged;
  std::size_t i = from, j = mid;
  while (i < mid && j < to) merged.push_back(v[i] <= v[j] ? v[i++] : v[j++]);
  while (i < mid) merged.push_back(v[i++]);
  while (j < to) merged.push_back(v[j++]);

  std::cout << std::string(depth * 2, ' ') << "merge ";
  print(v, from, mid);
  std::cout << " + ";
  print(v, mid, to);
  for (std::size_t k = 0; k < merged.size(); k++) v[from + k] = merged[k];
  std::cout << " -> ";
  print(v, from, to);
  std::cout << "\n";
}

int main() {
  std::vector<int> nums = {38, 27, 43, 3, 9, 82, 10, 15};
  std::cout << "Start: ";
  print(nums, 0, nums.size());
  std::cout << "\n\n";
  mergeSort(nums, 0, nums.size(), 0);
  std::cout << "\nSorted: ";
  print(nums, 0, nums.size());
  std::cout << "\n";
  return 0;
}
