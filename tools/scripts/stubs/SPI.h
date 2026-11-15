// Stub SPI.h (built-in library) for syntax checks. Declarations only.
#pragma once
#include "Arduino.h"

class SPIClass {
public:
  static void begin();
  static void end();
  static uint8_t transfer(uint8_t data);
};
extern SPIClass SPI;
