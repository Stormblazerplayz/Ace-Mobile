// @title What to Build First (Topological Sort)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o buildorder && ./buildorder
// @keywords topological sort, dependency order, kahn algorithm, directed graph c++, build order tasks
// @about Works out an order to do robot-building steps so every step comes after the steps it depends on.

#include <iostream>
#include <map>
#include <queue>
#include <string>
#include <vector>

int main() {
  // "A needs B" means B must happen before A.
  std::vector<std::pair<std::string, std::string>> needs = {
    {"wire motors", "mount motors"},    {"mount motors", "cut chassis"},
    {"add battery", "cut chassis"},     {"upload code", "write code"},
    {"test drive", "upload code"},      {"test drive", "wire motors"},
    {"test drive", "add battery"},      {"upload code", "wire motors"},
  };

  std::map<std::string, std::vector<std::string>> unlocks;  // B -> things that can happen after B
  std::map<std::string, int> waitingOn;                     // how many steps each one still needs
  for (const auto &[after, before] : needs) {
    unlocks[before].push_back(after);
    waitingOn[after]++;
    waitingOn[before] += 0;  // make sure every step is in the map
  }

  // Kahn's method: start with steps that need nothing, then "unlock" the rest one by one.
  std::queue<std::string> ready;
  for (const auto &[step, count] : waitingOn) if (count == 0) ready.push(step);

  std::vector<std::string> order;
  while (!ready.empty()) {
    std::string step = ready.front();
    ready.pop();
    order.push_back(step);
    for (const auto &next : unlocks[step]) {
      if (--waitingOn[next] == 0) ready.push(next);  // all its needs are done
    }
  }

  if (order.size() != waitingOn.size()) {
    std::cout << "Impossible: some steps need each other in a circle!\n";
    return 0;
  }
  std::cout << "Build order:\n";
  for (std::size_t i = 0; i < order.size(); i++) std::cout << "  " << i + 1 << ". " << order[i] << "\n";
  return 0;
}
