// @title Ticket Line Simulation with std::queue
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o ticketline && ./ticketline
// @keywords std queue, first in first out, queue simulation, waiting line c++, fifo customers
// @about Simulates people joining a ticket line and being served first come, first served, using std::queue.

#include <iostream>
#include <queue>
#include <random>
#include <string>

struct Person {
  std::string name;
  int arrivedAt;
};

int main() {
  const std::string NAMES[] = {"Ava", "Ben", "Cai", "Dee", "Eli", "Fay", "Gus", "Hana", "Ivo", "Jun"};
  std::mt19937 rng(7);
  std::uniform_int_distribution<int> coin(0, 2);

  std::queue<Person> line;
  int nextName = 0;
  int served = 0;
  int totalWait = 0;

  for (int minute = 1; minute <= 12; minute++) {
    // Sometimes 0, 1 or 2 people arrive.
    int arrivals = coin(rng);
    for (int a = 0; a < arrivals && nextName < 10; a++) {
      line.push({NAMES[nextName++], minute});  // join at the BACK
      std::cout << "Minute " << minute << ": " << line.back().name << " joins the line\n";
    }

    // The ticket booth serves one person per minute, from the FRONT.
    if (!line.empty()) {
      Person p = line.front();
      line.pop();
      int waited = minute - p.arrivedAt;
      totalWait += waited;
      served++;
      std::cout << "Minute " << minute << ": served " << p.name << " (waited " << waited << " min)\n";
    }
    std::cout << "           people waiting: " << line.size() << "\n";
  }

  std::cout << "\nServed " << served << " people";
  if (served > 0) std::cout << ", average wait " << static_cast<double>(totalWait) / served << " min";
  std::cout << ". Still in line: " << line.size() << "\n";
  return 0;
}
