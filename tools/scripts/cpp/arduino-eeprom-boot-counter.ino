// @title Count How Many Times the Arduino Started
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino Uno or Nano; open Serial Monitor at 9600, then press the reset button a few times.
// @keywords eeprom, eeprom counter, remember after power off, eeprom get put, boot counter
// @about Saves a counter in EEPROM memory so it remembers how many times the board has started, even after unplugging it.

#include <EEPROM.h>

const int ADDRESS = 0;  // where in EEPROM we keep our number

void setup() {
  Serial.begin(9600);

  unsigned long boots;
  EEPROM.get(ADDRESS, boots);  // read 4 bytes into "boots"

  // A brand new EEPROM is full of 255s, which reads as a giant number. Start from 0.
  if (boots == 0xFFFFFFFFUL) boots = 0;

  boots++;
  EEPROM.put(ADDRESS, boots);  // put only writes bytes that changed (EEPROM wears out after ~100,000 writes)

  Serial.print("I have started ");
  Serial.print(boots);
  Serial.println(" times!");
}

void loop() {
  // Nothing to do. Press reset to count again.
}
