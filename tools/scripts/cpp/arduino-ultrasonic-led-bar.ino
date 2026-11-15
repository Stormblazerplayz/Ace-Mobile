// @title Distance LED Bar Graph
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-SR04 Trig to A0, Echo to A1; 6 LEDs (with 220 ohm resistors) on pins 2 to 7.
// @keywords ultrasonic led bar graph, distance leds, closer more leds light, hc-sr04 led meter
// @about Lights up more LEDs the closer your hand gets to the ultrasonic sensor.

const int TRIG_PIN = A0;  // analog pins work as normal digital pins too
const int ECHO_PIN = A1;
const int LED_PINS[] = {2, 3, 4, 5, 6, 7};
const int LED_COUNT = 6;
const int MAX_CM = 60;  // farther than this = no LEDs

long readDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000UL);
  if (duration == 0) return MAX_CM;
  return duration / 58;
}

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  for (int i = 0; i < LED_COUNT; i++) {
    pinMode(LED_PINS[i], OUTPUT);
  }
}

void loop() {
  long cm = constrain(readDistanceCm(), 0, MAX_CM);
  // 0 cm -> 6 LEDs, MAX_CM -> 0 LEDs.
  int lit = map(cm, 0, MAX_CM, LED_COUNT, 0);

  for (int i = 0; i < LED_COUNT; i++) {
    digitalWrite(LED_PINS[i], i < lit ? HIGH : LOW);
  }
  delay(60);
}
