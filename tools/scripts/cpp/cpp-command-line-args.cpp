// @title Command Line Arguments (argc and argv)
// @category Basics
// @kind Console program
// @where Save as main.cpp, compile with g++ -std=c++17 main.cpp -o greet, then run ./greet Storm --shout --times 3
// @keywords argc argv, command line arguments c++, main parameters, read flags c++, terminal arguments
// @about Reads words typed after the program name, like a name and flags such as --shout and --times 3.

#include <cctype>
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
  // argc = how many words, argv = the words. argv[0] is the program's own name.
  std::cout << "You gave me " << argc - 1 << " argument(s).\n";
  for (int i = 0; i < argc; i++) std::cout << "  argv[" << i << "] = " << argv[i] << "\n";

  std::string name = "friend";
  bool shout = false;
  int times = 1;

  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg == "--shout") {
      shout = true;
    } else if (arg == "--times" && i + 1 < argc) {
      try {
        times = std::stoi(argv[++i]);  // use the NEXT word as the number
      } catch (const std::exception &) {
        std::cout << "--times needs a number\n";
      }
      if (times < 1 || times > 10) times = 1;
    } else if (arg == "--help") {
      std::cout << "Usage: greet NAME [--shout] [--times N]\n";
      return 0;
    } else {
      name = arg;
    }
  }

  std::string message = "Hello, " + name + "!";
  if (shout) {
    for (char &c : message) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
  }
  for (int i = 0; i < times; i++) std::cout << message << "\n";
  return 0;
}
