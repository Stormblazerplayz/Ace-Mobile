// @title LCD Custom Characters (Hearts and Smileys)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA to A4, SCL to A5, VCC 5V, GND.
// @keywords lcd custom characters, lcd createchar, draw icons on lcd, lcd heart smiley
// @about Draws your own little pictures (a heart, a smiley and a walking person) on an LCD.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// Each character is 5 dots wide and 8 tall. 1 = dot on.
byte heart[8]   = {0b00000, 0b01010, 0b11111, 0b11111, 0b01110, 0b00100, 0b00000, 0b00000};
byte smiley[8]  = {0b00000, 0b01010, 0b01010, 0b00000, 0b10001, 0b01110, 0b00000, 0b00000};
byte walkA[8]   = {0b01110, 0b01110, 0b00100, 0b01110, 0b10101, 0b00100, 0b01010, 0b10001};
byte walkB[8]   = {0b01110, 0b01110, 0b00100, 0b11111, 0b00100, 0b00100, 0b01010, 0b01010};

void setup() {
  lcd.init();
  lcd.backlight();
  // Save them in the LCD's 8 custom slots (0 to 7).
  lcd.createChar(0, heart);
  lcd.createChar(1, smiley);
  lcd.createChar(2, walkA);
  lcd.createChar(3, walkB);

  lcd.setCursor(0, 0);
  lcd.write(byte(0));
  lcd.print(" I love code ");
  lcd.write(byte(1));
}

void loop() {
  // Walk the little person across the bottom line.
  for (int col = 0; col < 16; col++) {
    lcd.setCursor(0, 1);
    lcd.print("                ");  // wipe the line
    lcd.setCursor(col, 1);
    lcd.write(byte(col % 2 == 0 ? 2 : 3));  // swap legs every step
    delay(350);
  }
}
