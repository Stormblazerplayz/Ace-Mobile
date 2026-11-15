// @title Virtual Robot Pet
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pet && ./pet
// @keywords virtual pet, tamagotchi game, feed play sleep, pet class with stats, take care of a pet
// @about Look after a little robot pet by charging, playing and fixing it, and keep its stats up for 15 turns.

#include <algorithm>
#include <iostream>
#include <string>

class RobotPet {
public:
  explicit RobotPet(std::string name) : name_(std::move(name)) {}

  void charge() { battery_ = std::min(100, battery_ + 30); fun_ -= 5; say("Bzzzt... battery recharging!"); }
  void play() { fun_ = std::min(100, fun_ + 25); battery_ -= 15; rust_ += 5; say("Wheee! Beep boop!"); }
  void oil() { rust_ = std::max(0, rust_ - 30); say("Ahh, squeaky clean gears."); }

  // Time passes: everything slowly gets worse.
  void tick() {
    battery_ -= 8;
    fun_ -= 6;
    rust_ += 4;
  }

  bool ok() const { return battery_ > 0 && fun_ > 0 && rust_ < 100; }

  void show() const {
    std::cout << "\n" << name_ << " " << face() << "\n";
    bar("Battery", battery_);
    bar("Fun    ", fun_);
    bar("Rust   ", rust_);
  }

private:
  std::string name_;
  int battery_ = 70, fun_ = 70, rust_ = 10;

  std::string face() const {
    if (!ok()) return "[x_x]";
    if (battery_ < 30 || fun_ < 30 || rust_ > 70) return "[o_o;]";
    return "[^_^]";
  }
  void say(const std::string &s) const { std::cout << name_ << ": " << s << "\n"; }
  static void bar(const char *label, int v) {
    int n = std::max(0, std::min(100, v)) / 10;
    std::cout << "  " << label << " [" << std::string(n, '#') << std::string(10 - n, ' ') << "] " << v << "\n";
  }
};

int main() {
  std::cout << "Name your robot pet: ";
  std::string name;
  if (!(std::cin >> name)) name = "Bolt";
  RobotPet pet(name);

  for (int turn = 1; turn <= 15 && pet.ok(); turn++) {
    pet.show();
    std::cout << "Turn " << turn << "/15: 1 Charge  2 Play  3 Oil  > ";
    int c;
    if (!(std::cin >> c)) break;
    if (c == 1) pet.charge();
    else if (c == 2) pet.play();
    else if (c == 3) pet.oil();
    pet.tick();
  }
  pet.show();
  std::cout << (pet.ok() ? "Your pet is happy and healthy. Great job!\n" : "Oh no, your pet shut down. Try again!\n");
  return 0;
}
