// @title Text Adventure with Rooms
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o game && ./game
// @keywords c++ text adventure, c++ adventure game with rooms, c++ dungeon game, choose your path game c++
// @about Walk between rooms by typing north, south, east or west, find the key and escape the castle.

#include <cctype>
#include <iostream>
#include <map>
#include <string>

// One room: a name, a description, and which way leads where.
struct Room {
  std::string name;
  std::string description;
  std::map<std::string, std::string> exits;  // direction -> room id
};

int main() {
  std::map<std::string, Room> rooms = {
      {"hall", {"Great Hall", "A dusty hall. Doors lead north and east.",
                {{"north", "library"}, {"east", "kitchen"}}}},
      {"library", {"Library", "Tall shelves of old books. Something shiny is on a desk.",
                   {{"south", "hall"}}}},
      {"kitchen", {"Kitchen", "Pots and pans everywhere. A big locked door is to the east.",
                   {{"west", "hall"}, {"east", "exit"}}}},
      {"exit", {"Castle Gate", "Fresh air! You escaped!", {}}},
  };

  std::string current = "hall";
  bool hasKey = false;

  std::cout << "== Castle Escape ==\n"
            << "Commands: north, south, east, west, take, look, quit\n";

  while (true) {
    const Room &room = rooms[current];
    std::cout << "\n[" << room.name << "]\n" << room.description << "\n";
    if (current == "exit") break;

    std::cout << "> ";
    std::string command;
    if (!std::getline(std::cin, command)) return 0;  // input closed
    for (char &c : command) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));

    if (command == "quit") {
      std::cout << "Bye!\n";
      return 0;
    } else if (command == "look") {
      continue;  // the loop prints the room again
    } else if (command == "take") {
      if (current == "library" && !hasKey) {
        hasKey = true;
        rooms["library"].description = "Tall shelves of old books. The desk is empty now.";
        std::cout << "You picked up a golden key!\n";
      } else {
        std::cout << "There's nothing to take here.\n";
      }
    } else if (room.exits.count(command)) {
      std::string next = room.exits.at(command);
      if (next == "exit" && !hasKey) {
        std::cout << "The door is locked. Maybe a key is somewhere...\n";
      } else {
        current = next;
      }
    } else {
      std::cout << "You can't do that. Try north, south, east, west, take or look.\n";
    }
  }

  std::cout << "You win! Thanks for playing.\n";
  return 0;
}
