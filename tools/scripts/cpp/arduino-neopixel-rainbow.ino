// @title NeoPixel Rainbow
// @category Arduino
// @kind Arduino sketch
// @where Install "Adafruit NeoPixel" from the Arduino IDE Library Manager, paste this into a new sketch and upload it; wire the strip's DIN to pin 6, 5V to 5V and GND to GND.
// @keywords arduino neopixel, arduino rainbow led strip, arduino rgb strip, ws2812b arduino, arduino addressable leds
// @about Makes a NeoPixel LED strip show a smooth rainbow that slides along.

#include <Adafruit_NeoPixel.h>

const int LED_PIN = 6;
const int LED_COUNT = 30;   // change to how many LEDs your strip has
const int BRIGHTNESS = 50;  // 0 to 255 (keep it low so USB power is enough)

Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800);

// Where the rainbow starts. It moves a bit each frame.
uint16_t firstHue = 0;

void setup() {
  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  strip.show();  // start with all LEDs off
}

void loop() {
  for (uint16_t i = 0; i < strip.numPixels(); i++) {
    // Spread one full rainbow (65536 hues) across the strip.
    uint16_t hue = firstHue + (uint32_t)i * 65536UL / strip.numPixels();
    uint32_t color = strip.gamma32(strip.ColorHSV(hue));
    strip.setPixelColor(i, color);
  }
  strip.show();

  firstHue += 256;  // slide the rainbow along
  delay(20);
}
