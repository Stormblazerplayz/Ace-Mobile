// @title Magic 8 Ball on an LCD
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA A4, SCL A5; tilt switch between pin 2 and GND (or a button). Ask a question and shake it!
// @keywords magic 8 ball, fortune teller lcd, shake for answer, ask a question arduino
// @about Shake the tilt switch and the LCD shows a random Magic 8 Ball answer.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int TILT_PIN = 2;

const char *ANSWERS[] = {
  "Yes!", "No way", "Maybe...", "Ask again", "Definitely", "Not today",
  "Signs say yes", "Very doubtful", "Of course!", "Try later", "I think so", "Hmm, no"
};
const int ANSWER_COUNT = sizeof(ANSWERS) / sizeof(ANSWERS[0]);

void setup() {
  pinMode(TILT_PIN, INPUT_PULLUP);
  lcd.init();
  lcd.backlight();
  lcd.print("Ask a question");
  lcd.setCursor(0, 1);
  lcd.print("then shake me!");
  randomSeed(analogRead(A0));
}

void loop() {
  if (digitalRead(TILT_PIN) == HIGH) {  // tipped or shaken
    lcd.clear();
    lcd.print("Thinking");
    for (int i = 0; i < 3; i++) {
      delay(400);
      lcd.print(".");
    }
    lcd.clear();
    lcd.print("The ball says:");
    lcd.setCursor(0, 1);
    lcd.print(ANSWERS[random(ANSWER_COUNT)]);
    delay(4000);
    lcd.clear();
    lcd.print("Ask another!");
  }
}
