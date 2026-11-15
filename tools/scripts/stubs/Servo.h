// Stub Servo.h for syntax-checking sketches. Declarations only.
#pragma once
#include <stdint.h>

class Servo {
public:
  Servo();
  uint8_t attach(int pin);
  uint8_t attach(int pin, int min, int max);
  void detach();
  void write(int value);
  void writeMicroseconds(int value);
  int read();
  bool attached();
};
