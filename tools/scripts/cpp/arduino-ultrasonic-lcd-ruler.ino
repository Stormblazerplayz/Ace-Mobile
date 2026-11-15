// @title Ultrasonic Ruler on an LCD
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; HC-SR04 Trig to 9, Echo to 10; LCD I2C SDA to A4, SCL to A5, VCC 5V, GND.
// @keywords arduino digital ruler, ultrasonic lcd, measure distance on lcd, hc-sr04 lcd 16x2
// @about Measures distance with an HC-SR04 and shows it in cm and inches on an LCD.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int TRIG_PIN = 9;
const int ECHO_PIN = 10;

float readDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000UL);
  if (duration == 0) return -1;      // no echo came back
  return duration * 0.0343 / 2.0;    // speed of sound is 0.0343 cm per microsecond
}

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  lcd.init();
  lcd.backlight();
}

void loop() {
  float cm = readDistanceCm();
  lcd.clear();
  lcd.setCursor(0, 0);
  if (cm < 0) {
    lcd.print("Out of range");
  } else {
    lcd.print("Dist: ");
    lcd.print(cm, 1);
    lcd.print(" cm");
    lcd.setCursor(0, 1);
    lcd.print("      ");
    lcd.print(cm / 2.54, 1);
    lcd.print(" in");
  }
  delay(300);
}
