// @title Lamp that Remembers its Brightness
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED with 220 ohm resistor on pin 9; button between pin 2 and GND. Unplug and plug back in: it keeps its setting.
// @keywords eeprom remember setting, save brightness eeprom, eeprom update, keep settings after reset
// @about Each button press changes the lamp brightness, and the choice is saved in EEPROM so it comes back after power off.

#include <EEPROM.h>

const int LED = 9, BUTTON = 2;
const int SAVE_ADDRESS = 10;
const byte LEVELS[] = {0, 20, 60, 130, 255};
const byte LEVEL_COUNT = 5;
byte level;
bool lastButton = HIGH;

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  level = EEPROM.read(SAVE_ADDRESS);
  if (level >= LEVEL_COUNT) level = 2;  // first time ever: a medium setting
  analogWrite(LED, LEVELS[level]);
}

void loop() {
  bool button = digitalRead(BUTTON);
  if (button == LOW && lastButton == HIGH) {
    level = (level + 1) % LEVEL_COUNT;
    analogWrite(LED, LEVELS[level]);
    EEPROM.update(SAVE_ADDRESS, level);  // update skips the write if it's the same, saving wear
    delay(40);
  }
  lastButton = button;
}
