// @title Tilt Switch Alarm
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; tilt (ball) switch between pin 2 and GND; LED (220 ohm) on pin 13; buzzer on pin 8.
// @keywords tilt switch, ball tilt sensor, sw-520d, arduino tilt alarm, detect if knocked over
// @about Beeps and flashes when the tilt switch is tipped over, like an anti-theft box.

const int TILT_PIN = 2;
const int LED_PIN = 13;
const int BUZZER_PIN = 8;

void setup() {
  pinMode(TILT_PIN, INPUT_PULLUP);  // upright = closed = LOW
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  // The little ball rolls and bounces, so check that it stays tipped for 50 ms.
  if (digitalRead(TILT_PIN) == HIGH) {
    delay(50);
    if (digitalRead(TILT_PIN) == HIGH) {
      digitalWrite(LED_PIN, HIGH);
      tone(BUZZER_PIN, 1000, 200);
      delay(250);
      digitalWrite(LED_PIN, LOW);
      delay(150);
      return;
    }
  }
  digitalWrite(LED_PIN, LOW);
}
