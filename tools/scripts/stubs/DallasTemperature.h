// Stub DallasTemperature.h (Miles Burton's DS18B20 library) for syntax checks.
#pragma once
#include "Arduino.h"
#include "OneWire.h"

#define DEVICE_DISCONNECTED_C -127
#define DEVICE_DISCONNECTED_F -196.6

class DallasTemperature {
public:
  DallasTemperature(OneWire *oneWire);
  void begin();
  uint8_t getDeviceCount();
  void requestTemperatures();
  float getTempCByIndex(uint8_t index);
  float getTempFByIndex(uint8_t index);
  void setResolution(uint8_t newResolution);
};
