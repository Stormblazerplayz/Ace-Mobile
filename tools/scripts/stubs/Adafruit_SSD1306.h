// Stub Adafruit_SSD1306.h (Adafruit SSD1306 OLED library) for syntax checks.
#pragma once
#include "Arduino.h"
#include "Wire.h"
#include "Adafruit_GFX.h"

#define SSD1306_BLACK 0
#define SSD1306_WHITE 1
#define SSD1306_INVERSE 2
#define BLACK SSD1306_BLACK
#define WHITE SSD1306_WHITE
#define INVERSE SSD1306_INVERSE
#define SSD1306_EXTERNALVCC 0x01
#define SSD1306_SWITCHCAPVCC 0x02

class Adafruit_SSD1306 : public Adafruit_GFX {
public:
  Adafruit_SSD1306(uint8_t w, uint8_t h, TwoWire *twi = &Wire, int8_t rst_pin = -1,
                   uint32_t clkDuring = 400000UL, uint32_t clkAfter = 100000UL);
  ~Adafruit_SSD1306();
  bool begin(uint8_t switchvcc = SSD1306_SWITCHCAPVCC, uint8_t i2caddr = 0, bool reset = true,
             bool periphBegin = true);
  void display();
  void clearDisplay();
  void invertDisplay(bool i);
  void dim(bool dim);
  void drawPixel(int16_t x, int16_t y, uint16_t color) override;
  void startscrollright(uint8_t start, uint8_t stop);
  void startscrollleft(uint8_t start, uint8_t stop);
  void stopscroll();
  bool getPixel(int16_t x, int16_t y);
};
