// @title Cannonball Projectile Simulator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o cannon && ./cannon
// @keywords projectile motion, cannonball physics, launch angle range, gravity simulation, trajectory plot
// @about Launches a cannonball at the speed and angle you choose, works out how far and high it flies, and plots the path.

#include <cmath>
#include <iostream>
#include <vector>

const double PI = 3.14159265358979;
const double G = 9.81;  // gravity on Earth, meters per second per second

int main() {
  double speed, angle;
  std::cout << "Launch speed in m/s (1-200): ";
  if (!(std::cin >> speed) || speed < 1 || speed > 200) speed = 30;
  std::cout << "Launch angle in degrees (1-89): ";
  if (!(std::cin >> angle) || angle < 1 || angle > 89) angle = 45;

  double rad = angle * PI / 180;
  double vx = speed * std::cos(rad), vy = speed * std::sin(rad);  // split the speed into across and up
  double flight = 2 * vy / G;
  double range = vx * flight;
  double height = vy * vy / (2 * G);
  std::cout << "\nFlight time: " << flight << " s\nDistance:    " << range << " m\nMax height:  " << height << " m\n";

  // Step through time and mark where the ball is on a 60 x 15 picture.
  const int W = 60, H = 15;
  std::vector<std::string> sky(H, std::string(W, ' '));
  double scale = std::max(range, height);
  for (int i = 0; i <= 200; i++) {
    double t = flight * i / 200;
    double x = vx * t, y = vy * t - 0.5 * G * t * t;
    int col = static_cast<int>(x / scale * (W - 1));
    int row = H - 1 - static_cast<int>(y / scale * (H - 1) * 2);
    if (col >= 0 && col < W && row >= 0 && row < H) sky[row][col] = 'o';
  }
  for (const std::string &row : sky) std::cout << "|" << row << "\n";
  std::cout << "+" << std::string(W, '-') << "\n";

  // Which angle goes furthest? Try them all.
  double bestRange = 0;
  int bestAngle = 0;
  for (int a = 5; a <= 85; a += 5) {
    double r = speed * speed * std::sin(2 * a * PI / 180) / G;
    if (r > bestRange + 1e-9) { bestRange = r; bestAngle = a; }
  }
  std::cout << "At this speed, " << bestAngle << " degrees goes furthest: " << bestRange << " m\n";
  return 0;
}
