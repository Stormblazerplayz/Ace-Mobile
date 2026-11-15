// @title Menu with switch and do while
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o menu && ./menu
// @keywords c++ switch case, c++ do while loop, console menu c++, c++ break statement
// @about A snack shop menu that uses a do while loop and a switch to handle each choice.

#include <iomanip>
#include <iostream>

int main() {
  int choice = 0;
  double total = 0.0;
  int items = 0;

  // A do while loop always runs at least once, perfect for menus.
  do {
    std::cout << "\n=== Snack Shop ===\n"
              << "1. Chips    $1.50\n"
              << "2. Cookie   $0.75\n"
              << "3. Juice    $2.00\n"
              << "4. Show total\n"
              << "0. Pay and leave\n"
              << "Choose: ";
    if (!(std::cin >> choice)) break;  // no more input: leave

    switch (choice) {
      case 1:
        total += 1.50;
        items++;
        std::cout << "Added chips.\n";
        break;  // without break, it would fall into the next case!
      case 2:
        total += 0.75;
        items++;
        std::cout << "Added a cookie.\n";
        break;
      case 3:
        total += 2.00;
        items++;
        std::cout << "Added juice.\n";
        break;
      case 4:
        std::cout << items << " items so far.\n";
        break;
      case 0:
        std::cout << "Thanks for shopping!\n";
        break;
      default:
        std::cout << "That's not on the menu.\n";
    }
    std::cout << std::fixed << std::setprecision(2) << "Total: $" << total << "\n";
  } while (choice != 0);

  return 0;
}
