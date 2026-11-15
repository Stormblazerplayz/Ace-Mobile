// @title Simple Clock on a TM1637 Display
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "TM1637" by Avishay Orpaz; display CLK to 2, DIO to 3, VCC 5V, GND; hour button pin 4 to GND, minute button pin 5 to GND.
// @keywords tm1637 clock, arduino digital clock, clock with colon, set time buttons
// @about A 24-hour clock with a blinking colon that you set with an hour button and a minute button.

#include <TM1637Display.h>

TM1637Display display(2, 3);
const int HOUR_BUTTON = 4;
const int MINUTE_BUTTON = 5;

int hours = 12;
int minutes = 0;
int seconds = 0;
unsigned long lastTick = 0;

void setup() {
  pinMode(HOUR_BUTTON, INPUT_PULLUP);
  pinMode(MINUTE_BUTTON, INPUT_PULLUP);
  display.setBrightness(4);
}

void loop() {
  // Count one second every 1000 ms. (The Arduino's clock may drift a little each day.)
  if (millis() - lastTick >= 1000) {
    lastTick += 1000;
    seconds++;
    if (seconds == 60) { seconds = 0; minutes++; }
    if (minutes == 60) { minutes = 0; hours++; }
    if (hours == 24) hours = 0;
  }

  if (digitalRead(HOUR_BUTTON) == LOW) { hours = (hours + 1) % 24; delay(250); }
  if (digitalRead(MINUTE_BUTTON) == LOW) { minutes = (minutes + 1) % 60; seconds = 0; delay(200); }

  // 0b01000000 turns on the colon. Blink it every other second.
  uint8_t colon = (seconds % 2 == 0) ? 0b01000000 : 0;
  display.showNumberDecEx(hours * 100 + minutes, colon, true);  // true = show leading zeros
}
