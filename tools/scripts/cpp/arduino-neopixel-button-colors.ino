// @title NeoPixel Color Picker Button
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; strip DIN to pin 6, 5V, GND; push button between pin 2 and GND.
// @keywords neopixel button, change strip color button, led strip color picker, ws2812b button
// @about Each button press changes the whole strip to the next color in a list.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 30;
const int BUTTON_PIN = 2;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

// Red, orange, yellow, green, cyan, blue, purple, white, off.
const uint32_t COLORS[] = {
  0xFF0000, 0xFF6000, 0xFFD000, 0x00FF00, 0x00FFFF, 0x0000FF, 0x8000FF, 0xFFFFFF, 0x000000
};
const int COLOR_COUNT = sizeof(COLORS) / sizeof(COLORS[0]);
int current = 0;
bool lastButton = HIGH;

void showColor() {
  strip.fill(COLORS[current], 0, NUM_LEDS);
  strip.show();
}

void setup() {
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  strip.begin();
  strip.setBrightness(60);
  showColor();
}

void loop() {
  bool button = digitalRead(BUTTON_PIN);
  if (button == LOW && lastButton == HIGH) {
    current = (current + 1) % COLOR_COUNT;
    showColor();
    delay(50);  // debounce
  }
  lastButton = button;
}
