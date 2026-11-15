// @title Doubly Linked List Music Playlist
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o playlist && ./playlist
// @keywords doubly linked list, prev and next pointers, playlist next previous, linked list both ways
// @about A music playlist built as a doubly linked list so you can skip forward and back through songs.

#include <iostream>
#include <string>

struct Song {
  std::string title;
  Song *prev = nullptr;
  Song *next = nullptr;
};

class Playlist {
public:
  Playlist() = default;
  Playlist(const Playlist &) = delete;
  Playlist &operator=(const Playlist &) = delete;
  ~Playlist() {
    while (head_) {
      Song *next = head_->next;
      delete head_;
      head_ = next;
    }
  }

  void add(const std::string &title) {
    Song *s = new Song{title};
    if (!tail_) {
      head_ = tail_ = current_ = s;
    } else {
      tail_->next = s;  // old last song points forward to the new one
      s->prev = tail_;  // and the new one points back
      tail_ = s;
    }
  }

  void next() {
    if (current_ && current_->next) current_ = current_->next;
    else std::cout << "(end of playlist)\n";
  }

  void previous() {
    if (current_ && current_->prev) current_ = current_->prev;
    else std::cout << "(already at the first song)\n";
  }

  void show() const {
    for (Song *s = head_; s; s = s->next) {
      std::cout << (s == current_ ? " >> " : "    ") << s->title << "\n";
    }
  }

  void showBackwards() const {
    std::cout << "Backwards:";
    for (Song *s = tail_; s; s = s->prev) std::cout << " " << s->title << " |";
    std::cout << "\n";
  }

private:
  Song *head_ = nullptr;
  Song *tail_ = nullptr;
  Song *current_ = nullptr;
};

int main() {
  Playlist list;
  for (const char *t : {"Eye of the Tiger", "Thunderstruck", "Believer", "Radioactive", "Levels"}) list.add(t);

  std::cout << "Commands: n (next), p (previous), b (backwards), q (quit)\n";
  list.show();
  char c;
  while (std::cin >> c && c != 'q') {
    if (c == 'n') list.next();
    else if (c == 'p') list.previous();
    else if (c == 'b') { list.showBackwards(); continue; }
    list.show();
  }
  return 0;
}
