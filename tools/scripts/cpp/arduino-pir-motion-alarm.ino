// @title PIR Motion Alarm
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-SR501 PIR OUT to pin 2, VCC to 5V, GND to GND; red LED (220 ohm) on pin 13; buzzer + on pin 8.
// @keywords arduino pir sensor, motion alarm, hc-sr501, arduino intruder alarm, motion detector buzzer
// @about Flashes a light and sounds a siren when the PIR sensor sees someone move.

const int PIR_PIN = 2;
const int LED_PIN = 13;
const int BUZZER_PIN = 8;

void setup() {
  pinMode(PIR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  Serial.begin(9600);
  Serial.println("Warming up the PIR sensor (30 seconds)...");
  delay(30000);  // PIR sensors need time to learn the room
  Serial.println("Alarm armed!");
}

void loop() {
  if (digitalRead(PIR_PIN) == HIGH) {
    Serial.println("Motion detected!");
    // Siren: three up-and-down whoops.
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_PIN, HIGH);
      for (int f = 600; f <= 1200; f += 20) {
        tone(BUZZER_PIN, f);
        delay(5);
      }
      digitalWrite(LED_PIN, LOW);
      for (int f = 1200; f >= 600; f -= 20) {
        tone(BUZZER_PIN, f);
        delay(5);
      }
    }
    noTone(BUZZER_PIN);
  }
  delay(50);
}
