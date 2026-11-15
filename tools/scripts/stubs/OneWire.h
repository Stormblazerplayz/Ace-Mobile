// Stub OneWire.h (OneWire library) for syntax checks. Declarations only.
#pragma once
#include "Arduino.h"

class OneWire {
public:
  OneWire(uint8_t pin);
  uint8_t reset();
  void write(uint8_t v, uint8_t power = 0);
  uint8_t read();
};
