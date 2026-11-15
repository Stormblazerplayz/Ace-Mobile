// @title Contact Book with unordered_map
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o contacts && ./contacts
// @keywords unordered_map, hash map c++, phone book program, find erase map, contact list c++
// @about A contact book that adds, finds, removes and lists contacts using a fast hash map (unordered_map).

#include <algorithm>
#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>

int main() {
  // unordered_map finds things super fast but keeps them in no particular order.
  std::unordered_map<std::string, std::string> book = {
    {"mom", "555-0101"}, {"grandpa", "555-0199"}, {"pizza", "555-0123"},
  };

  std::cout << "Commands: add NAME NUMBER, find NAME, remove NAME, list, quit\n";
  std::string cmd;
  while (std::cout << "> " && std::cin >> cmd && cmd != "quit") {
    if (cmd == "add") {
      std::string name, number;
      if (!(std::cin >> name >> number)) break;
      bool isNew = book.count(name) == 0;
      book[name] = number;  // adds a new one or replaces the old number
      std::cout << (isNew ? "Added " : "Updated ") << name << "\n";
    } else if (cmd == "find") {
      std::string name;
      if (!(std::cin >> name)) break;
      auto it = book.find(name);  // find returns end() if it's not there
      if (it != book.end()) std::cout << name << ": " << it->second << "\n";
      else std::cout << "No contact called " << name << "\n";
    } else if (cmd == "remove") {
      std::string name;
      if (!(std::cin >> name)) break;
      std::cout << (book.erase(name) ? "Removed " : "Couldn't find ") << name << "\n";
    } else if (cmd == "list") {
      // Copy the names out and sort them so the list looks tidy.
      std::vector<std::string> names;
      for (const auto &entry : book) names.push_back(entry.first);
      std::sort(names.begin(), names.end());
      for (const auto &n : names) std::cout << "  " << n << ": " << book[n] << "\n";
      std::cout << "  (" << book.size() << " contacts)\n";
    } else {
      std::cout << "Unknown command\n";
    }
  }
  return 0;
}
