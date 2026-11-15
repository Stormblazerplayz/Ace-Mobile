// Stub Adafruit_NeoPixel.h for syntax-checking sketches. Declarations only.
#pragma once
#include <stdint.h>

typedef uint16_t neoPixelType;

#define NEO_RGB ((0 << 6) | (0 << 4) | (1 << 2) | (2))
#define NEO_GRB ((1 << 6) | (1 << 4) | (0 << 2) | (2))
#define NEO_RGBW ((3 << 6) | (0 << 4) | (1 << 2) | (2))
#define NEO_GRBW ((3 << 6) | (1 << 4) | (0 << 2) | (2))
#define NEO_KHZ800 0x0000
#define NEO_KHZ400 0x0100

class Adafruit_NeoPixel {
public:
  Adafruit_NeoPixel(uint16_t n, int16_t pin = 6, neoPixelType type = NEO_GRB + NEO_KHZ800);
  Adafruit_NeoPixel();
  ~Adafruit_NeoPixel();
  void begin();
  void show();
  void clear();
  void fill(uint32_t c = 0, uint16_t first = 0, uint16_t count = 0);
  void setPixelColor(uint16_t n, uint8_t r, uint8_t g, uint8_t b);
  void setPixelColor(uint16_t n, uint32_t c);
  void setBrightness(uint8_t b);
  uint32_t getPixelColor(uint16_t n) const;
  uint16_t numPixels() const;
  static uint32_t Color(uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
  }
  static uint32_t ColorHSV(uint16_t hue, uint8_t sat = 255, uint8_t val = 255);
  static uint32_t gamma32(uint32_t x);
};
