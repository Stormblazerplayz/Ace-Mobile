// @title Queue Made from Two Stacks
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o twostacks && ./twostacks
// @keywords queue using two stacks, interview puzzle c++, inbox outbox stacks, amortized queue
// @about Solves a classic puzzle: makes a first-in-first-out queue using only two last-in-first-out stacks.

#include <iostream>
#include <stack>
#include <stdexcept>

class TwoStackQueue {
public:
  void push(int v) { inbox_.push(v); }

  int pop() {
    if (outbox_.empty()) {
      // Pour the inbox into the outbox. That flips the order, so the oldest is on top!
      while (!inbox_.empty()) {
        outbox_.push(inbox_.top());
        inbox_.pop();
      }
    }
    if (outbox_.empty()) throw std::runtime_error("queue is empty");
    int v = outbox_.top();
    outbox_.pop();
    return v;
  }

  bool empty() const { return inbox_.empty() && outbox_.empty(); }
  std::size_t inboxSize() const { return inbox_.size(); }
  std::size_t outboxSize() const { return outbox_.size(); }

private:
  std::stack<int> inbox_, outbox_;
};

int main() {
  TwoStackQueue q;
  for (int i = 1; i <= 4; i++) q.push(i);
  std::cout << "Pushed 1 2 3 4. inbox=" << q.inboxSize() << " outbox=" << q.outboxSize() << "\n";

  std::cout << "pop -> " << q.pop() << "  (inbox=" << q.inboxSize() << " outbox=" << q.outboxSize() << ")\n";
  q.push(5);
  q.push(6);
  std::cout << "Pushed 5 6.\n";
  std::cout << "Popping the rest:";
  while (!q.empty()) std::cout << " " << q.pop();
  std::cout << "\nSame order they went in: first in, first out!\n";
  return 0;
}
