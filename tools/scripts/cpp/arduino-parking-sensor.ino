// @title Parking Sensor with Beeps
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-SR04 Trig to pin 9, Echo to pin 10, VCC to 5V, GND to GND; piezo buzzer + to pin 8, - to GND.
// @keywords arduino parking sensor, beeps faster when closer, ultrasonic buzzer, car reverse sensor arduino
// @about Beeps slowly when something is far away and faster and faster as it gets closer, like a car.

const int TRIG_PIN = 9;
const int ECHO_PIN = 10;
const int BUZZER_PIN = 8;

long readDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);  // a 10 microsecond ping
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000UL);  // give up after 30 ms
  if (duration == 0) return 999;  // nothing in range
  return duration / 58;           // sound: about 58 microseconds per cm there and back
}

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  long cm = readDistanceCm();

  if (cm < 5) {
    tone(BUZZER_PIN, 2000);  // super close: one long beep
    delay(100);
  } else if (cm < 60) {
    noTone(BUZZER_PIN);
    // Closer = shorter gap between beeps (5 cm -> 25 ms, 60 cm -> 600 ms).
    int gap = map(cm, 5, 60, 25, 600);
    tone(BUZZER_PIN, 2000, 60);
    delay(60 + gap);
  } else {
    noTone(BUZZER_PIN);  // far away: quiet
    delay(100);
  }
}
