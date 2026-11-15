// @title Area and Perimeter Calculator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o area && ./area
// @keywords area calculator, perimeter calculator, area of circle triangle, geometry homework c++, shape formulas
// @about Works out the area and perimeter of squares, rectangles, triangles, circles and trapezoids, showing the formula.

#include <cmath>
#include <iostream>

const double PI = 3.14159265358979;

bool readPositive(double &x) {
  return static_cast<bool>(std::cin >> x) && x > 0;
}

int main() {
  int choice;
  while (std::cout << "\n1 Square  2 Rectangle  3 Triangle (3 sides)  4 Circle  5 Trapezoid  0 Quit\nShape: " &&
         std::cin >> choice && choice != 0) {
    double a, b, c, h;
    switch (choice) {
      case 1:
        std::cout << "Side: ";
        if (!readPositive(a)) return 0;
        std::cout << "Area = side x side = " << a * a << "\nPerimeter = 4 x side = " << 4 * a << "\n";
        break;
      case 2:
        std::cout << "Width and height: ";
        if (!readPositive(a) || !readPositive(b)) return 0;
        std::cout << "Area = w x h = " << a * b << "\nPerimeter = 2(w + h) = " << 2 * (a + b) << "\n";
        break;
      case 3: {
        std::cout << "Three side lengths: ";
        if (!readPositive(a) || !readPositive(b) || !readPositive(c)) return 0;
        if (a + b <= c || a + c <= b || b + c <= a) {
          std::cout << "Those sides can't make a triangle!\n";
          break;
        }
        double s = (a + b + c) / 2;  // Heron's formula uses half the perimeter
        std::cout << "Area (Heron's formula) = " << std::sqrt(s * (s - a) * (s - b) * (s - c))
                  << "\nPerimeter = a + b + c = " << a + b + c << "\n";
        break;
      }
      case 4:
        std::cout << "Radius: ";
        if (!readPositive(a)) return 0;
        std::cout << "Area = pi x r x r = " << PI * a * a << "\nCircumference = 2 x pi x r = " << 2 * PI * a << "\n";
        break;
      case 5:
        std::cout << "Top side, bottom side and height: ";
        if (!readPositive(a) || !readPositive(b) || !readPositive(h)) return 0;
        std::cout << "Area = (top + bottom) / 2 x height = " << (a + b) / 2 * h << "\n";
        break;
      default:
        std::cout << "Pick 0 to 5.\n";
    }
  }
  return 0;
}
