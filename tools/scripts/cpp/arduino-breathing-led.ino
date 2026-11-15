// @title Breathing LED (Sleep Light)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED with 220 ohm resistor on pin 9 and GND.
// @keywords breathing led, sine wave fade, sleep mode light, smooth pulsing led
// @about Makes an LED gently pulse like a sleeping laptop light, using a sine wave for a smooth look.

const int LED_PIN = 9;
const float BREATH_SECONDS = 4.0;  // one full in-and-out breath

void setup() {
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  float seconds = millis() / 1000.0;
  // sin() swings from -1 to 1. Shift it to 0..1, then to 0..255.
  float wave = (sin(seconds * TWO_PI / BREATH_SECONDS) + 1.0) / 2.0;
  // Squaring the wave makes the dim part last longer, which looks nicer.
  int brightness = (int)(wave * wave * 255);
  analogWrite(LED_PIN, brightness);
  delay(10);
}
