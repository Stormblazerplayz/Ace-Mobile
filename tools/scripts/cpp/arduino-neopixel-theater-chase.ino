// @title NeoPixel Theater Chase Lights
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip DIN to pin 6 (330 ohm resistor), 5V, GND.
// @keywords theater chase, marquee lights, neopixel chase, cinema sign lights
// @about Makes lights march along a strip like an old cinema sign, changing color each round.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 30;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

void theaterChase(uint32_t color, int wait) {
  for (int round = 0; round < 10; round++) {
    for (int offset = 0; offset < 3; offset++) {
      strip.clear();
      // Light every 3rd LED, starting at offset 0, 1 or 2.
      for (int i = offset; i < NUM_LEDS; i += 3) {
        strip.setPixelColor(i, color);
      }
      strip.show();
      delay(wait);
    }
  }
}

void setup() {
  strip.begin();
  strip.setBrightness(50);
}

void loop() {
  theaterChase(strip.Color(255, 200, 0), 80);  // gold
  theaterChase(strip.Color(255, 0, 80), 80);   // pink
  theaterChase(strip.Color(0, 150, 255), 80);  // sky blue
}
