// @title To-Do List that Saves to a File
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o todo && ./todo (it keeps todo.txt next to the program)
// @keywords todo list app c++, vector of tasks, save and load list file, checklist program, erase from vector
// @about A to-do list where you can add, tick off, delete and list tasks, saved in todo.txt so it's still there next time.

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

struct Task {
  bool done;
  std::string text;
};

const std::string FILE_NAME = "todo.txt";

std::vector<Task> load() {
  std::vector<Task> tasks;
  std::ifstream in(FILE_NAME);
  std::string line;
  while (std::getline(in, line)) {
    if (line.size() < 2) continue;
    tasks.push_back({line[0] == 'x', line.substr(2)});  // saved as "x text" or "- text"
  }
  return tasks;
}

void save(const std::vector<Task> &tasks) {
  std::ofstream out(FILE_NAME);
  for (const auto &t : tasks) out << (t.done ? 'x' : '-') << ' ' << t.text << '\n';
}

void list(const std::vector<Task> &tasks) {
  if (tasks.empty()) std::cout << "  (nothing to do!)\n";
  for (std::size_t i = 0; i < tasks.size(); i++) {
    std::cout << "  " << i + 1 << ". [" << (tasks[i].done ? 'x' : ' ') << "] " << tasks[i].text << "\n";
  }
}

int main() {
  std::vector<Task> tasks = load();
  std::cout << "Commands: add TEXT, done N, del N, clear (removes done ones), list, quit\n";
  list(tasks);

  std::string cmd;
  while (std::cout << "> " && std::cin >> cmd && cmd != "quit") {
    if (cmd == "add") {
      std::string text;
      std::getline(std::cin, text);
      if (!text.empty() && text[0] == ' ') text.erase(0, 1);
      if (text.empty()) { std::cout << "Add what?\n"; continue; }
      tasks.push_back({false, text});
    } else if (cmd == "done" || cmd == "del") {
      std::size_t n = 0;
      if (!(std::cin >> n) || n < 1 || n > tasks.size()) {
        std::cin.clear();
        std::cin.ignore(1000, '\n');
        std::cout << "No task with that number.\n";
        continue;
      }
      if (cmd == "done") tasks[n - 1].done = true;
      else tasks.erase(tasks.begin() + static_cast<long>(n - 1));
    } else if (cmd == "clear") {
      std::vector<Task> left;
      for (const auto &t : tasks) if (!t.done) left.push_back(t);
      tasks = left;
    } else if (cmd != "list") {
      std::cout << "Unknown command\n";
      continue;
    }
    save(tasks);  // save after every change
    list(tasks);
  }
  return 0;
}
