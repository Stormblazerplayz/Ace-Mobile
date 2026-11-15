// @title NeoPixel Campfire Flicker
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip or ring DIN to pin 6 (330 ohm), 5V, GND; put it behind paper for a cosy fake fire.
// @keywords neopixel fire, fake candle leds, flickering flame effect, campfire lights
// @about Flickers a NeoPixel strip in reds, oranges and yellows like a real fire.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 16;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

void setup() {
  strip.begin();
  strip.setBrightness(120);
  randomSeed(analogRead(A0));
}

void loop() {
  for (int i = 0; i < NUM_LEDS; i++) {
    // Fire colors: lots of red, some green (to make orange), almost no blue.
    int flicker = random(0, 80);
    int red = 255 - flicker;
    int green = 90 - flicker;
    if (green < 0) green = 0;
    strip.setPixelColor(i, red, green, 0);
  }
  strip.show();
  delay(random(50, 150));  // random timing looks more real
}
