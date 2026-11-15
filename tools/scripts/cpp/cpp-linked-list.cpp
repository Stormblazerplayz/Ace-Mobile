// @title Singly Linked List from Scratch
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o linkedlist && ./linkedlist
// @keywords linked list c++, singly linked list, node next pointer, insert delete linked list, reverse linked list
// @about Builds a linked list of train cars by hand, with add to front and back, remove, search, reverse and safe cleanup.

#include <iostream>
#include <string>

// Each Node holds one value and a pointer to the next node.
struct Node {
  std::string value;
  Node *next;
};

class LinkedList {
public:
  ~LinkedList() {  // delete every node so no memory leaks
    while (head_) {
      Node *old = head_;
      head_ = head_->next;
      delete old;
    }
  }
  LinkedList() = default;
  LinkedList(const LinkedList &) = delete;             // copying would delete nodes twice,
  LinkedList &operator=(const LinkedList &) = delete;  // so we turn it off

  void pushFront(const std::string &v) { head_ = new Node{v, head_}; size_++; }

  void pushBack(const std::string &v) {
    Node *n = new Node{v, nullptr};
    if (!head_) { head_ = n; }
    else {
      Node *cur = head_;
      while (cur->next) cur = cur->next;  // walk to the last node
      cur->next = n;
    }
    size_++;
  }

  bool remove(const std::string &v) {
    Node **link = &head_;  // the pointer that points at the current node
    while (*link) {
      if ((*link)->value == v) {
        Node *doomed = *link;
        *link = doomed->next;  // skip over it
        delete doomed;
        size_--;
        return true;
      }
      link = &(*link)->next;
    }
    return false;
  }

  bool contains(const std::string &v) const {
    for (Node *cur = head_; cur; cur = cur->next) if (cur->value == v) return true;
    return false;
  }

  void reverse() {
    Node *prev = nullptr, *cur = head_;
    while (cur) {
      Node *next = cur->next;
      cur->next = prev;  // flip the arrow
      prev = cur;
      cur = next;
    }
    head_ = prev;
  }

  void print() const {
    std::cout << "[engine]";
    for (Node *cur = head_; cur; cur = cur->next) std::cout << "->[" << cur->value << "]";
    std::cout << "  (" << size_ << " cars)\n";
  }

private:
  Node *head_ = nullptr;
  int size_ = 0;
};

int main() {
  LinkedList train;
  train.pushBack("coal");
  train.pushBack("passengers");
  train.pushBack("mail");
  train.pushFront("dining");
  train.print();

  std::cout << "Has mail car? " << (train.contains("mail") ? "yes" : "no") << "\n";
  train.remove("passengers");
  std::cout << "After removing passengers: ";
  train.print();

  train.reverse();
  std::cout << "Reversed: ";
  train.print();
  return 0;
}
