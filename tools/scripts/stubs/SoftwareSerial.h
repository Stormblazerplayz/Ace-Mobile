// Stub SoftwareSerial.h (built-in library) for syntax checks. Declarations only.
#pragma once
#include "Arduino.h"

class SoftwareSerial : public Stream {
public:
  SoftwareSerial(uint8_t receivePin, uint8_t transmitPin, bool inverse_logic = false);
  ~SoftwareSerial();
  void begin(long speed);
  bool listen();
  void end();
  bool isListening();
  bool overflow();
  int peek() override;
  size_t write(uint8_t byte) override;
  int read() override;
  int available() override;
  void flush();
  explicit operator bool() { return true; }
  using Print::write;
};
