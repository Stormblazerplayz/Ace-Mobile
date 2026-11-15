// @title Build Your Own Vector (Dynamic Array)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o myvector && ./myvector
// @keywords dynamic array, how vector works, grow array capacity, my own vector class, rule of three
// @about Builds a simple growing array like std::vector, doubling its capacity when it fills up.

#include <iostream>
#include <stdexcept>

class IntVector {
public:
  IntVector() = default;
  ~IntVector() { delete[] data_; }
  // Copying needs its own memory, or two vectors would share (and double-delete) one array.
  IntVector(const IntVector &other) : data_(new int[other.capacity_]), size_(other.size_), capacity_(other.capacity_) {
    for (std::size_t i = 0; i < size_; i++) data_[i] = other.data_[i];
  }
  IntVector &operator=(IntVector other) {  // copy-and-swap: simple and safe
    std::swap(data_, other.data_);
    std::swap(size_, other.size_);
    std::swap(capacity_, other.capacity_);
    return *this;
  }

  void push_back(int v) {
    if (size_ == capacity_) grow();
    data_[size_++] = v;
  }

  int &operator[](std::size_t i) {
    if (i >= size_) throw std::out_of_range("index too big");
    return data_[i];
  }

  std::size_t size() const { return size_; }
  std::size_t capacity() const { return capacity_; }

private:
  int *data_ = nullptr;
  std::size_t size_ = 0;      // how many are used
  std::size_t capacity_ = 0;  // how many fit before we need more room

  void grow() {
    std::size_t newCap = capacity_ == 0 ? 1 : capacity_ * 2;  // double it
    int *bigger = new int[newCap];
    for (std::size_t i = 0; i < size_; i++) bigger[i] = data_[i];  // copy the old items
    delete[] data_;
    data_ = bigger;
    std::cout << "  grew from " << capacity_ << " to " << newCap << " slots\n";
    capacity_ = newCap;
  }
};

int main() {
  IntVector v;
  for (int i = 1; i <= 10; i++) {
    v.push_back(i * i);
    std::cout << "added " << i * i << " (size " << v.size() << ", capacity " << v.capacity() << ")\n";
  }

  IntVector copy = v;
  copy[0] = 999;
  std::cout << "\nv[0] = " << v[0] << ", copy[0] = " << copy[0] << " (separate memory)\n";

  try {
    std::cout << v[50] << "\n";
  } catch (const std::out_of_range &e) {
    std::cout << "v[50] -> error: " << e.what() << "\n";
  }
  return 0;
}
