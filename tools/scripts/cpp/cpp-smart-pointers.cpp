// @title Smart Pointers: unique_ptr and shared_ptr
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o smart && ./smart
// @keywords c++ smart pointers, unique_ptr, shared_ptr, make_unique, no memory leaks c++, use_count
// @about Shows unique_ptr (one owner) and shared_ptr (many owners) cleaning up memory by themselves.

#include <iostream>
#include <memory>
#include <string>
#include <vector>

class Spaceship {
public:
  explicit Spaceship(const std::string &name) : name_(name) {
    std::cout << "  Spaceship " << name_ << " built\n";
  }
  ~Spaceship() { std::cout << "  Spaceship " << name_ << " scrapped\n"; }
  void fly() const { std::cout << "  " << name_ << " zooms through space!\n"; }
private:
  std::string name_;
};

int main() {
  std::cout << "1. unique_ptr: only ONE owner at a time\n";
  {
    std::unique_ptr<Spaceship> ship = std::make_unique<Spaceship>("Falcon");
    ship->fly();
    // You can't copy a unique_ptr, but you can MOVE it to a new owner.
    std::unique_ptr<Spaceship> newOwner = std::move(ship);
    std::cout << "  old pointer is now " << (ship ? "full" : "empty") << "\n";
    newOwner->fly();
  }  // newOwner goes away here, so the ship is deleted automatically.

  std::cout << "\n2. shared_ptr: MANY owners, deleted when the last one is gone\n";
  std::shared_ptr<Spaceship> mothership = std::make_shared<Spaceship>("Mothership");
  std::cout << "  owners: " << mothership.use_count() << "\n";
  {
    std::vector<std::shared_ptr<Spaceship>> fleet;
    fleet.push_back(mothership);  // another owner
    fleet.push_back(mothership);  // and another
    std::cout << "  owners while in the fleet: " << mothership.use_count() << "\n";
  }
  std::cout << "  owners after the fleet is gone: " << mothership.use_count() << "\n";
  mothership.reset();  // let go of the last owner
  std::cout << "  (no delete needed anywhere!)\n";

  std::cout << "\n3. A list of unique_ptrs\n";
  std::vector<std::unique_ptr<Spaceship>> hangar;
  hangar.push_back(std::make_unique<Spaceship>("Scout"));
  hangar.push_back(std::make_unique<Spaceship>("Cargo"));
  for (const auto &s : hangar) s->fly();
  std::cout << "End of main:\n";
  return 0;
}
