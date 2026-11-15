// @title Fraction Calculator Class
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o fractions && ./fractions
// @keywords fraction calculator, add fractions c++, simplify fractions, fraction class operators, mixed numbers
// @about A Fraction class that adds, subtracts, multiplies and divides fractions, always simplifying the answer.

#include <iostream>
#include <numeric>
#include <stdexcept>

class Fraction {
public:
  Fraction(long long top = 0, long long bottom = 1) : num_(top), den_(bottom) {
    if (den_ == 0) throw std::invalid_argument("the bottom of a fraction can't be 0");
    simplify();
  }

  Fraction operator+(const Fraction &o) const { return {num_ * o.den_ + o.num_ * den_, den_ * o.den_}; }
  Fraction operator-(const Fraction &o) const { return {num_ * o.den_ - o.num_ * den_, den_ * o.den_}; }
  Fraction operator*(const Fraction &o) const { return {num_ * o.num_, den_ * o.den_}; }
  Fraction operator/(const Fraction &o) const { return {num_ * o.den_, den_ * o.num_}; }  // flip and multiply

  double toDouble() const { return static_cast<double>(num_) / den_; }

  friend std::ostream &operator<<(std::ostream &out, const Fraction &f) {
    if (f.den_ == 1) return out << f.num_;
    long long whole = f.num_ / f.den_;
    if (whole != 0) {  // show as a mixed number too, like 7/2 = 3 1/2
      long long rest = f.num_ % f.den_;
      return out << f.num_ << "/" << f.den_ << " (= " << whole << " " << (rest < 0 ? -rest : rest) << "/" << f.den_ << ")";
    }
    return out << f.num_ << "/" << f.den_;
  }

private:
  long long num_, den_;

  void simplify() {
    if (den_ < 0) { num_ = -num_; den_ = -den_; }  // keep the minus sign on top
    long long g = std::gcd(num_, den_);
    if (g != 0) { num_ /= g; den_ /= g; }
  }
};

int main() {
  std::cout << "Type a sum like 1/2 + 3/4 (signs: + - * /). Ctrl+D to stop.\n";
  long long a, b, c, d;
  char slash1, op, slash2;
  while (std::cout << "> " && std::cin >> a >> slash1 >> b >> op >> c >> slash2 >> d) {
    try {
      Fraction x(a, b), y(c, d), result;
      if (op == '+') result = x + y;
      else if (op == '-') result = x - y;
      else if (op == '*') result = x * y;
      else if (op == '/') result = x / y;
      else { std::cout << "Unknown sign " << op << "\n"; continue; }
      std::cout << x << " " << op << " " << y << " = " << result << "  ~ " << result.toDouble() << "\n";
    } catch (const std::invalid_argument &e) {
      std::cout << "Oops: " << e.what() << "\n";
    }
  }
  std::cout << "\n";
  return 0;
}
