// @title AA Battery Tester
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; battery + to A0, battery - to GND (only 1.5V AA, AAA or 1 cell, never more than 5V); green LED 4, yellow LED 5, red LED 6 with 220 ohm resistors.
// @keywords battery tester, check aa battery, battery voltage arduino, is my battery dead
// @about Measures a 1.5 V battery and lights green, yellow or red to show if it is good, ok or dead.

const int BATTERY_PIN = A0;
const int GREEN = 4, YELLOW = 5, RED = 6;

void setup() {
  pinMode(GREEN, OUTPUT);
  pinMode(YELLOW, OUTPUT);
  pinMode(RED, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  float volts = analogRead(BATTERY_PIN) * 5.0 / 1023.0;

  digitalWrite(GREEN, LOW);
  digitalWrite(YELLOW, LOW);
  digitalWrite(RED, LOW);

  Serial.print("Battery: ");
  Serial.print(volts, 2);
  Serial.print(" V  ");

  if (volts < 0.1) {
    Serial.println("(no battery)");
  } else if (volts >= 1.4) {
    digitalWrite(GREEN, HIGH);
    Serial.println("good");
  } else if (volts >= 1.2) {
    digitalWrite(YELLOW, HIGH);
    Serial.println("ok");
  } else {
    digitalWrite(RED, HIGH);
    Serial.println("dead, recycle it");
  }
  delay(500);
}
