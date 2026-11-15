// Stub Keypad.h (Mark Stanley and Alexander Brevig's Keypad library) for syntax checks.
#pragma once
#include "Arduino.h"

#define NO_KEY '\0'
#define makeKeymap(x) ((char *)x)

class Keypad {
public:
  Keypad(char *userKeymap, byte *row, byte *col, byte numRows, byte numCols);
  char getKey();
  char waitForKey();
  void setDebounceTime(unsigned int debounce);
  void setHoldTime(unsigned int hold);
};
