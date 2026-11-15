// @title LCD Score Counter with Buttons
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA A4, SCL A5; plus button pin 2 to GND, minus button pin 3 to GND, reset button pin 4 to GND.
// @keywords lcd counter, button scoreboard lcd, tally counter arduino, plus minus buttons
// @about A score counter: one button adds a point, one takes a point away, and one resets to zero.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int PLUS = 2, MINUS = 3, RESET = 4;
int score = 0;

// True only at the moment a button is pressed (not while held).
bool pressed(int pin, bool &last) {
  bool now = digitalRead(pin) == LOW;
  bool result = now && !last;
  last = now;
  return result;
}

void showScore() {
  lcd.setCursor(0, 1);
  lcd.print("Score: ");
  lcd.print(score);
  lcd.print("      ");  // wipe leftover digits, like when 10 becomes 9
}

void setup() {
  pinMode(PLUS, INPUT_PULLUP);
  pinMode(MINUS, INPUT_PULLUP);
  pinMode(RESET, INPUT_PULLUP);
  lcd.init();
  lcd.backlight();
  lcd.print("Scoreboard");
  showScore();
}

void loop() {
  static bool lastPlus = false, lastMinus = false, lastReset = false;
  bool changed = false;

  if (pressed(PLUS, lastPlus)) { score++; changed = true; }
  if (pressed(MINUS, lastMinus)) { score--; changed = true; }
  if (pressed(RESET, lastReset)) { score = 0; changed = true; }

  if (changed) showScore();
  delay(30);  // simple debounce
}
