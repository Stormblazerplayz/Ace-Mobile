// @title NeoPixel Twinkling Stars
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip DIN to pin 6, 5V, GND; great on a bedroom ceiling.
// @keywords twinkle stars, starry night leds, neopixel sparkle, random twinkle strip
// @about Makes random LEDs sparkle white and slowly fade, like stars twinkling.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 30;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);
byte level[NUM_LEDS];  // how bright each star is right now

void setup() {
  strip.begin();
  strip.setBrightness(80);
  randomSeed(analogRead(A0));
  for (int i = 0; i < NUM_LEDS; i++) level[i] = 0;
}

void loop() {
  // Sometimes a new star lights up.
  if (random(4) == 0) {
    level[random(NUM_LEDS)] = 255;
  }

  for (int i = 0; i < NUM_LEDS; i++) {
    // Slightly blue-white looks more like a star.
    strip.setPixelColor(i, level[i] * 8 / 10, level[i] * 8 / 10, level[i]);
    // Fade each star a little.
    if (level[i] > 6) level[i] -= 6;
    else level[i] = 0;
  }
  strip.show();
  delay(30);
}
