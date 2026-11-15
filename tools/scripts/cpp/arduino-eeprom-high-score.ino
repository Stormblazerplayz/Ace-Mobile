// @title Reaction Game that Saves the High Score
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LED on pin 9; button pin 2 to GND; open Serial Monitor at 9600. Hold the button while pressing reset to clear the record.
// @keywords eeprom high score, save best score, record that survives reset, eeprom game
// @about A reaction game whose best time is stored in EEPROM, so the record stays even when the Arduino is turned off.

#include <EEPROM.h>

const int LED = 9, BUTTON = 2;
const int RECORD_ADDRESS = 0;
unsigned long record;

void setup() {
  pinMode(LED, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
  randomSeed(analogRead(A0));

  EEPROM.get(RECORD_ADDRESS, record);
  // Empty EEPROM, or the button held at startup: clear the record.
  if (record == 0xFFFFFFFFUL || record == 0 || digitalRead(BUTTON) == LOW) {
    record = 99999;
    EEPROM.put(RECORD_ADDRESS, record);
    Serial.println("Record cleared.");
  }
  Serial.print("Record to beat: ");
  Serial.print(record);
  Serial.println(" ms");
}

void loop() {
  while (digitalRead(BUTTON) == LOW) delay(10);
  delay(random(1500, 4000));
  if (digitalRead(BUTTON) == LOW) return;  // no holding the button down!

  digitalWrite(LED, HIGH);
  unsigned long start = millis();
  while (digitalRead(BUTTON) == HIGH) {}
  unsigned long reaction = millis() - start;
  digitalWrite(LED, LOW);

  Serial.print("You: ");
  Serial.print(reaction);
  Serial.println(" ms");
  if (reaction < record) {
    record = reaction;
    EEPROM.put(RECORD_ADDRESS, record);
    Serial.println("NEW RECORD! Saved forever (well, until someone beats it).");
  }
  delay(1000);
}
