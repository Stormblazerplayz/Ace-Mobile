// @title Abstract Classes and Interfaces
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o devices && ./devices
// @keywords abstract class c++, pure virtual function, c++ interface, = 0 function, cannot instantiate abstract
// @about Defines a Device interface with pure virtual functions, then makes a lamp, a fan and a robot that all follow it.

#include <iostream>
#include <memory>
#include <string>
#include <vector>

// An interface: it only says WHAT a device can do. "= 0" means "no body here, children must write it".
class Device {
public:
  virtual ~Device() = default;
  virtual std::string name() const = 0;
  virtual void turnOn() = 0;
  virtual void turnOff() = 0;
};
// You can't write "Device d;" because Device is abstract (it has = 0 functions).

class Lamp : public Device {
public:
  std::string name() const override { return "Lamp"; }
  void turnOn() override { std::cout << "The lamp glows warm yellow.\n"; }
  void turnOff() override { std::cout << "The lamp clicks off.\n"; }
};

class Fan : public Device {
public:
  std::string name() const override { return "Fan"; }
  void turnOn() override {
    speed_ = 3;
    std::cout << "The fan spins at speed " << speed_ << ". Whoosh!\n";
  }
  void turnOff() override {
    speed_ = 0;
    std::cout << "The fan slows down and stops.\n";
  }
private:
  int speed_ = 0;
};

class Robot : public Device {
public:
  std::string name() const override { return "Robot"; }
  void turnOn() override { std::cout << "BEEP BOOP. Robot online. Hello, human.\n"; }
  void turnOff() override { std::cout << "Robot powering down... goodnight.\n"; }
};

// This function works with ANY device, even ones invented later.
void runRoutine(Device &d) {
  std::cout << "[" << d.name() << "]\n";
  d.turnOn();
  d.turnOff();
}

int main() {
  std::vector<std::unique_ptr<Device>> room;
  room.push_back(std::make_unique<Lamp>());
  room.push_back(std::make_unique<Fan>());
  room.push_back(std::make_unique<Robot>());

  for (auto &device : room) runRoutine(*device);
  return 0;
}
