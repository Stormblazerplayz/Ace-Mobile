// @title NeoPixel Tug of War Button Battle
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Adafruit NeoPixel"; 30 LED strip DIN to pin 6, 5V, GND; red player button pin 2 to GND, blue player button pin 3 to GND.
// @keywords tug of war game, button mashing game, two player led strip game, neopixel game
// @about Two players mash their buttons to pull the light to their end of the strip; first to reach the end wins.

#include <Adafruit_NeoPixel.h>

const int NUM_LEDS = 30;
const int RED_BUTTON = 2, BLUE_BUTTON = 3;
Adafruit_NeoPixel strip(NUM_LEDS, 6, NEO_GRB + NEO_KHZ800);

int rope = NUM_LEDS / 2;  // the "flag" position
bool lastRed = HIGH, lastBlue = HIGH;

void draw() {
  for (int i = 0; i < NUM_LEDS; i++) {
    if (i == rope) strip.setPixelColor(i, 255, 255, 255);    // white flag
    else if (i < rope) strip.setPixelColor(i, 40, 0, 0);     // red side
    else strip.setPixelColor(i, 0, 0, 40);                   // blue side
  }
  strip.show();
}

void celebrate(uint32_t color) {
  for (int k = 0; k < 6; k++) {
    strip.fill(k % 2 ? 0 : color, 0, NUM_LEDS);
    strip.show();
    delay(250);
  }
  rope = NUM_LEDS / 2;
}

void setup() {
  pinMode(RED_BUTTON, INPUT_PULLUP);
  pinMode(BLUE_BUTTON, INPUT_PULLUP);
  strip.begin();
  strip.setBrightness(80);
  draw();
}

void loop() {
  bool red = digitalRead(RED_BUTTON);
  bool blue = digitalRead(BLUE_BUTTON);
  // Only a fresh press counts: holding the button does nothing.
  if (red == LOW && lastRed == HIGH) rope--;
  if (blue == LOW && lastBlue == HIGH) rope++;
  lastRed = red;
  lastBlue = blue;

  if (rope <= 0) celebrate(strip.Color(255, 0, 0));
  else if (rope >= NUM_LEDS - 1) celebrate(strip.Color(0, 0, 255));
  draw();
  delay(5);
}
