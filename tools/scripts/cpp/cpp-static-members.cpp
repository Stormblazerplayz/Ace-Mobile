// @title Static Members: Shared by Every Object
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o statics && ./statics
// @keywords c++ static member, static variable class, count objects c++, static function, inline static
// @about Uses a static counter shared by all Enemy objects to count how many exist and give each a unique ID.

#include <iostream>
#include <string>

class Enemy {
public:
  explicit Enemy(const std::string &type) : type_(type), id_(nextId_++) {
    alive_++;
    std::cout << "Spawned " << type_ << " #" << id_ << " (alive: " << alive_ << ")\n";
  }
  ~Enemy() {
    alive_--;
    std::cout << type_ << " #" << id_ << " defeated (alive: " << alive_ << ")\n";
  }

  // A static function belongs to the class, not to one object.
  static int aliveCount() { return alive_; }

private:
  std::string type_;
  int id_;
  // "static" = ONE copy shared by every Enemy. "inline" lets us set it right here (C++17).
  inline static int alive_ = 0;
  inline static int nextId_ = 1;
};

// A static variable inside a function remembers its value between calls.
int callCounter() {
  static int calls = 0;
  return ++calls;
}

int main() {
  std::cout << "Enemies at start: " << Enemy::aliveCount() << "\n";
  Enemy goblin("goblin");
  {
    Enemy bat("bat");
    Enemy slime("slime");
    std::cout << "Enemies in the cave: " << Enemy::aliveCount() << "\n";
  }
  Enemy troll("troll");
  std::cout << "Enemies now: " << Enemy::aliveCount() << "\n\n";

  for (int i = 0; i < 3; i++) std::cout << "callCounter() = " << callCounter() << "\n";
  return 0;
}
