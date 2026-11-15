// @title NeoPixel Color Wipe
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip DIN to pin 6 through a 330 ohm resistor, 5V and GND (use an external 5V supply for more than 30 LEDs).
// @keywords neopixel color wipe, fill strip one by one, ws2812 wipe, led strip animation
// @about Fills a NeoPixel strip one LED at a time with red, then green, then blue.

#include <Adafruit_NeoPixel.h>

const int PIN = 6;
const int NUM_LEDS = 30;
Adafruit_NeoPixel strip(NUM_LEDS, PIN, NEO_GRB + NEO_KHZ800);

void colorWipe(uint32_t color, int wait) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, color);
    strip.show();  // send the colors to the strip
    delay(wait);
  }
}

void setup() {
  strip.begin();
  strip.setBrightness(60);  // 0 to 255; keep it low to save power and eyes
  strip.show();             // start with all LEDs off
}

void loop() {
  colorWipe(strip.Color(255, 0, 0), 40);
  colorWipe(strip.Color(0, 255, 0), 40);
  colorWipe(strip.Color(0, 0, 255), 40);
  colorWipe(strip.Color(0, 0, 0), 20);  // wipe to black
}
