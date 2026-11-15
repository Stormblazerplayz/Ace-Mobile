// @title Copy vs Move (std::move)
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o move && ./move
// @keywords c++ move semantics, std move, move constructor, copy constructor, rvalue reference
// @about Shows the difference between copying a big object and moving it, with a class that prints when each happens.

#include <iostream>
#include <string>
#include <utility>
#include <vector>

class Level {
public:
  explicit Level(const std::string &name) : name_(name), tiles_(100000, 1) {
    std::cout << "  made " << name_ << "\n";
  }
  // Copy constructor: makes a full duplicate (slow for big data).
  Level(const Level &other) : name_(other.name_ + " copy"), tiles_(other.tiles_) {
    std::cout << "  COPIED " << other.name_ << " (" << tiles_.size() << " tiles duplicated)\n";
  }
  // Move constructor: steals the insides (fast!). The old object is left empty.
  Level(Level &&other) noexcept : name_(std::move(other.name_)), tiles_(std::move(other.tiles_)) {
    std::cout << "  MOVED " << name_ << " (no tiles duplicated)\n";
  }
  Level &operator=(const Level &) = default;
  Level &operator=(Level &&) = default;

  std::size_t tileCount() const { return tiles_.size(); }
  const std::string &name() const { return name_; }

private:
  std::string name_;
  std::vector<int> tiles_;
};

int main() {
  std::cout << "Making a level:\n";
  Level forest("forest");

  std::cout << "\nCopying it:\n";
  Level forestCopy = forest;  // both now have 100000 tiles

  std::cout << "\nMoving it:\n";
  Level moved = std::move(forest);  // std::move says "I'm done with forest, take its stuff"
  std::cout << "  forest now has " << forest.tileCount() << " tiles (it was emptied)\n";
  std::cout << "  moved has " << moved.tileCount() << " tiles\n";

  std::cout << "\nPutting levels in a vector:\n";
  std::vector<Level> world;
  world.reserve(2);  // room for 2 so the vector doesn't have to shuffle things around
  world.push_back(Level("cave"));      // a temporary is moved in automatically
  world.push_back(std::move(moved));   // moved in on purpose
  for (const Level &l : world) std::cout << "  world has: " << l.name() << "\n";
  return 0;
}
