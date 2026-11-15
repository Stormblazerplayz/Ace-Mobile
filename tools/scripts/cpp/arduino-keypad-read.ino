// @title Read a 4x4 Keypad
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Keypad" by Mark Stanley; keypad pins 1 to 8 (left to right) go to Arduino pins 9, 8, 7, 6, 5, 4, 3, 2; open Serial Monitor at 9600.
// @keywords arduino keypad, 4x4 membrane keypad, keypad getkey, matrix keypad arduino
// @about Prints each key you press on a 4x4 membrane keypad.

#include <Keypad.h>

const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};
byte rowPins[ROWS] = {9, 8, 7, 6};  // the first 4 wires
byte colPins[COLS] = {5, 4, 3, 2};  // the last 4 wires

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

void setup() {
  Serial.begin(9600);
  Serial.println("Press some keys!");
}

void loop() {
  char key = keypad.getKey();  // NO_KEY if nothing is pressed
  if (key != NO_KEY) {
    Serial.print("You pressed: ");
    Serial.println(key);
  }
}
