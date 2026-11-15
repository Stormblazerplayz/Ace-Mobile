// @title Circular Queue (Ring Buffer)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o ringqueue && ./ringqueue
// @keywords circular queue, ring buffer c++, fifo queue array, enqueue dequeue, wrap around index
// @about Builds a fixed-size queue whose positions wrap around in a circle, the trick used for keyboard and serial buffers.

#include <array>
#include <iostream>

template <typename T, std::size_t N>
class RingQueue {
public:
  bool enqueue(const T &item) {
    if (full()) return false;
    data_[tail_] = item;
    tail_ = (tail_ + 1) % N;  // % N wraps back to 0 at the end
    count_++;
    return true;
  }

  bool dequeue(T &out) {
    if (empty()) return false;
    out = data_[head_];
    head_ = (head_ + 1) % N;
    count_--;
    return true;
  }

  bool empty() const { return count_ == 0; }
  bool full() const { return count_ == N; }

  void draw() const {
    std::cout << "  slots: ";
    for (std::size_t i = 0; i < N; i++) {
      bool used = (i - head_ + N) % N < count_;  // is slot i between head and tail?
      std::cout << "[" << (used ? std::to_string(data_[i]) : std::string(" ")) << "]";
    }
    std::cout << "  head=" << head_ << " tail=" << tail_ << " count=" << count_ << "\n";
  }

private:
  std::array<T, N> data_{};
  std::size_t head_ = 0;  // where we take from
  std::size_t tail_ = 0;  // where we add to
  std::size_t count_ = 0;
};

int main() {
  RingQueue<int, 5> q;
  std::cout << "Add 1..4:\n";
  for (int i = 1; i <= 4; i++) q.enqueue(i);
  q.draw();

  int x;
  std::cout << "Take two out:\n";
  q.dequeue(x); std::cout << "  got " << x << "\n";
  q.dequeue(x); std::cout << "  got " << x << "\n";
  q.draw();

  std::cout << "Add 5, 6, 7 (watch them wrap around to the start):\n";
  for (int i = 5; i <= 7; i++) q.enqueue(i);
  q.draw();
  std::cout << "Try to add 8 when full: " << (q.enqueue(8) ? "added" : "queue is full!") << "\n";

  std::cout << "Empty it out in order:";
  while (q.dequeue(x)) std::cout << " " << x;
  std::cout << "\n";
  return 0;
}
