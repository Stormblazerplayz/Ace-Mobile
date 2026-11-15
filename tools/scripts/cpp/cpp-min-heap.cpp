// @title Min Heap from Scratch
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o heap && ./heap
// @keywords min heap, binary heap array, sift up sift down, heap insert extract, heapsort
// @about Builds a min heap in a vector where the smallest number is always on top, and uses it to sort numbers.

#include <iostream>
#include <stdexcept>
#include <utility>
#include <vector>

class MinHeap {
public:
  void push(int v) {
    data_.push_back(v);
    siftUp(data_.size() - 1);  // bubble the new number up to its place
  }

  int pop() {
    if (data_.empty()) throw std::runtime_error("heap is empty");
    int smallest = data_[0];
    data_[0] = data_.back();  // move the last number to the top...
    data_.pop_back();
    if (!data_.empty()) siftDown(0);  // ...and sink it down to its place
    return smallest;
  }

  bool empty() const { return data_.empty(); }
  const std::vector<int> &raw() const { return data_; }

private:
  // In an array heap: children of i are 2i+1 and 2i+2, parent of i is (i-1)/2.
  std::vector<int> data_;

  void siftUp(std::size_t i) {
    while (i > 0) {
      std::size_t parent = (i - 1) / 2;
      if (data_[parent] <= data_[i]) break;
      std::swap(data_[parent], data_[i]);
      i = parent;
    }
  }

  void siftDown(std::size_t i) {
    while (true) {
      std::size_t left = 2 * i + 1, right = 2 * i + 2, smallest = i;
      if (left < data_.size() && data_[left] < data_[smallest]) smallest = left;
      if (right < data_.size() && data_[right] < data_[smallest]) smallest = right;
      if (smallest == i) break;
      std::swap(data_[i], data_[smallest]);
      i = smallest;
    }
  }
};

int main() {
  MinHeap heap;
  for (int v : {42, 7, 19, 3, 88, 25, 1, 60}) {
    heap.push(v);
    std::cout << "push " << v << " -> array:";
    for (int x : heap.raw()) std::cout << " " << x;
    std::cout << "\n";
  }

  // Popping gives the numbers smallest first. That's "heapsort"!
  std::cout << "\nPopping:";
  while (!heap.empty()) std::cout << " " << heap.pop();
  std::cout << "\n";
  return 0;
}
