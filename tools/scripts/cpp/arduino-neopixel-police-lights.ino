// @title NeoPixel Police Lights
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; 8 or more LEDs, DIN to pin 6, 5V, GND.
// @keywords police lights, red and blue flashing, emergency lights neopixel, police car leds
// @about Flashes the left half red and the right half blue like a police car.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 16;
const int HALF = NUM_LEDS / 2;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

void showHalf(bool leftSide, uint32_t color) {
  strip.clear();
  int start = leftSide ? 0 : HALF;
  for (int i = start; i < start + HALF; i++) strip.setPixelColor(i, color);
  strip.show();
}

void setup() {
  strip.begin();
  strip.setBrightness(100);
}

void loop() {
  uint32_t red = strip.Color(255, 0, 0);
  uint32_t blue = strip.Color(0, 0, 255);

  for (int i = 0; i < 3; i++) {  // three quick red flashes
    showHalf(true, red);
    delay(60);
    strip.clear();
    strip.show();
    delay(40);
  }
  for (int i = 0; i < 3; i++) {  // then three blue
    showHalf(false, blue);
    delay(60);
    strip.clear();
    strip.show();
    delay(40);
  }
}
