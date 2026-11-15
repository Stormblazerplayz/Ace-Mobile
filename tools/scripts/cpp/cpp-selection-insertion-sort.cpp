// @title Selection Sort and Insertion Sort
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o simplesorts && ./simplesorts
// @keywords selection sort, insertion sort, sorting cards in hand, compare sorting algorithms, simple sorts c++
// @about Shows two simple sorts side by side: selection sort picks the smallest each time, insertion sort slides each card into place.

#include <iostream>
#include <string>
#include <utility>
#include <vector>

void print(const std::string &label, const std::vector<int> &v) {
  std::cout << label;
  for (int x : v) std::cout << x << " ";
  std::cout << "\n";
}

// Find the smallest of the unsorted part and swap it to the front of that part.
void selectionSort(std::vector<int> &v) {
  for (std::size_t i = 0; i < v.size(); i++) {
    std::size_t smallest = i;
    for (std::size_t j = i + 1; j < v.size(); j++) {
      if (v[j] < v[smallest]) smallest = j;
    }
    std::swap(v[i], v[smallest]);
    print("  picked " + std::to_string(v[i]) + ":\t", v);
  }
}

// Like sorting cards in your hand: take the next card and slide it left until it fits.
void insertionSort(std::vector<int> &v) {
  for (std::size_t i = 1; i < v.size(); i++) {
    int card = v[i];
    std::size_t j = i;
    while (j > 0 && v[j - 1] > card) {
      v[j] = v[j - 1];  // shift the bigger card right
      j--;
    }
    v[j] = card;
    print("  placed " + std::to_string(card) + ":\t", v);
  }
}

int main() {
  const std::vector<int> start = {64, 25, 12, 22, 11, 90, 3};

  std::vector<int> a = start;
  print("Selection sort on: ", a);
  selectionSort(a);

  std::vector<int> b = start;
  print("\nInsertion sort on: ", b);
  insertionSort(b);

  std::cout << "\nInsertion sort is very fast when the list is already almost sorted!\n";
  return 0;
}
