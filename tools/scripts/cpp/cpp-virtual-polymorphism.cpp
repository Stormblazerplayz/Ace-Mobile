// @title Polymorphism with Virtual Functions
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o shapes && ./shapes
// @keywords c++ polymorphism, virtual function, override keyword, base class pointer, virtual destructor
// @about Stores different shapes in one list and lets each shape work out its own area with a virtual function.

#include <iostream>
#include <memory>
#include <string>
#include <vector>

const double PI = 3.14159265358979;

class Shape {
public:
  // A virtual destructor makes sure the right destructor runs. Always add one!
  virtual ~Shape() = default;
  // virtual = "child classes may replace this".
  virtual double area() const { return 0.0; }
  virtual std::string name() const { return "shape"; }
};

class Circle : public Shape {
public:
  explicit Circle(double r) : radius_(r) {}
  double area() const override { return PI * radius_ * radius_; }  // override = "I'm replacing it"
  std::string name() const override { return "circle"; }
private:
  double radius_;
};

class Rectangle : public Shape {
public:
  Rectangle(double w, double h) : width_(w), height_(h) {}
  double area() const override { return width_ * height_; }
  std::string name() const override { return "rectangle"; }
private:
  double width_, height_;
};

class Triangle : public Shape {
public:
  Triangle(double base, double height) : base_(base), height_(height) {}
  double area() const override { return 0.5 * base_ * height_; }
  std::string name() const override { return "triangle"; }
private:
  double base_, height_;
};

int main() {
  // One list, many kinds of shapes. unique_ptr cleans them up for us.
  std::vector<std::unique_ptr<Shape>> shapes;
  shapes.push_back(std::make_unique<Circle>(2.0));
  shapes.push_back(std::make_unique<Rectangle>(3.0, 4.5));
  shapes.push_back(std::make_unique<Triangle>(6.0, 2.0));
  shapes.push_back(std::make_unique<Circle>(0.5));

  double total = 0;
  for (const auto &s : shapes) {
    // This calls the RIGHT area() for each shape, even though we only know it's a Shape.
    std::cout << "A " << s->name() << " with area " << s->area() << "\n";
    total += s->area();
  }
  std::cout << "Total area: " << total << "\n";
  return 0;
}
