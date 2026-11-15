// @title NeoPixel Knob Level Meter
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip DIN to pin 6, 5V, GND; potentiometer middle leg on A0 (or any analog sensor).
// @keywords neopixel meter, led strip bar graph, green yellow red meter, potentiometer led strip
// @about Shows a knob's position as a bar on an LED strip that goes green, then yellow, then red.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 20;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

void setup() {
  strip.begin();
  strip.setBrightness(40);
}

void loop() {
  int lit = map(analogRead(A0), 0, 1023, 0, NUM_LEDS);

  for (int i = 0; i < NUM_LEDS; i++) {
    if (i >= lit) {
      strip.setPixelColor(i, 0);  // off
    } else if (i < NUM_LEDS * 6 / 10) {
      strip.setPixelColor(i, 0, 255, 0);    // first 60%: green
    } else if (i < NUM_LEDS * 85 / 100) {
      strip.setPixelColor(i, 255, 180, 0);  // next part: yellow
    } else {
      strip.setPixelColor(i, 255, 0, 0);    // top: red
    }
  }
  strip.show();
  delay(20);
}
