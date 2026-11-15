// @title Matrix Class: Add, Multiply, Transpose
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o matrix && ./matrix
// @keywords matrix class c++, matrix multiplication, transpose matrix, 2d vector class, linear algebra c++
// @about A Matrix class stored in one vector that can add, multiply and transpose matrices, with a rotation example.

#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <vector>

class Matrix {
public:
  Matrix(int rows, int cols) : rows_(rows), cols_(cols), data_(rows * cols, 0.0) {}
  Matrix(int rows, int cols, std::vector<double> values) : rows_(rows), cols_(cols), data_(std::move(values)) {
    if (static_cast<int>(data_.size()) != rows * cols) throw std::invalid_argument("wrong number of values");
  }

  // One long vector: row r, column c lives at r * cols + c.
  double &at(int r, int c) { return data_[r * cols_ + c]; }
  double at(int r, int c) const { return data_[r * cols_ + c]; }

  Matrix operator+(const Matrix &o) const {
    if (rows_ != o.rows_ || cols_ != o.cols_) throw std::invalid_argument("sizes must match to add");
    Matrix out(rows_, cols_);
    for (std::size_t i = 0; i < data_.size(); i++) out.data_[i] = data_[i] + o.data_[i];
    return out;
  }

  Matrix operator*(const Matrix &o) const {
    if (cols_ != o.rows_) throw std::invalid_argument("columns of A must equal rows of B");
    Matrix out(rows_, o.cols_);
    for (int r = 0; r < rows_; r++)
      for (int c = 0; c < o.cols_; c++)
        for (int k = 0; k < cols_; k++) out.at(r, c) += at(r, k) * o.at(k, c);  // row times column
    return out;
  }

  Matrix transposed() const {
    Matrix out(cols_, rows_);
    for (int r = 0; r < rows_; r++)
      for (int c = 0; c < cols_; c++) out.at(c, r) = at(r, c);
    return out;
  }

  void print(const char *name) const {
    std::cout << name << " (" << rows_ << "x" << cols_ << "):\n";
    for (int r = 0; r < rows_; r++) {
      std::cout << "  [";
      for (int c = 0; c < cols_; c++) std::cout << std::setw(7) << std::fixed << std::setprecision(2) << at(r, c);
      std::cout << " ]\n";
    }
  }

private:
  int rows_, cols_;
  std::vector<double> data_;
};

int main() {
  Matrix a(2, 3, {1, 2, 3, 4, 5, 6});
  Matrix b(3, 2, {7, 8, 9, 10, 11, 12});
  a.print("A");
  b.print("B");
  (a * b).print("A x B");
  a.transposed().print("A transposed");
  (a + a).print("A + A");

  // A rotation matrix turns a point around (0,0). Here: 90 degrees.
  double angle = 90 * 3.14159265358979 / 180;
  Matrix rotate(2, 2, {std::cos(angle), -std::sin(angle), std::sin(angle), std::cos(angle)});
  Matrix point(2, 1, {3, 1});
  (rotate * point).print("Point (3,1) turned 90 degrees");

  try {
    (a * a).print("A x A");
  } catch (const std::invalid_argument &e) {
    std::cout << "A x A failed: " << e.what() << "\n";
  }
  return 0;
}
