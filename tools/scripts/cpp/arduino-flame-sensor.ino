// @title Flame Detector Alarm
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; IR flame sensor module DO to pin 2, AO to A0, VCC 5V, GND; buzzer pin 8; red LED pin 13. Test only with a candle and an adult nearby.
// @keywords flame sensor, fire alarm arduino, ir flame detector, candle detector
// @about Sounds an alarm when the flame sensor sees fire and prints how strong it is.

const int FLAME_DIGITAL = 2;
const int FLAME_ANALOG = A0;
const int BUZZER_PIN = 8;
const int LED_PIN = 13;

void setup() {
  pinMode(FLAME_DIGITAL, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // Most flame modules output LOW when they see a flame.
  bool fire = digitalRead(FLAME_DIGITAL) == LOW;
  int strength = 1023 - analogRead(FLAME_ANALOG);  // flip so bigger = stronger flame

  Serial.print("Flame strength: ");
  Serial.println(strength);

  if (fire) {
    digitalWrite(LED_PIN, HIGH);
    tone(BUZZER_PIN, 3000, 100);
    delay(150);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  } else {
    digitalWrite(LED_PIN, LOW);
    delay(250);
  }
}
