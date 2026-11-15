// @title Homework Planner with a Priority Queue
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o planner && ./planner
// @keywords priority queue, std priority_queue, most urgent first, heap c++, task scheduler c++
// @about Keeps homework in a priority queue so the most urgent task always comes out first.

#include <iostream>
#include <queue>
#include <string>
#include <vector>

struct Task {
  std::string name;
  int daysUntilDue;
  int priority;  // 1 = low, 3 = high
};

// Decides which task is "less urgent". The priority_queue puts the MOST urgent on top.
struct LessUrgent {
  bool operator()(const Task &a, const Task &b) const {
    if (a.daysUntilDue != b.daysUntilDue) return a.daysUntilDue > b.daysUntilDue;  // sooner = more urgent
    return a.priority < b.priority;  // same day: higher priority first
  }
};

int main() {
  std::priority_queue<Task, std::vector<Task>, LessUrgent> todo;
  todo.push({"Science poster", 5, 2});
  todo.push({"Math worksheet", 1, 2});
  todo.push({"Read chapter 4", 3, 1});
  todo.push({"Spelling test study", 1, 3});
  todo.push({"Arduino project", 7, 3});

  std::cout << "Add a task as: name_without_spaces days priority  (or 'done')\n";
  std::string name;
  int days, prio;
  while (std::cin >> name && name != "done" && std::cin >> days >> prio) {
    todo.push({name, days, prio});
    std::cout << "Added " << name << "\n";
  }

  std::cout << "\nDo your homework in this order:\n";
  int step = 1;
  while (!todo.empty()) {
    const Task &t = todo.top();  // the most urgent one
    std::cout << step++ << ". " << t.name << " (due in " << t.daysUntilDue << " days, priority " << t.priority << ")\n";
    todo.pop();
  }
  return 0;
}
