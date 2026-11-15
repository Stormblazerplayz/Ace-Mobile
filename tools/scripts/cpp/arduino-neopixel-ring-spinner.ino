// @title NeoPixel Ring Loading Spinner
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; 12 or 16 LED ring, DIN to pin 6, 5V, GND.
// @keywords neopixel ring, loading spinner, spinning comet ring, led ring animation
// @about Spins a glowing comet with a fading tail around a NeoPixel ring, changing color as it goes.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 16;
const int TAIL = 6;
Adafruit_NeoPixel ring(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);
uint16_t hue = 0;

void setup() {
  ring.begin();
  ring.setBrightness(60);
}

void loop() {
  for (int head = 0; head < NUM_LEDS; head++) {
    ring.clear();
    for (int t = 0; t < TAIL; t++) {
      int pixel = (head - t + NUM_LEDS) % NUM_LEDS;  // wrap around the circle
      uint8_t brightness = 255 - t * (255 / TAIL);   // dimmer toward the tail end
      ring.setPixelColor(pixel, ring.ColorHSV(hue, 255, brightness));
    }
    ring.show();
    hue += 600;  // uint16_t wraps back to 0 after 65535, giving a full rainbow loop
    delay(50);
  }
}
