// @title Air Piano (Ultrasonic Theremin)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-SR04 Trig to pin 9, Echo to pin 10; passive buzzer on pin 8. Move your hand 5 to 40 cm above the sensor.
// @keywords ultrasonic theremin, air piano, hand distance music, play notes in the air
// @about Plays a note from a scale depending on how far your hand is from the ultrasonic sensor.

const int TRIG_PIN = 9, ECHO_PIN = 10, BUZZER_PIN = 8;
// C major scale, two octaves.
const int SCALE[] = {262, 294, 330, 349, 392, 440, 494, 523, 587, 659, 698, 784, 880, 988};
const int SCALE_SIZE = 14;

long distanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long d = pulseIn(ECHO_PIN, HIGH, 20000UL);
  return d == 0 ? 999 : d / 58;
}

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
}

void loop() {
  long cm = distanceCm();
  if (cm >= 5 && cm <= 40) {
    // Each 2.5 cm or so is one step on the scale.
    int note = map(cm, 5, 40, 0, SCALE_SIZE - 1);
    tone(BUZZER_PIN, SCALE[note]);
  } else {
    noTone(BUZZER_PIN);  // no hand: silence
  }
  delay(50);
}
