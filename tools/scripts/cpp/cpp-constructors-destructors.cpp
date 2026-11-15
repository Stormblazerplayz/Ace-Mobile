// @title Constructors and Destructors
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o lifecycle && ./lifecycle
// @keywords c++ constructor, c++ destructor, object lifetime, initializer list c++, raii example
// @about Shows when objects are born and when they are destroyed, using a torch that lights up and goes out.

#include <iostream>
#include <string>

class Torch {
public:
  // Default constructor: runs when you make a Torch with no info.
  Torch() : Torch("plain torch", 10) {}

  // Constructor with values. The part after : is the "initializer list".
  Torch(const std::string &name, int fuel) : name_(name), fuel_(fuel) {
    std::cout << "  [+] " << name_ << " is lit (" << fuel_ << " fuel)\n";
  }

  // Destructor: runs automatically when the object goes away.
  ~Torch() {
    std::cout << "  [-] " << name_ << " goes out\n";
  }

  void burn(int amount) {
    fuel_ = fuel_ > amount ? fuel_ - amount : 0;
    std::cout << "  " << name_ << " burns, fuel left: " << fuel_ << "\n";
  }

private:
  std::string name_;
  int fuel_;
};

int main() {
  std::cout << "Entering the cave...\n";
  Torch main("main torch", 50);

  {  // curly braces make a new "scope"
    std::cout << "Entering a side tunnel...\n";
    Torch small("tiny torch", 5);
    small.burn(3);
    std::cout << "Leaving the side tunnel...\n";
  }  // small is destroyed right here, automatically!

  Torch spare;  // uses the default constructor
  main.burn(20);

  std::cout << "Leaving the cave...\n";
  return 0;
  // main and spare are destroyed now, in the opposite order they were made.
}
