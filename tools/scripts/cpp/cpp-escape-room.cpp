// @title Escape Room Puzzles
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o escape && ./escape
// @keywords escape room, puzzle riddles game, find the code, locked door puzzle, inventory of items
// @about Escape a locked room by searching objects, collecting items and solving riddles and number puzzles.

#include <iostream>
#include <set>
#include <string>

int main() {
  std::set<std::string> inventory;
  bool boxOpen = false;
  std::cout << "You wake up in a locked room. There's a DESK, a PAINTING, a BOX with a 3-digit lock and a DOOR.\n";
  std::cout << "Commands: look desk, look painting, open box, open door, items, quit\n";

  std::string verb, thing;
  while (std::cout << "\n> " && std::cin >> verb) {
    if (verb == "quit") break;
    if (verb == "items") {
      std::cout << "You have:";
      for (const std::string &i : inventory) std::cout << " " << i;
      std::cout << (inventory.empty() ? " nothing" : "") << "\n";
      continue;
    }
    if (!(std::cin >> thing)) break;

    if (verb == "look" && thing == "desk") {
      std::cout << "A note says: 'I have keys but open no locks. I have space but no room. What am I?'\n";
      std::cout << "Type your answer: ";
      std::string answer;
      if (!(std::cin >> answer)) break;
      if (answer == "keyboard" || answer == "KEYBOARD" || answer == "Keyboard") {
        std::cout << "The drawer clicks open. You take a FLASHLIGHT.\n";
        inventory.insert("flashlight");
      } else {
        std::cout << "Nothing happens.\n";
      }
    } else if (verb == "look" && thing == "painting") {
      if (inventory.count("flashlight"))
        std::cout << "You shine the flashlight on it. Glowing numbers say: 7 x 6 + 100 = ?\n";
      else
        std::cout << "It's too dark to see details. Maybe a light would help.\n";
    } else if (verb == "open" && thing == "box") {
      if (boxOpen) { std::cout << "It's already open.\n"; continue; }
      std::cout << "Enter the 3-digit code: ";
      int code;
      if (!(std::cin >> code)) break;
      if (code == 142) {
        boxOpen = true;
        inventory.insert("key");
        std::cout << "The box opens! Inside is a shiny KEY.\n";
      } else {
        std::cout << "Beep. Wrong code.\n";
      }
    } else if (verb == "open" && thing == "door") {
      if (inventory.count("key")) {
        std::cout << "The key turns... the door swings open. YOU ESCAPED!\n";
        return 0;
      }
      std::cout << "It's locked tight.\n";
    } else {
      std::cout << "You can't do that.\n";
    }
  }
  std::cout << "\nYou're still stuck in the room. Try again!\n";
  return 0;
}
