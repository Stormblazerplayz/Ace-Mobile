// @title Triangle Classifier
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o triangle && ./triangle
// @keywords triangle classifier, equilateral isosceles scalene, acute obtuse right triangle, triangle inequality, triangle angles law of cosines
// @about Tells you whether three sides make a triangle, what kind it is, and works out all three angles.

#include <algorithm>
#include <cmath>
#include <iostream>

const double PI = 3.14159265358979;

// Law of cosines: angle opposite side c = acos((a^2 + b^2 - c^2) / 2ab)
double angleOpposite(double a, double b, double c) {
  double cosC = (a * a + b * b - c * c) / (2 * a * b);
  cosC = std::max(-1.0, std::min(1.0, cosC));  // keep rounding errors inside acos' range
  return std::acos(cosC) * 180 / PI;
}

int main() {
  std::cout << "Type three side lengths (Ctrl+D to stop): ";
  double a, b, c;
  while (std::cin >> a >> b >> c) {
    double s[3] = {a, b, c};
    std::sort(s, s + 3);  // s[2] is now the longest side
    if (s[0] <= 0 || s[0] + s[1] <= s[2]) {
      std::cout << "Not a triangle: the two short sides must add up to more than the long one.\n";
    } else {
      if (s[0] == s[2]) std::cout << "Equilateral (all sides equal). ";
      else if (s[0] == s[1] || s[1] == s[2]) std::cout << "Isosceles (two sides equal). ";
      else std::cout << "Scalene (no sides equal). ";

      double diff = s[0] * s[0] + s[1] * s[1] - s[2] * s[2];
      double tiny = 1e-9 * s[2] * s[2];
      if (std::fabs(diff) <= tiny) std::cout << "Right-angled!\n";
      else if (diff > 0) std::cout << "Acute (all angles under 90).\n";
      else std::cout << "Obtuse (one angle over 90).\n";

      double A = angleOpposite(b, c, a), B = angleOpposite(a, c, b), C = 180 - A - B;
      std::cout << "Angles: " << A << ", " << B << ", " << C << " degrees (they add to 180)\n";
    }
    std::cout << "\nType three side lengths: ";
  }
  std::cout << "\n";
  return 0;
}
