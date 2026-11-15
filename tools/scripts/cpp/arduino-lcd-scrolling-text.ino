// @title LCD Scrolling Message
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA to A4, SCL to A5, VCC 5V, GND.
// @keywords lcd scrolling text, marquee message lcd, long text on 16x2, scroll text arduino
// @about Scrolls a long message across the top line of a 16x2 LCD like a news ticker.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const char MESSAGE[] = "Welcome to my robot lab! Please do not touch the wires...   ";

void setup() {
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 1);
  lcd.print("  ** NEWS **");
}

void loop() {
  int length = strlen(MESSAGE);
  for (int start = 0; start < length; start++) {
    lcd.setCursor(0, 0);
    // Print 16 letters starting at "start", wrapping back to the beginning.
    for (int i = 0; i < 16; i++) {
      lcd.print(MESSAGE[(start + i) % length]);
    }
    delay(300);
  }
}
