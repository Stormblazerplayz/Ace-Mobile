// @title Two Minute Toothbrush Timer
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; 8 LED stick or ring DIN to pin 6, 5V, GND; button pin 2 to GND; passive buzzer pin 8.
// @keywords toothbrush timer, two minute timer, brush teeth timer, neopixel progress bar
// @about Fills an LED bar over two minutes, beeping every 30 seconds so you know when to brush the next part of your mouth.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 8;
const int BUTTON = 2, BUZZER = 8;
const unsigned long TOTAL_MS = 120000UL;  // 2 minutes
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  strip.begin();
  strip.setBrightness(40);
  strip.show();
}

void loop() {
  if (digitalRead(BUTTON) == HIGH) return;  // wait for start

  unsigned long start = millis();
  int lastQuarter = 0;
  while (millis() - start < TOTAL_MS) {
    unsigned long passed = millis() - start;
    int lit = passed * NUM_LEDS / TOTAL_MS + 1;  // how many LEDs to show
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, i < lit ? strip.Color(0, 120, 255) : 0);
    }
    strip.show();

    int quarter = passed / 30000UL;  // which 30 seconds we are in (0 to 3)
    if (quarter != lastQuarter) {
      lastQuarter = quarter;
      tone(BUZZER, 1500, 120);  // switch to the next part of your mouth
    }
    delay(50);
  }

  // Done! Rainbow party for clean teeth.
  for (int j = 0; j < 100; j++) {
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, strip.ColorHSV((i * 8192UL + j * 1000UL) % 65536UL));
    }
    strip.show();
    delay(20);
  }
  tone(BUZZER, 2000, 400);
  strip.clear();
  strip.show();
}
