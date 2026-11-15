// @title Classes and Objects: a Pet
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pets && ./pets
// @keywords c++ classes and objects, c++ class example, c++ pet class, learn c++ classes, c++ object oriented
// @about Makes a Pet class with a name, hunger and happiness, then creates two pets and plays with them.

#include <iostream>
#include <string>

// A class is a blueprint. Each Pet we make from it is an "object".
class Pet {
public:
  // The constructor runs when a new Pet is made.
  Pet(const std::string &name, const std::string &species)
      : name_(name), species_(species) {}

  void feed() {
    hunger_ = clamp(hunger_ - 30);
    std::cout << name_ << " munches some food. Yum!\n";
  }

  void play() {
    happiness_ = clamp(happiness_ + 20);
    hunger_ = clamp(hunger_ + 10);  // playing makes you hungry
    std::cout << name_ << " plays fetch!\n";
  }

  void showStatus() const {
    std::cout << name_ << " the " << species_ << " - hunger: " << hunger_
              << "/100, happiness: " << happiness_ << "/100";
    if (hunger_ > 70) std::cout << " (very hungry!)";
    std::cout << "\n";
  }

  const std::string &getName() const { return name_; }

private:
  // Private data: only the Pet's own functions can change it.
  std::string name_;
  std::string species_;
  int hunger_ = 50;
  int happiness_ = 50;

  // Keep a value between 0 and 100.
  static int clamp(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }
};

int main() {
  // Two different objects made from the same class.
  Pet dog("Biscuit", "dog");
  Pet cat("Pixel", "cat");

  dog.showStatus();
  cat.showStatus();
  std::cout << "\n";

  dog.play();
  dog.play();
  cat.feed();
  std::cout << "\n";

  dog.showStatus();
  cat.showStatus();

  std::cout << "\nRemember to feed " << dog.getName() << " soon!\n";
  return 0;
}
