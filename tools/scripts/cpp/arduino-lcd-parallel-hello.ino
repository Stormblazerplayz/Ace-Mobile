// @title LCD 16x2 Without I2C (Parallel Wiring)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LCD RS to 12, E to 11, D4 to 5, D5 to 4, D6 to 3, D7 to 2, RW to GND, VSS GND, VDD 5V, V0 to a 10k pot middle leg, A to 5V via 220 ohm, K to GND.
// @keywords lcd parallel, liquidcrystal library, starter kit lcd, lcd without i2c backpack
// @about Uses the built-in LiquidCrystal library to show text on an LCD with no I2C backpack.

#include <LiquidCrystal.h>

// The pins in order: RS, E, D4, D5, D6, D7
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

void setup() {
  lcd.begin(16, 2);  // 16 columns, 2 rows
  lcd.print("Starter kit LCD");
}

void loop() {
  lcd.setCursor(0, 1);
  unsigned long seconds = millis() / 1000;
  lcd.print("Up for ");
  lcd.print(seconds / 60);
  lcd.print("m ");
  lcd.print(seconds % 60);
  lcd.print("s   ");
  delay(500);
}
