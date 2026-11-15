// @title LCD 16x2 I2C Hello World
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C" by Frank de Brabander; LCD backpack GND to GND, VCC to 5V, SDA to A4, SCL to A5. Turn the blue screw on the back if you see no text.
// @keywords lcd i2c, 16x2 lcd, liquidcrystal_i2c, lcd hello world, arduino lcd screen
// @about Shows a message on the top line of an I2C LCD and counts seconds on the bottom line.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Address 0x27, 16 characters wide, 2 lines tall. Try 0x3F if nothing shows.
LiquidCrystal_I2C lcd(0x27, 16, 2);

void setup() {
  lcd.init();       // start the screen
  lcd.backlight();  // turn on the light behind the text
  lcd.setCursor(0, 0);  // column 0, line 0 (the top)
  lcd.print("Hello, Storm!");
}

void loop() {
  lcd.setCursor(0, 1);  // column 0, line 1 (the bottom)
  lcd.print("Seconds: ");
  lcd.print(millis() / 1000);
  delay(250);
}
