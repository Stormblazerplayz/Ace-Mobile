// @title Operator Overloading: a Vector2 Class
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o vec2 && ./vec2
// @keywords operator overloading, c++ vector2 class, overload plus operator, overload ostream, game math vector
// @about Makes a 2D vector type you can add, subtract, scale and print with normal + - * and << signs, like in game engines.

#include <cmath>
#include <iostream>

struct Vector2 {
  double x = 0, y = 0;

  Vector2() = default;
  Vector2(double xIn, double yIn) : x(xIn), y(yIn) {}

  // a + b
  Vector2 operator+(const Vector2 &other) const { return {x + other.x, y + other.y}; }
  // a - b
  Vector2 operator-(const Vector2 &other) const { return {x - other.x, y - other.y}; }
  // a * 2.5
  Vector2 operator*(double scale) const { return {x * scale, y * scale}; }
  // a += b
  Vector2 &operator+=(const Vector2 &other) {
    x += other.x;
    y += other.y;
    return *this;
  }
  // a == b
  bool operator==(const Vector2 &other) const { return x == other.x && y == other.y; }

  double length() const { return std::sqrt(x * x + y * y); }

  Vector2 normalized() const {
    double len = length();
    if (len == 0) return {0, 0};
    return {x / len, y / len};
  }
};

// Lets you write: std::cout << myVector
std::ostream &operator<<(std::ostream &out, const Vector2 &v) {
  return out << "(" << v.x << ", " << v.y << ")";
}

int main() {
  Vector2 position(0, 0);
  Vector2 velocity(3, 4);

  std::cout << "Start position: " << position << "\n";
  std::cout << "Velocity: " << velocity << " with speed " << velocity.length() << "\n";

  // Move for 3 frames.
  for (int frame = 1; frame <= 3; frame++) {
    position += velocity;
    std::cout << "Frame " << frame << ": " << position << "\n";
  }

  Vector2 target(20, 5);
  Vector2 toTarget = target - position;
  std::cout << "\nArrow to the target: " << toTarget << "\n";
  std::cout << "Distance to target: " << toTarget.length() << "\n";
  std::cout << "Direction (length 1): " << toTarget.normalized() << "\n";
  std::cout << "Half speed: " << velocity * 0.5 << "\n";
  std::cout << "Is (1,2)+(2,3) == (3,5)? " << std::boolalpha
            << (Vector2(1, 2) + Vector2(2, 3) == Vector2(3, 5)) << "\n";
  return 0;
}
