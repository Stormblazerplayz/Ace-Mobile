// @title Quick Sort with a Pivot
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o quicksort && ./quicksort
// @keywords quick sort, quicksort pivot, partition array, fast sorting algorithm, lomuto partition
// @about Sorts a list with quick sort: pick a pivot, put smaller numbers left and bigger right, then repeat on each side.

#include <iostream>
#include <utility>
#include <vector>

int steps = 0;

void print(const std::vector<int> &v) {
  for (int x : v) std::cout << x << " ";
  std::cout << "\n";
}

// Lomuto partition: uses the last number as the pivot and returns where the pivot ends up.
int partition(std::vector<int> &v, int low, int high) {
  int pivot = v[high];
  int wall = low;  // everything left of the wall is smaller than the pivot
  for (int i = low; i < high; i++) {
    if (v[i] < pivot) std::swap(v[i], v[wall++]);
  }
  std::swap(v[wall], v[high]);  // put the pivot right after the small numbers
  return wall;
}

void quickSort(std::vector<int> &v, int low, int high) {
  if (low >= high) return;
  int p = partition(v, low, high);
  std::cout << "Step " << ++steps << ", pivot " << v[p] << ": ";
  print(v);
  quickSort(v, low, p - 1);   // sort the small side
  quickSort(v, p + 1, high);  // sort the big side
}

int main() {
  std::vector<int> nums = {10, 80, 30, 90, 40, 50, 70, 25, 5};
  std::cout << "Start:              ";
  print(nums);
  quickSort(nums, 0, static_cast<int>(nums.size()) - 1);
  std::cout << "Sorted:             ";
  print(nums);
  std::cout << "Quick sort is usually very fast, which is why std::sort uses a version of it.\n";
  return 0;
}
