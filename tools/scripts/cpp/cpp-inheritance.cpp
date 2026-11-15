// @title Inheritance: Game Characters
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o inherit && ./inherit
// @keywords c++ inheritance, base class derived class, protected members, c++ class hierarchy, is-a relationship
// @about Builds Warrior and Wizard classes on top of a Character base class so they share health and names.

#include <iostream>
#include <string>

// The base class has what EVERY character has.
class Character {
public:
  Character(const std::string &name, int health) : name_(name), health_(health) {}

  void takeDamage(int amount) {
    health_ -= amount;
    if (health_ < 0) health_ = 0;
    std::cout << name_ << " takes " << amount << " damage (" << health_ << " HP left)\n";
  }

  bool isAlive() const { return health_ > 0; }
  const std::string &name() const { return name_; }

protected:
  // protected: hidden from outside code, but child classes can use it.
  std::string name_;
  int health_;
};

// A Warrior IS a Character, plus armor and a sword.
class Warrior : public Character {
public:
  Warrior(const std::string &name) : Character(name, 120) {}

  void swingSword(Character &target) {
    std::cout << name_ << " swings a sword!\n";
    target.takeDamage(25);
  }
};

// A Wizard IS a Character, plus mana for spells.
class Wizard : public Character {
public:
  Wizard(const std::string &name) : Character(name, 80) {}

  void castFireball(Character &target) {
    if (mana_ < 30) {
      std::cout << name_ << " is out of mana!\n";
      return;
    }
    mana_ -= 30;
    std::cout << name_ << " casts FIREBALL! (mana " << mana_ << ")\n";
    target.takeDamage(40);
  }

private:
  int mana_ = 100;
};

int main() {
  Warrior hero("Brick");
  Wizard rival("Zappo");

  int round = 1;
  while (hero.isAlive() && rival.isAlive()) {
    std::cout << "\n-- Round " << round++ << " --\n";
    hero.swingSword(rival);
    if (rival.isAlive()) rival.castFireball(hero);
  }
  std::cout << "\n" << (hero.isAlive() ? hero.name() : rival.name()) << " wins!\n";
  return 0;
}
