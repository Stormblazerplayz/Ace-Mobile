// @title Ultrasonic Distance Sensor
// @category Arduino
// @kind Arduino sketch
// @where Paste this into a new Arduino IDE sketch, upload it and open Tools > Serial Monitor at 9600 baud; wire the HC-SR04 VCC to 5V, GND to GND, Trig to pin 9 and Echo to pin 10.
// @keywords arduino ultrasonic sensor, arduino hc-sr04, arduino distance sensor, measure distance with arduino
// @about Measures how far away something is with an HC-SR04 sensor and prints it in centimeters.

const int TRIG_PIN = 9;
const int ECHO_PIN = 10;

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  Serial.begin(9600);
}

void loop() {
  // Send a tiny 10 microsecond "ping".
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Time how long the echo takes to come back (give up after 30 ms).
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000UL);

  if (duration == 0) {
    Serial.println("Nothing in range");
  } else {
    // Sound goes about 0.0343 cm per microsecond, there and back, so divide by 2.
    float distanceCm = duration * 0.0343 / 2.0;
    Serial.print("Distance: ");
    Serial.print(distanceCm, 1);
    Serial.println(" cm");
  }

  delay(200);
}
