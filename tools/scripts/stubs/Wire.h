// Stub Wire.h (I2C) for syntax-checking sketches. Declarations only.
#pragma once
#include "Arduino.h"

class TwoWire : public Stream {
public:
  void begin();
  void begin(uint8_t address);
  void begin(int address);
  void end();
  void setClock(uint32_t clock);
  void beginTransmission(uint8_t address);
  void beginTransmission(int address);
  uint8_t endTransmission();
  uint8_t endTransmission(uint8_t sendStop);
  uint8_t requestFrom(uint8_t address, uint8_t quantity);
  uint8_t requestFrom(uint8_t address, uint8_t quantity, uint8_t sendStop);
  uint8_t requestFrom(int address, int quantity);
  uint8_t requestFrom(int address, int quantity, int sendStop);
  size_t write(uint8_t data) override;
  size_t write(const uint8_t *data, size_t quantity);
  size_t write(unsigned long n);
  size_t write(long n);
  size_t write(unsigned int n);
  size_t write(int n);
  int available() override;
  int read() override;
  int peek() override;
  void onReceive(void (*function)(int));
  void onRequest(void (*function)(void));
  using Print::write;
};
extern TwoWire Wire;
