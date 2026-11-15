// Stub EEPROM.h (built-in AVR EEPROM library) for syntax checks. Declarations only.
#pragma once
#include "Arduino.h"

struct EERef {
  operator uint8_t() const;
  EERef &operator=(uint8_t in);
  EERef &update(uint8_t in);
};

struct EEPROMClass {
  EERef operator[](const int idx);
  uint8_t read(int idx);
  void write(int idx, uint8_t val);
  void update(int idx, uint8_t val);
  uint16_t length();
  template <typename T> T &get(int idx, T &t);
  template <typename T> const T &put(int idx, const T &t);
};
extern EEPROMClass EEPROM;
